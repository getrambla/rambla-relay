import Config

if config_env() == :prod do
  {:ok, operations} = RamblaRelay.Config.load()

  config :rambla_relay,
    runtime: operations
end
