defmodule Amqplug.Testplug do
  import Amqplug.Event

  def init(options) do
    options
  end

  def call(event, _options) do
    event
    |> send_ack
    |> add_effect({"some.route", "some.payload"}) 
    |> add_effect({"another.route", "another.payload"}) 
    |> publish_effects
    :timer.sleep(5000)
  end
end
