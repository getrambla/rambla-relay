defmodule RamblaRelay.RuntimeSupervisor do
  @moduledoc false

  use Supervisor

  def start_link(_options), do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    children = [
      RamblaRelay.Capacity,
      {RamblaRelay.Listener, ref: RamblaRelay.Listener}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
