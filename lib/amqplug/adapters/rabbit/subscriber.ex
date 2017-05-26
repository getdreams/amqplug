defmodule Amqplug.Adapters.Rabbit.Subscriber do
  use GenServer
  use AMQP

  @url "amqp://guest:guest@localhost"
  @exchange "world"
  @queue "#"

  def start_link(route) do 
    GenServer.start(__MODULE__, [route], [])
  end

  def init([route]) do
    {:ok, conn} = Connection.open(@url)
    {:ok, chan} = Channel.open(conn)
    Queue.declare(chan, @queue, auto_delete: true)
    Queue.bind(chan, @queue, @exchange, routing_key: route)
    {:ok, _consumer_tag} = Basic.consume(chan, @queue)
    {:ok, {chan, @exchange}}
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

  def handle_info({:basic_deliver, payload, meta}, {chan, exchange} = state) do
    task = Amqplug.Adapters.Rabbit.Task.task(chan, payload, meta, exchange)
    IO.inspect task
    IO.puts "============================================================="
    {:noreply, state}
  end
end
