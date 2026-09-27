# Rambla Relay — Agent Guide

Rambla Relay is a distributed, protocol-compatible WebSocket relay for
[Rambla](https://github.com/getrambla/rambla). Daemons and clients meet here by
`serverId`; frames are end-to-end encrypted by the Rambla protocol, so the
relay never sees content. It is written in Elixir/OTP: Cowboy/Ranch serves the
public listener, a per-`serverId` owner process pins each session to one BEAM
node via [Syn](https://hexdocs.pm/syn/readme.html), and a deployment adapter
reroutes WebSocket upgrades to the owning node so frames never cross nodes.

**This is critical production infrastructure.** People run their entire
working day through it, and a blip of even a few seconds is user-visible.
Read the bar and the diagnostics discipline in
[OPERATIONS.md](OPERATIONS.md) before touching anything production-shaped —
in particular: never dump full process state (`:sys.get_state/1`) on live
nodes, and never stack production actions.

## Docs

| Doc | What's in it |
| --- | --- |
| [README.md](README.md) | Protocol compatibility, dev setup, configuration reference, black-box load testing |
| [OPERATIONS.md](OPERATIONS.md) | The production bar, diagnostics discipline, capacity model, failure behavior, metrics/alerting |
| [TDD.md](TDD.md) | Red/green evidence log for every behavior — the test methodology record |
| [deployment/fly/README.md](deployment/fly/README.md) | The Fly.io adapter: bootstrap, manual deployment policy, and a generic health-check/incident cookbook |

<!-- RAMBLA-FORK: fix: 2026-09-27-fix-remove-fly.md: no-Fly rule replaces the Fly narrative; this file is the authority overriding Fly language elsewhere. -->

**This fork does not deploy on Fly, and Fly must not be used for any
deployment work here.** The Fly adapter is upstream's, absorbed by the
rebrand, kept only as an inherited artifact under `deployment/fly/`. This
file is the authority: it overrides any Fly-sounding language anywhere else
in the repo, including verbatim upstream docs.

## Development

```sh
asdf install
mix deps.get
mix test
mix format --check-formatted
MIX_ENV=prod mix release        # production release build
```

## Conventions

- **Platform-agnostic core.** Nothing under `lib/` or `scripts/` may depend
  on a deployment provider. Provider specifics live in explicit adapters
  under `deployment/`; the core speaks only the generic settings documented
  in README.md.
- **Tests use real dependencies.** Real Cowboy/Ranch listeners, real WebSockets,
  real `:peer` BEAM nodes for distributed behavior — no mocks of the things
  under test. Every behavior change gets a red test first; record the
  red/green evidence in TDD.md as the existing entries do.
- **Fail closed.** Sockets monitor the processes they depend on (Owner,
  Writer, connection budget) and close with an explicit code rather than lingering in a
  half-alive state. Follow that pattern for anything new.
- **No silent capacity changes.** Listener ceilings, connection limits, and
  timeouts are part of the operational contract in OPERATIONS.md — change
  the doc in the same commit.
