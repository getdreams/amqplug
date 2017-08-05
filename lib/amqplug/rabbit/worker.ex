# This is actually a worker, and it could have one more session for outboud messages, passed on to sub worker processes. 
# When we handle a task, we kick off a new process and give it the plug pipeline
defmodule Amqplug.Rabbit.Worker do
  use GenServer
  use AMQP
  
  def start_link(conn, {{_, queue_name, _} = queue, plug}) do 
    GenServer.start(__MODULE__, {conn, queue, plug}, name: String.to_atom(queue_name))
  end

  def init({conn, queue, plug}) do
    send(self(), {:setup, conn})
    {:ok, {plug, queue, nil, nil}}
  end

  def handle_info({:setup, conn}, {plug, {exchange, queue_name, routing_key} = queue, _, _}) do
    {:ok, %AMQP.Channel{pid: in_chan_pid} = in_chan} = Channel.open(conn)
    {:ok, %AMQP.Channel{pid: out_chan_pid} = out_chan} = Channel.open(conn)
    Process.monitor(in_chan_pid)
    Process.monitor(out_chan_pid)
    Queue.declare(in_chan, queue_name, durable: true)
    Queue.bind(in_chan, queue_name, exchange, routing_key: routing_key)
    {:ok, _consumer_tag} = Basic.consume(in_chan, queue_name)
    {:noreply, {plug, queue, in_chan, out_chan}}
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

  def handle_info({:basic_deliver, payload, meta}, {plug, {exchange, _, _}, in_chan, out_chan} = state) do
    event = Amqplug.Rabbit.Event.event(
        in_chan, payload, meta, exchange, out_chan)

    Amqplug.EventDispatcher.dispatch_event(event, plug)

    {:noreply, state}
  end

  # remove?
  def handle_info(ref, state) do
    {:noreply, state}
  end
end
