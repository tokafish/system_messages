defmodule SystemMessages.MonitoringServerTest do
  use ExUnit.Case
  alias SystemMessages.MonitoringServer

  test "server cleans up monitored pids on a down message (fails)" do
    {:ok, server} = MonitoringServer.start_link
    test = self
    test_child = spawn fn ->
      :ok = MonitoringServer.subscribe(server)
      send test, :proceed

      receive do
        :terminate -> :ok
      end
    end

    assert_receive :proceed
    assert {:ok, [test_child]} == MonitoringServer.subscribers(server)

    send test_child, :terminate

    assert {:ok, []} == MonitoringServer.subscribers(server)
  end

  test "server cleans up monitored pids on a down message (succeeds)" do
    {:ok, server} = MonitoringServer.start_link
    test = self
    test_child = spawn fn ->
      :ok = MonitoringServer.subscribe(server)
      send test, :proceed

      receive do
        :terminate -> :ok
      end
    end

    assert_receive :proceed
    assert {:ok, [test_child]} == MonitoringServer.subscribers(server)

    dbg_fn = fn
      :waiting_for_down, {:in, {:DOWN, _, _, _, _}}, _ ->
        send test, :monitor_complete
        :done
      func_state, _, _ -> func_state
    end
    :sys.install(server, {dbg_fn, :waiting_for_down})
    send test_child, :terminate
    assert_receive :monitor_complete

    assert {:ok, []} == MonitoringServer.subscribers(server)
  end
end
