defmodule RamblaRelay.Application do
  use Application

  @impl true
  def start(_type, _args) do
    config =
      RamblaRelay.Config.normalize(
        Application.get_env(:rambla_relay, :runtime, RamblaRelay.Config.defaults())
      )

    children = [
      {DNSCluster, query: config.cluster_query || :ignore},
      {RamblaRelay.Drain, config.drain},
      RamblaRelay.Metrics,
      {RamblaRelay.RuntimeSupervisor, config}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: RamblaRelay.Supervisor)
  end
end
