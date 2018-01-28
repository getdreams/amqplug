defmodule Amqplug.Testplug do
  import Amqplug.Event

  def init(options) do
    options
  end

  def call(event, _options) do
    event
    |> publish_single({"futures.list", "single no header"})

    :timer.sleep(1000)

    event
    |> publish_single({"futures.list", "single with header", headers: [{"reference", "ref"}]})

    :timer.sleep(1000)

    event
    |> publish_single(
      {"futures.list", "single with two headers", headers: [{"reference", "ref"}, {"key", "val"}]}
    )

    :timer.sleep(1000)

    event
    |> send_ack
    |> add_effect({"futures.list", "add no header"})
    |> publish_effects

    :timer.sleep(1000)

    event
    |> add_effect({"futures.list", "add with header", headers: [{"reference", "ref"}]})
    |> publish_effects

    :timer.sleep(1000)
  end
end
