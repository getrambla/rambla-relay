defmodule RamblaRelay.RuntimeSupervisor do
  @moduledoc false

  use Supervisor

  def start_link(config), do: Supervisor.start_link(__MODULE__, config, name: __MODULE__)

  @impl true
  def init(config) do
    children = [
      {RamblaRelay.Capacity, config},
      {RamblaRelay.Listener, ref: RamblaRelay.Listener, config: config}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
