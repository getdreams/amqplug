# This is actually a worker, and it could have one more session for outboud messages, passed on to sub worker processes.
# When we handle a task, we kick off a new process and give it the plug pipeline
defmodule Amqplug.Rabbit.Worker do
  require Logger
  use GenServer
  use AMQP

  def start_link(conn, {{_, queue_name, _} = queue, plug}) do
    GenServer.start(__MODULE__, {conn, queue, plug, nil}, name: String.to_atom(queue_name))
  end

  def start_link(conn, {{_, queue_name, _} = queue, plug, plug_init}) do
    GenServer.start(__MODULE__, {conn, queue, plug, plug_init}, name: String.to_atom(queue_name))
  end

  def init({conn, queue, plug, plug_init}) do
    send(self(), {:setup, conn})
    {:ok, {plug, plug_init, queue, nil, nil}}
  end

  def handle_info({:setup, conn}, {
        plug,
        plug_init,
        {exchange, queue_name, routing_key} = queue,
        _,
        _
      }) do
    {:ok, %AMQP.Channel{pid: in_chan_pid} = in_chan} = Channel.open(conn)
    Process.monitor(in_chan_pid)

    {:ok, %AMQP.Channel{pid: out_chan_pid} = out_chan} = Channel.open(conn)
    Process.monitor(out_chan_pid)

    Queue.declare(in_chan, queue_name, durable: true)
    cond do
      is_list(routing_key) ->
        routing_key
        |> Enum.each(fn key ->
          Queue.bind(in_chan, queue_name, exchange, routing_key: key)
        end)
      true ->
        Queue.bind(in_chan, queue_name, exchange, routing_key: routing_key)
    end
    {:ok, _consumer_tag} = Basic.consume(in_chan, queue_name)

    case plug.init(plug_init) do
      {:ok, init} ->
        {:noreply, {plug, init, queue, in_chan, out_chan}}

      {:error, error_msg} ->
        Logger.warn("Failed to initialize plug #{inspect(plug)}: " <> error_msg)
        {:noreply, {plug, nil, queue, in_chan, out_chan}}

      plug_init ->
        # Backwards compatibility
        {:noreply, {plug, plug_init, queue, in_chan, out_chan}}
    end
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  def handle_info(
        {:basic_deliver, payload, meta},
        {plug, plug_init, {exchange, _, _}, in_chan, out_chan} = state
      ) do
    event = Amqplug.Rabbit.Event.event(in_chan, payload, meta, exchange, out_chan)

    Amqplug.EventDispatcher.dispatch_event(event, plug, plug_init)

    {:noreply, state}
  end

  # remove?
  def handle_info(_ref, state) do
    {:noreply, state}
  end
end
