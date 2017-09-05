defmodule Amqplug.Event do
  require Logger
  require Poison
  defstruct adapter:      nil,
            state:        :received,
            in_channel:   nil,
            routing_key:  nil,
            headers:      nil,
            payload:      nil,
            delivery_tag: nil,
            out_channel:  nil,
            exchange:     nil,
            effects:      []

  alias Amqplug.Event

  def send_ack(%Event{adapter: adapter, in_channel: channel, delivery_tag: delivery_tag, payload: payload, exchange: exchange, routing_key: routing_key} = event) do
    {:ok, _} = adapter.ack(channel, delivery_tag)
    Logger.info("#{__MODULE__} received: #{exchange} #{routing_key}, #{payload}")
    %{event | state: :acked}
  end

  def send_nack(%Event{adapter: adapter, in_channel: channel, delivery_tag: delivery_tag, payload: payload, exchange: exchange, routing_key: routing_key} = event) do
    {:ok, _} = adapter.nack(channel, delivery_tag)
    Logger.info("#{__MODULE__} received: #{exchange} #{routing_key}, #{payload}")
    %{event | state: :nacked}
  end

  def add_effect(%Event{effects: effects} = event, {_routing_key, _payload} = new_effect) do
    %{event | effects: [new_effect | effects]}
  end

  def add_effect(%Event{effects: effects} = event, {_routing_key, _payload, _opts} = new_effect) do
    %{event | effects: [new_effect | effects]}
  end

  def set_out_channel(%Event{} = event, channel) do
    %{event | out_channel: channel}
  end

  def decode_json_payload(%Amqplug.Event{payload: payload} = event) do
    case Poison.decode(payload) do
      {:ok, parsed} ->
        %{event | payload: parsed}
      _ ->
        %{event | payload: payload}
    end
  end

  def log_inbound(%Amqplug.Event{payload: payload} = event) do
    Logger.info("#{inspect payload}")
    event
  end

  def publish_effects(%Event{adapter: adapter, out_channel: channel, exchange: exchange, effects: effects} = event) do
    publish_effects(adapter, channel, exchange, effects)
    %{event | state: :effects_published}
  end

  def publish_single(%Event{adapter: adapter, out_channel: channel, exchange: exchange} = event, {routing_key, payload}) do
    Logger.info("#{__MODULE__} publishing: #{exchange} #{routing_key}, #{payload}")
    adapter.publish(channel, exchange, routing_key, payload)
    event
  end

  def publish_single(%Event{adapter: adapter, out_channel: channel, exchange: exchange} = event, {routing_key, payload, opts}) do
    Logger.info("#{__MODULE__} publishing: #{exchange} #{routing_key}, #{payload}")
    adapter.publish(channel, exchange, routing_key, payload, opts)
    event
  end

  defp publish_effects(_, _, _, []) do
  end

  defp publish_effects(adapter, channel, exchange, [ head | tail ]) do
    case head do
      {routing_key, payload} -> 
        Logger.info("#{__MODULE__} publishing: #{exchange} #{routing_key}, #{payload}")
        adapter.publish(channel, exchange, routing_key, payload)
        publish_effects(adapter, channel, exchange, tail)
      {routing_key, payload, opts} -> 
        Logger.info("#{__MODULE__} publishing: #{exchange} #{routing_key}, #{payload}")
        adapter.publish(channel, exchange, routing_key, payload, opts)
        publish_effects(adapter, channel, exchange, tail)
    end
  end

  def get_header(%Event{headers: headers}, header_key) do
    case headers do
      [] -> {:error}
      headers ->
        get_specific_header(headers, header_key)
    end
  end

  defp get_specific_header(headers, header_key) do
    reference =
      Enum.filter(headers, fn({key, _, _}) -> key == header_key end)
      |> Enum.map(fn({_, _, ref_value}) -> ref_value end)
      |> List.first
    case reference do
      [] -> {:error}
      nil -> {:error}
      _ -> {:ok, reference}
    end
  end
end
