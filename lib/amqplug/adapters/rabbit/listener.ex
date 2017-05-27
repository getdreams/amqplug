defmodule Amqplug.Adapters.Rabbit.Listener do
  use GenServer
  use AMQP
  
  alias Amqplug.Adapters.Rabbit.Task

  def start_link(conn, queue) do 
    GenServer.start(__MODULE__, {conn, queue, nil}, [])
  end

  def init({conn, {exchange, queue_name, routing_key} = queue, _}) do
    {:ok, chan} = Channel.open(conn)
    Queue.declare(chan, queue_name, auto_delete: true)
    Queue.bind(chan, queue_name, exchange, routing_key: routing_key)
    {:ok, _consumer_tag} = Basic.consume(chan, queue_name)
    {:ok, {conn, queue, chan}}
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

  def handle_info({:basic_deliver, payload, meta}, {_, {exchange, _, _}, chan} = state) do
    task = Task.task(chan, payload, meta, exchange)
    IO.inspect task
    IO.puts "============================================================="
    {:noreply, state}
  end
end
