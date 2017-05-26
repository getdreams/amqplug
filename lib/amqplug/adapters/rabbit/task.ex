defmodule Amqplug.Adapters.Rabbit.Task do
  def task(channel, payload, %{routing_key: routing_key, delivery_tag: delivery_tag}, exchange) do
    %Amqplug.Task{
      adapter:      __MODULE__, 
      in_channel:   channel,
      routing_key:  routing_key,
      payload:      payload,
      delivery_tag: delivery_tag,
      exchange:     exchange
    }
  end

  def ack(channel, delivery_tag) do
    AMQP.Basic.ack(channel, delivery_tag)
    {:ok, delivery_tag}
  end

  def nack(channel, delivery_tag) do
    AMQP.Basic.nack(channel, delivery_tag)
    {:ok, delivery_tag}
  end

  def publish(channel, exchange, routing_key, payload) do
    AMQP.Basic.publish(channel, exchange, routing_key, payload)
  end
end