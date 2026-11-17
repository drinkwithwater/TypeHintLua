"""Build and run the repository's Rust, language, CLI, and LSP tests."""
import argparse
import os
from pathlib import Path
import subprocess
import sys
import unittest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, help="test an existing executable without rebuilding")
    parser.add_argument("--no-build", action="store_true", help="skip Cargo build/unit tests")
    parser.add_argument("--release", action="store_true", help="build/test the release profile")
    parser.add_argument("--filter", default="", help="run tests whose full names contain this text")
    parser.add_argument("--list", action="store_true", help="list Python tests without building/running")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    binary = (args.binary.resolve() if args.binary else root / "target" /
              ("release" if args.release else "debug") / ("thlua.exe" if os.name == "nt" else "thlua"))
    if not (args.no_build or args.binary or args.list):
        profile = ["--release"] if args.release else []
        for command in (["cargo", "test", "--locked", *profile], ["cargo", "build", "--locked", *profile]):
            subprocess.run(command, cwd=root, check=True)
    os.environ["THLUA_TEST_BINARY"] = str(binary)
    sys.path.insert(0, str(root / "test"))
    import test_language
    import test_harness
    import rust_cli
    import test_type_algebra
    suite = unittest.TestSuite()
    def select(tests):
        for test in tests:
            if isinstance(test, unittest.TestSuite):
                select(test)
            elif args.filter in test.id():
                if args.list:
                    print(test.id())
                suite.addTest(test)
    loader = unittest.TestLoader()
    for module in (test_language, test_harness, rust_cli, test_type_algebra):
        select(loader.loadTestsFromModule(module))
    if not suite.countTestCases():
        parser.error("no tests matched; refusing a vacuous success")
    if args.list:
        print(f"{suite.countTestCases()} tests")
        return 0
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(main())
