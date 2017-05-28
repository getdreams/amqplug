defmodule Amqplug.Testplug do
  import Amqplug.Task

  def init(options) do
    options
  end

  def call(task, _options) do
    task
    |> send_ack
    |> add_effect({"some.route", "some.payload"}) 
    |> add_effect({"another.route", "another.payload"}) 
    |> publish_effects
    :timer.sleep(5000)
  end
end
