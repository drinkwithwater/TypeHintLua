"""Run documented type-display probes; known defects are matched explicitly."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / "tostringGoal"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, default=ROOT / "target/debug" /
                        ("thlua.exe" if os.name == "nt" else "thlua"))
    parser.add_argument("--filter", default="", help="substring of ID, script path or title")
    parser.add_argument("--list", action="store_true", help="list probes without running")
    parser.add_argument("--strict", action="store_true", help="also fail for reproduced known defects")
    args = parser.parse_args()
    cases = json.loads((FOLDER / "cases.json").read_text(encoding="utf-8"))
    for case in cases:
        if case.get("kind") not in {"regression", "guard", "observation"}:
            parser.error(f"invalid probe kind: {case.get('kind')}")
        if case["kind"] == "regression" and not case.get("failureContains"):
            parser.error(f"missing correctness assertion marker: {case['id']}")
    ids = [case["id"] for case in cases]
    scripts = [case["script"] for case in cases]
    if len(set(ids)) != len(ids) or len(set(scripts)) != len(scripts):
        parser.error("duplicate probe ID or script")
    if set(scripts) != {p.name for p in FOLDER.glob("[0-9][0-9]_*.lua")}:
        parser.error("numbered probes and cases.json must match exactly")
    selected = [case for case in cases if args.filter in
                " ".join((case["id"], case["script"], case["title"]))]
    if not selected:
        parser.error("no probes matched")
    if args.list:
        for case in selected:
            print(f'{case["id"]} {case["kind"]}: {case["script"]}')
        return 0
    binary = args.binary.resolve()
    if not binary.is_file():
        parser.error(f"executable missing: {binary}; run cargo build --locked first")
    env = os.environ.copy()
    env.update(LUA_PATH="", LUA_CPATH="")
    reproduced, passed, errors = 0, 0, 0
    for case in selected:
        try:
            result = subprocess.run([str(binary), "run", str(FOLDER / case["script"])],
                                    cwd=ROOT, env=env, capture_output=True,
                                    encoding="utf-8", timeout=25)
        except (OSError, subprocess.TimeoutExpired) as error:
            print(f'ERROR {case["id"]}: {error}')
            errors += 1
            continue
        if case["kind"] == "regression":
            matched = (result.returncode == 1 and case["failureContains"] in result.stderr
                       and case["outputContains"] in result.stdout)
            if matched:
                status = "REPRODUCED"
                reproduced += 1
            else:
                status = "UNEXPECTED_PASS" if result.returncode == 0 else "ERROR"
                errors += 1
        elif result.returncode == 0 and case["outputContains"] in result.stdout:
            status = "PASS"
            passed += 1
        else:
            status = "ERROR"
            errors += 1
        print(f'{status} {case["id"]}: {case["script"]}')
        if result.stdout:
            print(result.stdout.rstrip())
        if status in ("ERROR", "UNEXPECTED_PASS"):
            print(result.stderr.rstrip())
            print("Review the documented contract before changing cases.json.")
    print(f"{len(selected)} probes: {passed} passed, {reproduced} known defects reproduced, {errors} unexpected results")
    return int(errors > 0 or (args.strict and reproduced > 0))


if __name__ == "__main__":
    sys.exit(main())
