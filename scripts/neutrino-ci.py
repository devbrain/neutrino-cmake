#!/usr/bin/env python3
"""Run the Neutrino build matrix locally. Never dispatches hosted CI or pushes Git."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import shlex
import subprocess
import sys
import time


INFRA = Path(__file__).resolve().parents[1]
PROJECTS = json.loads((INFRA / "ci/projects.json").read_text())
TOOLCHAINS = json.loads((INFRA / "ci/toolchains.json").read_text())


def command(argv, **kwargs):
    print("+ " + shlex.join(map(str, argv)), flush=True)
    return subprocess.run(list(map(str, argv)), check=True, **kwargs)


def container_image(engine, target, toolchain):
    base = toolchain["image"]
    if not toolchain.get("dockerfile"):
        return base
    dockerfile = INFRA / toolchain["dockerfile"]
    fingerprint = hashlib.sha256(base.encode() + dockerfile.read_bytes()).hexdigest()[:16]
    tag = f"neutrino-ci/{target}:{fingerprint}"
    inspect = [engine, "image", "inspect", tag, "--format", "{{.Id}}"]
    result = subprocess.run(inspect, capture_output=True, text=True)
    if result.returncode:
        command([engine, "build", "--build-arg", f"BASE_IMAGE={base}",
                 "--file", dockerfile, "--tag", tag, dockerfile.parent])
        result = subprocess.run(inspect, check=True, capture_output=True, text=True)
    return result.stdout.strip()


def consumer(build, profile):
    """Compile a consumer even when the library has no .cc files of its own."""
    source = build / "consumer.cc"
    source.write_text("".join(f"#include <{h}>\n" for h in profile["headers"])
                      + "int main() {\n" + profile.get("body", "") + "\n}\n")
    injection = build / "consumer.cmake"
    link = (f'target_link_libraries(neutrino_ci_smoke PRIVATE {profile["target"]})'
            if profile.get("target") else "")
    injection.write_text(f'''enable_testing()
function(neutrino_ci_consumer)
  add_executable(neutrino_ci_smoke [[{source.as_posix()}]])
  target_compile_features(neutrino_ci_smoke PRIVATE cxx_std_20)
  {link}
  add_test(NAME neutrino_ci_smoke COMMAND neutrino_ci_smoke)
endfunction()
cmake_language(DEFER CALL neutrino_ci_consumer)
''')
    return injection


def build_one(args):
    profile = PROJECTS[args.project]
    toolchain = TOOLCHAINS[args.target]
    root = args.workspace.resolve()
    source = root / args.project
    build = INFRA / ".local-ci/build" / args.project / args.target
    build.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    # Dockcross's native Linux toolchain sets CMAKE_SYSTEM_NAME, which makes
    # CMake consider an otherwise native build a cross build and disables tests.
    if toolchain.get("native_linux"):
        env.pop("CMAKE_TOOLCHAIN_FILE", None)
    tests = toolchain["tests"] if args.tests == "auto" else args.tests == "on"
    if tests and not toolchain["tests"]:
        raise ValueError("Full tests need a target runtime; use native Linux/Windows/macOS. "
                         "WebAssembly runs the consumer smoke test automatically.")
    prefix = "NEUTRINO_" + profile["component"]
    configure = ["cmake", "-S", source, "-B", build]
    configure += toolchain.get("configure", ["-G", "Ninja"])
    configure += ["-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                  f"-DNEUTRINO_CMAKE_DIR={INFRA / 'cmake'}",
                  f"-DCMAKE_PROJECT_TOP_LEVEL_INCLUDES={consumer(build, profile)}",
                  f"-D{prefix}_BUILD_TESTS={'ON' if tests else 'OFF'}",
                  f"-D{prefix}_BUILD_EXAMPLES=OFF", f"-D{prefix}_BUILD_DOCS=OFF",
                  f"-D{prefix}_BUILD_BENCHMARKS=OFF", f"-D{prefix}_INSTALL=OFF"]
    # Use the local ecosystem so edits to foundational libraries are tested by
    # their consumers before any commit or network push is required.
    for name, dependency in PROJECTS.items():
        local = root / name
        if name != args.project and (local / "CMakeLists.txt").is_file():
            fetch = dependency.get("fetch", name).upper()
            configure.append(f"-DFETCHCONTENT_SOURCE_DIR_{fetch}={local}")
    if args.target == "web-wasm":
        configure += ["-DCMAKE_C_FLAGS=-pthread", "-DCMAKE_CXX_FLAGS=-pthread -fexceptions",
                      "-DCMAKE_EXE_LINKER_FLAGS=-pthread -sALLOW_MEMORY_GROWTH=1"]
    if args.target.startswith("windows-"):
        configure += profile.get("windows", [])
    configure += profile.get("configure", []) + args.cmake_arg
    command(configure, env=env)
    command(["cmake", "--build", build, "--config", "Release", "--parallel", args.jobs], env=env)
    if tests or toolchain.get("smoke_test"):
        test_command = ["ctest", "--test-dir", build, "--build-config", "Release",
                        "--output-on-failure", "--no-tests=error", "--timeout", "300"]
        if not tests:
            test_command += ["-R", "^neutrino_ci_smoke$"]
        else:
            # An injected consumer must not conceal missing/disabled unit tests.
            listing = subprocess.check_output(
                ["ctest", "--test-dir", str(build), "-C", "Release", "--show-only=json-v1"],
                env=env, text=True)
            if not any(t["name"] != "neutrino_ci_smoke" for t in json.loads(listing)["tests"]):
                raise ValueError("No project tests were registered; only the consumer exists")
        command(test_command, env=env)


def run_matrix(args):
    root = args.workspace.resolve()
    names = list(PROJECTS) if args.all else args.projects
    if not names:
        raise ValueError("Specify --projects NAME ... or --all")
    missing = [n for n in names if not (root / n / "CMakeLists.txt").is_file()]
    if missing:
        raise ValueError("Missing project checkouts: " + ", ".join(missing))
    infra_relative = INFRA.relative_to(root)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    report_dir = INFRA / ".local-ci/runs" / stamp
    report_dir.mkdir(parents=True)
    results = []
    images = {}
    for name in names:
        for target in args.targets:
            toolchain = TOOLCHAINS[target]
            entry = {"project": name, "target": target,
                     "coverage": "build + tests" if toolchain["tests"] and args.tests != "off"
                     else "build + consumer test" if toolchain.get("smoke_test") else "build only"}
            reason = PROJECTS[name].get("unsupported", {}).get(target)
            if toolchain.get("host") and platform.system() != toolchain["host"]:
                reason = f"Requires a local {toolchain['host']} host; current host is {platform.system()}"
            if reason:
                entry.update(status="unsupported", reason=reason)
                print(f"UNSUPPORTED {name}/{target}: {reason}", flush=True)
            else:
                log = report_dir / f"{name}-{target}.log"
                child = ["--workspace", str(root), "_build", "--project", name, "--target", target,
                         "--jobs", str(args.jobs), "--tests", args.tests]
                child += ["--cmake-arg=" + arg for arg in args.cmake_arg]
                if "image" in toolchain:
                    if target not in images:
                        try:
                            images[target] = container_image(args.engine, target, toolchain)
                        except (OSError, subprocess.CalledProcessError) as error:
                            images[target] = error
                    if isinstance(images[target], Exception):
                        entry.update(status="failed", reason=f"Image preparation failed: {images[target]}")
                        print(f"FAILED {name}/{target}: {entry['reason']}", flush=True)
                        results.append(entry)
                        (report_dir / "report.json").write_text(json.dumps(results, indent=2) + "\n")
                        continue
                    child[1] = "/workspace"
                    argv = [args.engine, "run", "--rm", "--init",
                            "--mount", f"type=bind,source={root},target=/workspace",
                            "--workdir", "/workspace", "--env", "HOME=/tmp",
                            "--entrypoint", "python3"]
                    if hasattr(os, "getuid"):
                        argv += ["--user", f"{os.getuid()}:{os.getgid()}"]
                    argv += [images[target], f"/workspace/{infra_relative}/scripts/neutrino-ci.py"] + child
                    entry["image"] = images[target]
                    entry["base_image"] = toolchain["image"]
                else:
                    argv = [sys.executable, str(Path(__file__).resolve())] + child
                print(f"RUN {name}/{target} ({entry['coverage']}) — {log}", flush=True)
                start = time.monotonic()
                with log.open("w") as stream:
                    stream.write(shlex.join(argv) + "\n")
                    stream.flush()
                    try:
                        result = subprocess.run(argv, stdout=stream, stderr=subprocess.STDOUT)
                    except OSError as error:
                        stream.write(str(error) + "\n")
                        result = subprocess.CompletedProcess(argv, 127)
                entry.update(status="passed" if result.returncode == 0 else "failed",
                             exit_code=result.returncode, seconds=round(time.monotonic() - start, 1),
                             log=str(log))
                print(f"{entry['status'].upper()} {name}/{target} ({entry['seconds']}s)", flush=True)
                if result.returncode:
                    print("\n".join(log.read_text(errors="replace").splitlines()[-12:]), flush=True)
            results.append(entry)
            (report_dir / "report.json").write_text(json.dumps(results, indent=2) + "\n")
    print(f"Report: {report_dir / 'report.json'}")
    return int(any(r["status"] != "passed" for r in results))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", type=Path, default=INFRA.parent,
                        help="Directory containing Neutrino project checkouts")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("list", help="List projects and local toolchains")
    run = commands.add_parser("run", help="Build and test locally; never invokes GitHub Actions")
    projects = run.add_mutually_exclusive_group(required=True)
    projects.add_argument("--projects", nargs="+", choices=PROJECTS)
    projects.add_argument("--all", action="store_true")
    run.add_argument("--targets", nargs="+", choices=TOOLCHAINS, default=["linux-gcc", "linux-clang"])
    run.add_argument("--engine", default="docker", help="Container engine (docker or podman)")
    build = commands.add_parser("_build", help=argparse.SUPPRESS)
    build.add_argument("--project", choices=PROJECTS, required=True)
    build.add_argument("--target", choices=TOOLCHAINS, required=True)
    for p in (run, build):
        p.add_argument("--jobs", type=int, default=2, help="Parallel build jobs per project")
        p.add_argument("--tests", choices=["auto", "on", "off"], default="auto")
        p.add_argument("--cmake-arg", action="append", default=[], help="Extra CMake argument; use --cmake-arg=-DNAME=VALUE")
    args = parser.parse_args()
    if args.command == "list":
        print("Projects: " + ", ".join(PROJECTS))
        for target, cfg in TOOLCHAINS.items():
            print(f"{target}: {cfg.get('image', 'native ' + cfg.get('host', ''))}")
        return 0
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    try:
        if args.command == "_build":
            build_one(args)
            return 0
        return run_matrix(args)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
