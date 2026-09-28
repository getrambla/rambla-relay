defmodule RamblaRelay.ConfigTest do
  use ExUnit.Case, async: true

  alias RamblaRelay.Config

  test "loads generic release settings with safe local defaults" do
    assert Config.load([]) == {:ok, Config.defaults()}
  end

  test "loads and validates the Capacity mutation timeout" do
    assert Config.defaults().capacity_mutation_timeout_ms == 5_000

    assert {:ok, %{capacity_mutation_timeout_ms: 7_500}} =
             Config.load([{"RAMBLA_RELAY_CAPACITY_MUTATION_TIMEOUT_MS", "7500"}])

    assert Config.load([{"RAMBLA_RELAY_CAPACITY_MUTATION_TIMEOUT_MS", "99"}]) ==
             {:error,
              "RAMBLA_RELAY_CAPACITY_MUTATION_TIMEOUT_MS must be an integer between 100 and 120000"}
  end

  test "rejects a listener hostname that the socket layer cannot bind" do
    assert Config.load([{"RAMBLA_RELAY_HOST", "not-an-ip"}]) ==
             {:error, "RAMBLA_RELAY_HOST must be an IP address"}
  end

  test "rejects an invalid port instead of starting on an unintended listener" do
    assert Config.load([{"RAMBLA_RELAY_PORT", "not-a-port"}]) ==
             {:error, "RAMBLA_RELAY_PORT must be an integer between 1 and 65535"}
  end

  test "recognizes drain mode from the release environment" do
    assert {:ok, %{drain: true, port: 4400}} =
             Config.load([{"RAMBLA_RELAY_DRAIN", "true"}, {"RAMBLA_RELAY_PORT", "4400"}])
  end

  test "requires the websocket heap fuse to admit a maximum legal frame" do
    assert Config.load([{"RAMBLA_RELAY_WEBSOCKET_MAX_HEAP_WORDS", "33554431"}]) ==
             {:error,
              "RAMBLA_RELAY_WEBSOCKET_MAX_HEAP_WORDS must be an integer between 33554432 and 134217728"}

    assert {:ok, %{websocket_max_heap_words: 33_554_432}} =
             Config.load([{"RAMBLA_RELAY_WEBSOCKET_MAX_HEAP_WORDS", "33554432"}])
  end

  test "loads and validates the listener ceiling as connections per acceptor" do
    assert {:ok, %{acceptors: 20, connections_per_acceptor: 750, http_idle_timeout_ms: 10_000}} =
             Config.load([
               {"RAMBLA_RELAY_ACCEPTORS", "20"},
               {"RAMBLA_RELAY_CONNECTIONS_PER_ACCEPTOR", "750"},
               {"RAMBLA_RELAY_HTTP_IDLE_TIMEOUT_MS", "10000"}
             ])

    assert Config.load([{"RAMBLA_RELAY_CONNECTIONS_PER_ACCEPTOR", "0"}]) ==
             {:error,
              "RAMBLA_RELAY_CONNECTIONS_PER_ACCEPTOR must be an integer between 1 and 1000000"}

    assert Config.load([{"RAMBLA_RELAY_HTTP_IDLE_TIMEOUT_MS", "0"}]) ==
             {:error,
              "RAMBLA_RELAY_HTTP_IDLE_TIMEOUT_MS must be an integer between 100 and 120000"}
  end

  test "validates the weighted ingress envelope and delivery limits" do
    assert {:ok,
            %{
              ingress_budget_bytes: 256_000_000,
              ingress_weight: 2,
              delivery_timeout_ms: 5_000,
              transport_send_timeout_ms: 6_000,
              control_queue_bytes: 1_024,
              tcp_receive_buffer_bytes: 32_768
            }} =
             Config.load([
               {"RAMBLA_RELAY_INGRESS_BUDGET_BYTES", "256000000"},
               {"RAMBLA_RELAY_INGRESS_WEIGHT", "2"},
               {"RAMBLA_RELAY_DELIVERY_TIMEOUT_MS", "5000"},
               {"RAMBLA_RELAY_TRANSPORT_SEND_TIMEOUT_MS", "6000"},
               {"RAMBLA_RELAY_CONTROL_QUEUE_BYTES", "1024"},
               {"RAMBLA_RELAY_TCP_RECEIVE_BUFFER_BYTES", "32768"}
             ])

    assert Config.load([
             {"RAMBLA_RELAY_DELIVERY_TIMEOUT_MS", "5000"},
             {"RAMBLA_RELAY_TRANSPORT_SEND_TIMEOUT_MS", "5000"}
           ]) ==
             {:error,
              "RAMBLA_RELAY_DELIVERY_TIMEOUT_MS must be lower than RAMBLA_RELAY_TRANSPORT_SEND_TIMEOUT_MS"}

    assert Config.load([
             {"RAMBLA_RELAY_INGRESS_BUDGET_BYTES", Integer.to_string(128 * 1024 * 1024)},
             {"RAMBLA_RELAY_INGRESS_WEIGHT", "8"}
           ]) ==
             {:error,
              "RAMBLA_RELAY_INGRESS_BUDGET_BYTES must admit one maximum assembled message at the configured weight"}

    assert {:ok, %{memory_watermark_bytes: 0}} =
             Config.load([{"RAMBLA_RELAY_MEMORY_WATERMARK_BYTES", "0"}])

    assert {:ok, %{memory_watermark_bytes: 1_500_000_000}} =
             Config.load([{"RAMBLA_RELAY_MEMORY_WATERMARK_BYTES", "1500000000"}])
  end

  test "requires capacity for one maximum complete message" do
    weight = 5
    exact_budget = RamblaRelay.Protocol.maximum_message_payload_bytes() * weight

    assert {:ok, %{ingress_budget_bytes: ^exact_budget, ingress_weight: ^weight}} =
             Config.load([
               {"RAMBLA_RELAY_INGRESS_BUDGET_BYTES", Integer.to_string(exact_budget)},
               {"RAMBLA_RELAY_INGRESS_WEIGHT", Integer.to_string(weight)}
             ])

    assert Config.load([
             {"RAMBLA_RELAY_INGRESS_BUDGET_BYTES", Integer.to_string(exact_budget - 1)},
             {"RAMBLA_RELAY_INGRESS_WEIGHT", Integer.to_string(weight)}
           ]) ==
             {:error,
              "RAMBLA_RELAY_INGRESS_BUDGET_BYTES must admit one maximum assembled message at the configured weight"}
  end
end
