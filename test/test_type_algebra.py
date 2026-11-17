"""Type API regressions run against embedded sources in isolated processes."""
import json
import shutil
from support import ExecutableTest, ROOT


class TypeAlgebraTests(ExecutableTest):
    def verify_probe(self, case):
        self.assertEqual(case["kind"], "guard", "known defects must be fixed before joining the formal suite")
        destination = self.cwd / "goal"
        destination.mkdir()
        for name in ("support.lua", case["script"]):
            shutil.copyfile(ROOT / "goal" / name, destination / name)
        result = self.cli("run", str(destination / case["script"]))
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertIn(case["outputContains"], result.stdout)


for case in json.loads((ROOT / "goal/cases.json").read_text(encoding="utf-8")):
    def test(self, case=case):
        self.verify_probe(case)
    test.__doc__ = case["title"]
    setattr(TypeAlgebraTests, "test_" + case["id"].lower(), test)
