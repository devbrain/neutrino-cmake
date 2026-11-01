"""Integration checks for the local runner's failure reporting and CTest gates."""

import argparse
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "neutrino-ci.py"
SPEC = importlib.util.spec_from_file_location("local_ci", SCRIPT)
CI = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CI)


@unittest.skipUnless(shutil.which("cmake"), "CMake required")
class LocalCITests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="neutrino-local-ci-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.infra = self.root / "neutrino-cmake"
        self.infra.mkdir()
        self.source = self.root / "fixture"
        self.source.mkdir()
        profiles = {"fixture": {"component": "FIXTURE", "target": "fixture", "headers": []}}
        toolchains = {"native": {"tests": True, "configure": []}}
        self.patches = patch.multiple(CI, INFRA=self.infra, PROJECTS=profiles, TOOLCHAINS=toolchains)
        self.patches.start()
        self.addCleanup(self.patches.stop)
        self.args = argparse.Namespace(workspace=self.root, project="fixture", target="native",
                                       tests="auto", jobs=2, cmake_arg=[])

    def project(self, tests=""):
        (self.source / "CMakeLists.txt").write_text(
            "cmake_minimum_required(VERSION 3.24)\nproject(fixture LANGUAGES CXX)\n"
            "add_library(fixture INTERFACE)\n" + tests)

    def test_consumer_registered_when_project_tests_disabled(self):
        self.project()
        self.args.tests = "off"
        CI.build_one(self.args)
        build = self.infra / ".local-ci/build/fixture/native"
        subprocess.run(["ctest", "--test-dir", str(build), "-C", "Release", "--no-tests=error"], check=True)

    def test_consumer_does_not_hide_missing_project_tests(self):
        self.project()
        with self.assertRaisesRegex(ValueError, "No project tests"):
            CI.build_one(self.args)

    def test_project_test_failure_propagates(self):
        self.project('enable_testing()\nadd_test(NAME broken COMMAND "${CMAKE_COMMAND}" -E false)\n')
        with self.assertRaises(subprocess.CalledProcessError):
            CI.build_one(self.args)

    def test_unsupported_target_is_not_reported_as_success(self):
        self.project()
        CI.PROJECTS["fixture"]["unsupported"] = {"native": "Test platform limitation"}
        args = argparse.Namespace(workspace=self.root, projects=["fixture"], all=False,
                                  targets=["native"], tests="auto", jobs=2, cmake_arg=[], engine="docker")
        with patch.object(CI.subprocess, "run") as run, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(CI.run_matrix(args), 1)
            run.assert_not_called()
        report = next((self.infra / ".local-ci/runs").glob("*/report.json"))
        self.assertEqual(json.loads(report.read_text())[0]["status"], "unsupported")


if __name__ == "__main__":
    unittest.main()
