#!/bin/sh
set -eu

ulimit -n "${RAMBLA_RELAY_LOAD_NOFILE:-30000}"
exec "$@"
