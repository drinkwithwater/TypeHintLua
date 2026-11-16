#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
exec cargo build --release --locked "$@"
