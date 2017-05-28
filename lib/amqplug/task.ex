defmodule Amqplug.Task do
  require Logger
  defstruct adapter:      nil,
            state:        :received,
            in_channel:   nil,
            routing_key:  nil,
            payload:      nil,
            delivery_tag: nil,
            out_channel:  nil,
            exchange:     nil,
            effects:      []

  alias Amqplug.Task

  def send_ack(%Task{adapter: adapter, in_channel: channel, delivery_tag: delivery_tag} = task) do
    {:ok, _} = adapter.ack(channel, delivery_tag)
    %{task | state: :acked}
  end

  def send_nack(%Task{adapter: adapter, in_channel: channel, delivery_tag: delivery_tag} = task) do
    {:ok, _} = adapter.nack(channel, delivery_tag)
    %{task | state: :nacked}
  end

  def add_effect(%Task{effects: effects} = task, {_routing_key, _payload} = new_effect) do
    %{task | effects: [new_effect | effects]}
  end

  def set_out_channel(%Task{} = task, channel) do
    %{task | out_channel: channel}
  end

  def publish_effects(%Task{adapter: adapter, out_channel: channel, exchange: exchange, effects: effects} = task) do
    publish_effects(adapter, channel, exchange, effects)
    %{task | state: :effects_published}
  end

  defp publish_effects(_, _, _, []) do
  end

  defp publish_effects(adapter, channel, exchange, [{routing_key, payload} | tail]) do
    Logger.debug("#{__MODULE__} publishing: #{exchange} #{routing_key}, #{payload}")
    adapter.publish(channel, exchange, routing_key, payload)
    publish_effects(adapter, channel, exchange, tail)
  end
end
