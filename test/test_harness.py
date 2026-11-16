"""The test harness itself must reject missing/extra/wrong diagnostics."""
import json
import re
from pathlib import Path
import tempfile
import unittest
from support import TEST_ROOT, assert_diagnostics, load_cases, normalized_diagnostics


class HarnessTests(unittest.TestCase):
    def test_duplicate_diagnostics_are_counted(self):
        diagnostic = {"file": "main.thlua", "line": 1, "severity": 1, "message": "wrong type"}
        with self.assertRaises(AssertionError):
            assert_diagnostics(self, [diagnostic, diagnostic], [diagnostic])

    def test_missing_diagnostic_fails(self):
        with self.assertRaises(AssertionError):
            assert_diagnostics(self, [], [{"file": "main.thlua", "line": 1, "severity": 1, "contains": "wrong type"}])

    def test_wrong_location_or_severity_fails(self):
        diagnostic = {"file": "main.thlua", "line": 1, "severity": 1, "message": "wrong type"}
        for key, value in (("line", 2), ("severity", 2), ("message", "unrelated error")):
            with self.subTest(key=key), self.assertRaises(AssertionError):
                assert_diagnostics(self, [diagnostic], [dict(diagnostic, **{key: value})])

    def test_valid_empty_diagnostics(self):
        self.assertEqual(normalized_diagnostics("[]", Path.cwd()), [])
        assert_diagnostics(self, [], [])

    def test_invalid_checker_output_fails(self):
        for output in ('{}', 'not JSON', '[null]', '["wrong"]', '[{"severity":1}]'):
            with self.subTest(output=output), self.assertRaises((ValueError, AssertionError)):
                normalized_diagnostics(output, Path.cwd())

    def test_manifest_rejects_duplicate_names(self):
        cases = load_cases()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "manifest.json"
            path.write_text(json.dumps([cases[0], cases[0]]), encoding="utf-8")
            with self.assertRaises(ValueError):
                load_cases(path)

    def test_all_new_fixtures_are_registered(self):
        cases = load_cases()
        registered = {(TEST_ROOT / c["source"]).resolve() for c in cases if "source" in c}
        projects = [(TEST_ROOT / c["project"]).resolve() for c in cases if "project" in c]
        fixtures = {p.resolve() for p in (TEST_ROOT / "cases").rglob("*.thlua")
                    if not any(p.resolve().is_relative_to(project) for project in projects)}
        self.assertEqual(fixtures, {p for p in registered if p.is_relative_to(TEST_ROOT / "cases")})

    def test_legacy_markers_match_manifest(self):
        severity = {"E": 1, "W": 2, "I": 3, "H": 4}
        for case in load_cases():
            if not case["name"].startswith("legacy/"):
                continue
            with self.subTest(case=case["name"]):
                expected = {(d["line"], d["severity"]) for d in case["diagnostics"]}
                marked = set()
                for line, text in enumerate((TEST_ROOT / case["source"]).read_text(encoding="utf-8").splitlines(), 1):
                    marker = re.search(r"--([EWIH])(?:\s*$|:)", text)
                    if marker:
                        marked.add((line, severity[marker[1]]))
                self.assertEqual(marked, expected)

    def test_unknown_known_failure_phase_rejected(self):
        case = dict(load_cases()[0], knownFailure={"phase": "typo", "reason": "must not silently skip"})
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "manifest.json"
            path.write_text(json.dumps([case]), encoding="utf-8")
            with self.assertRaises(ValueError):
                load_cases(path)
