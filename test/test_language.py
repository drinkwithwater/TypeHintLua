"""File-based conformance and regression tests with reviewed expectations."""
import json
import shutil
import unittest
from support import ExecutableTest, ROOT, TEST_ROOT, assert_diagnostics, load_cases, normalized_diagnostics


class LanguageTests(ExecutableTest):
    def prepare(self, case):
        if "project" in case:
            shutil.copytree(TEST_ROOT / case["project"], self.cwd, dirs_exist_ok=True)
        else:
            shutil.copyfile(TEST_ROOT / case["source"], self.cwd / "main.thlua")
        return case.get("entry", "main.thlua")

    def verify_compile(self, case):
        entry = self.prepare(case)
        result = self.cli("compile", entry, "-o", "emitted.lua")
        if "syntaxError" in case:
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertIn(case["syntaxError"], result.stderr)
            self.assertFalse((self.cwd / "emitted.lua").exists())
        else:
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((self.cwd / "emitted.lua").is_file())
            self.write("validate.thlua", 'assert(loadfile("emitted.lua"))\n')
            validation = self.cli("run", "validate.thlua")
            self.assertEqual(validation.returncode, 0, validation.stderr)
            if "lua" in case:
                self.assertEqual((self.cwd / "emitted.lua").read_text(encoding="utf-8"),
                                 (TEST_ROOT / case["lua"]).read_text(encoding="utf-8"))

    def verify_run(self, case):
        entry = self.prepare(case)
        result = self.cli("run", case.get("run", entry))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, case["stdout"])
        # Execute the emitted result too: erasure must preserve Lua behavior.
        compiled = self.cli("compile", case.get("run", entry), "-o", "emitted.lua")
        self.assertEqual(compiled.returncode, 0, compiled.stderr)
        # Generated Lua may contain labels named `continue`, a thlua keyword.
        # Execute with Lua loadfile rather than parsing generated code as thlua.
        self.write("execute.thlua", 'assert(loadfile("emitted.lua"))()\n')
        result = self.cli("run", "execute.thlua")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, case["stdout"])

    def verify_check(self, case):
        entry = self.prepare(case)
        result = self.cli("check", entry, "--json")
        try:
            actual = normalized_diagnostics(result.stdout, self.cwd)
        except (ValueError, AssertionError) as error:
            self.fail(f"checker did not return valid diagnostics: {error}\n{result.stderr}\n{result.stdout}")
        expected_status = int(any(d["severity"] == 1 for d in case["diagnostics"]))
        try:
            self.assertEqual(result.returncode, expected_status, result.stderr + result.stdout)
            assert_diagnostics(self, actual, case["diagnostics"])
        except AssertionError:
            output = ROOT / "target/test-results" / (case["name"] + ".actual.json")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(json.dumps(actual, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            raise


for case in load_cases():
    for phase in ("compile", "run", "check"):
        if phase == "run" and "stdout" not in case:
            continue
        if phase == "check" and "diagnostics" not in case:
            continue
        def test(self, case=case, phase=phase):
            getattr(self, "verify_" + phase)(case)
        test.__doc__ = case.get("description", case["name"])
        if case.get("knownFailure", {}).get("phase") == phase:
            test = unittest.expectedFailure(test)
            test.__doc__ += " — known issue: " + case["knownFailure"]["reason"]
        setattr(LanguageTests, "test_" + case["name"].replace("/", "_") + "_" + phase, test)
