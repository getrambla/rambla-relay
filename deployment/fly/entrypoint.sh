#!/bin/sh
set -eu

# This adapter is the only place provider inputs are named. The release itself
# receives the same generic contract used by every other deployment target.
if [ -n "${FLY_PRIVATE_IP:-}" ] && [ -z "${RELEASE_NODE:-}" ]; then
  export RELEASE_NODE="rambla_relay@${FLY_PRIVATE_IP}"
fi

export RELEASE_DISTRIBUTION=name
export ERL_AFLAGS="${ERL_AFLAGS:-} -proto_dist inet6_tcp"
export ELIXIR_ERL_OPTIONS="${ELIXIR_ERL_OPTIONS:-} +fnu"
export RAMBLA_RELAY_CLUSTER_QUERY="${RAMBLA_RELAY_CLUSTER_QUERY:-${FLY_APP_NAME}.internal}"
export RAMBLA_RELAY_OWNERSHIP_TARGET="instance=${FLY_MACHINE_ID}"
export RAMBLA_RELAY_REROUTE_HEADER="${RAMBLA_RELAY_REROUTE_HEADER:-fly-replay}"
export RAMBLA_RELAY_MIN_CLUSTER_SIZE="${RAMBLA_RELAY_MIN_CLUSTER_SIZE:-2}"

ulimit -n "${RAMBLA_RELAY_NOFILE:-100000}"

exec /app/bin/rambla_relay start
