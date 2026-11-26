defmodule RamblaRelay.Drain do
  @moduledoc """
  Admission state for graceful relay maintenance: the live `drain` setting.

  Starting a drain makes readiness fail immediately. Existing relay sessions are
  intentionally left to the protocol/routing layer, which can close them after
  its own grace period.
  """

  def begin, do: put(true)
  def cancel, do: put(false)
  def draining?, do: RamblaRelay.RuntimeConfig.current().drain

  defp put(drain) do
    {:ok, _settings} = RamblaRelay.RuntimeConfig.put(%{drain: drain})
    :ok
  end
end
