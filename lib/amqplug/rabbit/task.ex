defmodule Amqplug.Rabbit.Event do
  def event(channel, payload, %{routing_key: routing_key, delivery_tag: delivery_tag}, exchange, out_channel) do
    %Amqplug.Event{
      adapter:      __MODULE__, 
      in_channel:   channel,
      routing_key:  routing_key,
      payload:      payload,
      delivery_tag: delivery_tag,
      exchange:     exchange,
      out_channel:  out_channel
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

  def publish(channel, exchange, routing_key, payload, opts) do
    AMQP.Basic.publish(channel, exchange, routing_key, payload, opts)
  end
end
