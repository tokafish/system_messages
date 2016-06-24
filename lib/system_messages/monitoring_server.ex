defmodule SystemMessages.MonitoringServer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def subscribe(server) do
    GenServer.call(server, :subscribe)
  end

  def subscribers(server) do
    GenServer.call(server, :subscribers)
  end

  def handle_call(:subscribe, {pid, _}, subscribers) do
    ref = Process.monitor(pid)
    {:reply, :ok, Map.put(subscribers, ref, pid)}
  end

  def handle_call(:subscribers, _from, subscribers) do
    {:reply, {:ok, Map.values(subscribers)}, subscribers}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, subscribers) do
    {:noreply, Map.delete(subscribers, ref)}
  end
end
