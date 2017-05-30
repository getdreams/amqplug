defmodule Amqplug.Event do
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

  alias Amqplug.Event

  def send_ack(%Event{adapter: adapter, in_channel: channel, delivery_tag: delivery_tag} = event) do
    {:ok, _} = adapter.ack(channel, delivery_tag)
    %{event | state: :acked}
  end

  def send_nack(%Event{adapter: adapter, in_channel: channel, delivery_tag: delivery_tag} = event) do
    {:ok, _} = adapter.nack(channel, delivery_tag)
    %{event | state: :nacked}
  end

  def add_effect(%Event{effects: effects} = event, {_routing_key, _payload} = new_effect) do
    %{event | effects: [new_effect | effects]}
  end

  def set_out_channel(%Event{} = event, channel) do
    %{event | out_channel: channel}
  end

  def publish_effects(%Event{adapter: adapter, out_channel: channel, exchange: exchange, effects: effects} = event) do
    publish_effects(adapter, channel, exchange, effects)
    %{event | state: :effects_published}
  end

  defp publish_effects(_, _, _, []) do
  end

  defp publish_effects(adapter, channel, exchange, [{routing_key, payload} | tail]) do
    Logger.debug("#{__MODULE__} publishing: #{exchange} #{routing_key}, #{payload}")
    adapter.publish(channel, exchange, routing_key, payload)
    publish_effects(adapter, channel, exchange, tail)
  end
end
