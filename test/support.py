"""Shared executable-test utilities. Importing this module never consumes argv."""
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
TEST_ROOT = ROOT / "test"
BINARY = Path(os.environ.get("THLUA_TEST_BINARY", ROOT / "target/debug" /
                            ("thlua.exe" if os.name == "nt" else "thlua"))).resolve()


def command(binary, cwd, *args):
    env = os.environ.copy()
    env.update(LUA_PATH="", LUA_CPATH="")
    return subprocess.run([str(binary), *args], cwd=cwd, env=env,
                          capture_output=True, encoding="utf-8", timeout=30)


def normalized_diagnostics(output, cwd):
    values = json.loads(output)
    if not isinstance(values, list):
        raise AssertionError("checker output must be a JSON diagnostic array")
    result = []
    for value in values:
        if not isinstance(value, dict) or set(value) != {"file", "line", "column", "severity", "message"}:
            raise AssertionError(f"invalid diagnostic fields: {value}")
        if not isinstance(value["file"], str) or not isinstance(value["message"], str):
            raise AssertionError(f"diagnostic file/message must be strings: {value}")
        for key in ("line", "column", "severity"):
            if type(value[key]) is not int:
                raise AssertionError(f"{key} must be an integer: {value}")
        if value["line"] < 1 or value["column"] < 0 or value["severity"] not in range(1, 5):
            raise AssertionError(f"invalid diagnostic position/severity: {value}")
        value = dict(value)
        value["file"] = value["file"].replace("\\", "/").removeprefix("./")
        value["message"] = value["message"].replace(str(cwd), "<workspace>").replace("\\", "/").strip()
        result.append(value)
    return sorted(result, key=lambda d: (d["file"], d["line"], d["column"], d["severity"], d["message"]))


def assert_diagnostics(test, actual, expected):
    # Consume every diagnostic exactly once, including duplicate diagnostics.
    # More specific expectations go first so a broad substring cannot hide one.
    test.assertEqual(len(actual), len(expected), f"diagnostic count mismatch\nactual: {actual}\nexpected: {expected}")
    remaining = list(actual)
    for want in sorted(expected, key=lambda d: (len(d), len(d.get("contains", ""))), reverse=True):
        def matches(got):
            return all((value in got["message"] if key == "contains" else got.get(key) == value)
                       for key, value in want.items())
        index = next((i for i, got in enumerate(remaining) if matches(got)), None)
        test.assertIsNotNone(index, f"missing diagnostic: {want}\nactual: {actual}")
        remaining.pop(index)


def load_cases(path=None):
    path = path or TEST_ROOT / "cases/manifest.json"
    cases = json.loads(path.read_text(encoding="utf-8"))
    names = set()
    for case in cases:
        name = case["name"]
        if name in names or not re.fullmatch(r"[a-z0-9_/]+", name):
            raise ValueError(f"invalid/duplicate case name: {name}")
        names.add(name)
        if ("source" in case) == ("project" in case):
            raise ValueError(f"{name}: choose source or project")
        relative = Path(case.get("source", case.get("project")))
        source = (TEST_ROOT / relative).resolve()
        if relative.is_absolute() or not source.is_relative_to(TEST_ROOT) or not source.exists():
            raise ValueError(f"{name}: invalid fixture path: {relative}")
        if "syntaxError" in case and ("diagnostics" in case or "stdout" in case):
            raise ValueError(f"{name}: invalid syntax fixtures cannot run/check")
        if not any(key in case for key in ("syntaxError", "stdout", "diagnostics", "compile")):
            raise ValueError(f"{name}: fixture has no expectations")
        known = case.get("knownFailure")
        if known and (known.get("phase") not in ("compile", "run", "check") or not known.get("reason")
                      or (known["phase"] == "run" and "stdout" not in case)
                      or (known["phase"] == "check" and "diagnostics" not in case)):
            raise ValueError(f"{name}: knownFailure needs a tested phase and an explanation")
        for diagnostic in case.get("diagnostics", []):
            if not {"file", "line", "severity"}.issubset(diagnostic) or not ({"message", "contains"} & diagnostic.keys()):
                raise ValueError(f"{name}: incomplete diagnostic expectation: {diagnostic}")
    return cases


class ExecutableTest(unittest.TestCase):
    def setUp(self):
        if not BINARY.is_file():
            self.fail(f"executable missing: {BINARY}; run python test.py first")
        directory = tempfile.TemporaryDirectory(prefix="thlua-语法-")
        self.addCleanup(directory.cleanup)
        self.cwd = Path(directory.name)

    def cli(self, *args):
        return command(BINARY, self.cwd, *args)

    def write(self, name, content):
        path = self.cwd / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8", newline="")
        return path
