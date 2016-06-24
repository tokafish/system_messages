defmodule SystemMessages.AddingServer do
  def start_link do
    :proc_lib.start_link(__MODULE__, :init, [self()])
  end

  def init(parent) do
    debug_opts = :sys.debug_options([])
    :proc_lib.init_ack(parent, {:ok, self()})
    loop(parent, debug_opts)
  end

  def loop(parent, debug_opts) do
    receive do
      {:system, from, request} ->
        :sys.handle_system_msg(request, from, parent, __MODULE__, debug_opts, nil)
      {{:add, x, y} = in_msg, from} ->
        debug_opts = :sys.handle_debug(debug_opts, &write_debug/3, nil, {:in, in_msg, from})
        out_msg = {:result, x + y}
        debug_opts = :sys.handle_debug(debug_opts, &write_debug/3, nil, {:out, out_msg, from})
        send from, out_msg
        loop(parent, debug_opts)
    end
  end

  def system_continue(parent, debug_opts, _state) do
    loop(parent, debug_opts)
  end

  def system_terminate(reason, _parent, _debug_options, _state) do
    exit(reason)
  end

  def write_debug(dev, event, _) do
    :io.format(dev, "AddServer got event: ~w~n", [event])
  end

  def add(server, x, y) do
    send server, {{:add, x, y}, self}

    receive do
      {:result, result} -> result
    end
  end
end
