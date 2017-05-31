defmodule Amqplug.Testplug do
  import Amqplug.Event

  def init(options) do
    options
  end

  def call(event, _options) do
    event
    |> send_ack
    |> add_effect({"some.route", "BEFORE"})
    |> publish_effects
    :timer.sleep(30000)

    event
    |> add_effect({"some.route", "AFTER"})
    |> publish_effects
    :timer.sleep(30000)
  end
end
