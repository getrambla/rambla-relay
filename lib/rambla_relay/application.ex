defmodule RamblaRelay.Application do
  use Application

  @impl true
  def start(_type, _args) do
    config = RamblaRelay.RuntimeConfig.boot()

    children = [
      {DNSCluster, query: config.cluster_query || :ignore},
      RamblaRelay.StaticCluster,
      RamblaRelay.Metrics,
      RamblaRelay.Placement,
      RamblaRelay.RuntimeSupervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: RamblaRelay.Supervisor)
  end
end
