# Local compiler and platform checks

`scripts/neutrino-ci.py` builds Neutrino projects locally using pinned Dockcross
images. It does not dispatch GitHub Actions, commit, push, or publish artifacts.
Docker image downloads and third-party dependency downloads still need network
access on the first run.

## Before running: check Docker's disk space

Docker images and build cache use the Docker storage filesystem, which can be
the root partition even when the source workspace is on a large `/home` disk.
Checking only the workspace's free space is insufficient.

From the workspace directory, check both locations before downloading images:

```sh
ci_docker_root=$(docker info --format '{{.DockerRootDir}}')
df -h / . "$ci_docker_root"
docker system df
```

Budget at least **30 GB of free space on Docker's storage filesystem** before
starting the full container matrix, plus space for build trees in the workspace.
This is a planning allowance, not an enforced limit: the four base images alone
have reported sizes of roughly 2.6, 3.7, 6.5, and 5.6 GB, with shared layers;
image extraction, the Linux SDK layers, and build cache require additional room.
Start with one project and one target to check resource usage before expanding.

**The runner does not check available disk space automatically.** Missing images
are downloaded, and missing Linux SDK images are built, when `run` starts.
`list` and `run --help` only print information and do not start Docker builds.

## Run locally

Install Python 3 and make the Docker daemon accessible to your user. Container
images provide their own build tools. Native Windows/macOS builds also require
CMake 3.24 or newer and the compiler/SDK listed in the coverage table below.

Keep the ecosystem repositories in sibling directories, including
`neutrino-cmake`. The runner uses these local checkouts for FetchContent
dependencies, so changes to foundational libraries reach consumers before a
push. Repositories outside this workspace are fetched normally. Use
`--workspace PATH` before `run` to select another workspace.

From the workspace directory:

```sh
# Inspect the project and target registry.
python3 neutrino-cmake/scripts/neutrino-ci.py list

# Start with one project and one toolchain after checking disk space.
python3 neutrino-cmake/scripts/neutrino-ci.py run \
  --projects failsafe --targets linux-gcc --jobs 2

# Expand to the foundational libraries and all container targets.
python3 neutrino-cmake/scripts/neutrino-ci.py run \
  --projects failsafe euler \
  --targets linux-gcc linux-clang android-arm64 web-wasm --jobs 4

# Check all 19 registered projects after validating storage and the small run.
python3 neutrino-cmake/scripts/neutrino-ci.py run --all \
  --targets linux-gcc linux-clang android-arm64 web-wasm

# Reproduce a specific build, or pass a project-specific CMake option.
python3 neutrino-cmake/scripts/neutrino-ci.py run --projects euler \
  --targets android-arm64 --cmake-arg=-DNEUTRINO_EULER_ENABLE_XSIMD=OFF
```

For a different checkout location, place `--workspace` before `run`:

```sh
python3 /path/to/workspace/neutrino-cmake/scripts/neutrino-ci.py \
  --workspace /path/to/workspace run --projects euler --targets linux-clang
```

Projects run sequentially, with two parallel compiler processes per build by
default. `--jobs` changes that limit. Existing build directories are reused.
Each run writes separate logs and `report.json` under
`neutrino-cmake/.local-ci/runs/`; build trees live in `.local-ci/build/`.
Both are ignored by Git. A failed or unsupported requested combination makes
the runner exit nonzero, but the remaining combinations still run.

Inspect a run's report or follow its log using the paths printed by the runner:

```sh
cat neutrino-cmake/.local-ci/runs/<run-id>/report.json
tail -f neutrino-cmake/.local-ci/runs/<run-id>/failsafe-linux-gcc.log
```

The report distinguishes `passed`, `failed`, and `unsupported`, and records the
coverage level, image reference, and log path when a build was attempted. A
registered target is not a claim that every project already passes on it.

## Coverage

| Target | Local environment | Checks |
| --- | --- | --- |
| `linux-gcc` | Dockcross Linux GCC | Build and project tests |
| `linux-clang` | Dockcross Linux Clang | Build and project tests |
| `android-arm64` | Dockcross Android NDK Clang | Build and link a consumer; no device tests |
| `web-wasm` | Dockcross Emscripten | Build and run a consumer under Node; no browser/graphics tests |
| `windows-msvc` | Windows with Visual Studio 2022 | Build and project tests |
| `windows-clangcl` | Windows with VS 2022 and ClangCL | Build and project tests |
| `macos-clang` | macOS with Xcode command-line tools and Ninja | Build and project tests |
| `ios-arm64` | macOS with Xcode and iPhoneOS SDK | Device build, code signing disabled |
| `ios-simulator` | macOS with Xcode and simulator SDK | ARM64 simulator build; no simulator tests |

The native Windows and Apple targets run on the current local machine. They
report `unsupported` on other hosts; they do not silently use a cloud runner.
Dockcross's Windows MinGW images do not validate MSVC and are not substituted
for it. Android and iOS runtime testing needs a device or a separate emulator
harness. Building a simulator binary alone does not run it.

Run the native targets on the corresponding local machine, for example:

```sh
# On Windows with Visual Studio 2022 (use your Python 3 executable).
python neutrino-cmake/scripts/neutrino-ci.py run --projects failsafe euler --targets windows-msvc windows-clangcl

# On macOS with Xcode and the relevant SDKs.
python3 neutrino-cmake/scripts/neutrino-ci.py run --projects failsafe euler \
  --targets macos-clang ios-arm64 ios-simulator
```

Every build compiles a consumer of the project's public headers. This prevents
header-only projects from reporting a successful build without compiling any
C++. Native jobs also require registered project tests; the injected consumer
cannot conceal a missing test suite. `--tests off` disables the full native test
suite; the WebAssembly consumer test still runs. `--tests on` is rejected for
targets without a full test runtime.

`mio` currently disables its implementation on Emscripten and provides only a
placeholder CMake target. Its WebAssembly combination is explicitly reported
as unsupported rather than passing an empty build. Other build or test failures
remain failures in the report; the runner does not disable warnings or tests to
make them green.

## Toolchain and project configuration

`ci/toolchains.json` pins Docker base images by digest. Updating a toolchain is an
explicit edit to that file after validating the replacement image. This also
means container compiler versions can differ from locally installed compilers.
The chosen compiler and CMake configuration are recorded in each build log.
The current Linux images provide GCC 12.2 and Clang 15.0, so results can differ
from jobs that use newer compiler versions. Warnings remain errors according to
each project's configuration.

For Linux, the runner automatically builds and caches a local image using
`ci/Dockerfile.linux`, adding SDL's X11, Wayland, graphics, and audio development
dependencies to the pinned compiler image. The cache tag includes the base
digest and Dockerfile contents. Debian packages are resolved when this layer is
first built; the resulting image ID is recorded in the report and used for the
run. Images are never uploaded to a registry.

`ci/projects.json` defines the component option prefix, FetchContent name,
consumer headers and target, and any project-specific options or known platform
limitations. Add a profile there to include another project. The same registry
is used by local container and native builds.

The Docker engine must be accessible to the invoking user. Containers mount the
workspace and create files with the invoking user's UID/GID on Unix. Do not run
the runner as root. `--engine podman` selects Podman when available.

## Stop and reclaim space

Interrupt the runner with Ctrl+C. If a container remains after interruption,
inspect `docker ps --no-trunc`, identify the container running this workspace's
`neutrino-ci.py` command, and stop that specific container with
`docker stop <container-id>`.

List the local CI images before choosing any to remove:

```sh
docker image ls --filter 'reference=dockcross/*' --filter 'reference=neutrino-ci/*'
```

Use `docker image rm <image-id> ...` for the selected unused CI images. The next
run will download or rebuild them. Image removal may leave layers retained by
BuildKit cache; inspect `docker system df` afterward. Avoid blanket Docker prune
commands on a machine with unrelated workloads. Workspace build trees and logs
are stored separately under `neutrino-cmake/.local-ci/`.

Upstream references: [Dockcross](https://github.com/dockcross/dockcross),
[Android NDK CMake](https://developer.android.com/ndk/guides/cmake),
[CMake Apple toolchains](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#cross-compiling-for-ios-tvos-visionos-or-watchos),
and [Emscripten builds](https://emscripten.org/docs/compiling/Building-Projects.html).
