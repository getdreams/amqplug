defmodule Amqplug.Router do
  def run() do
    pipeline_one =
      {{"world", "test_queue_one", "router_one"}, Amqplug.Testplug}
    pipeline_two =
      {{"world", "test_queue_two", "router_two"}, Amqplug.Testplug}
    Amqplug.Adapters.Rabbit.run([pipeline_one, pipeline_two])
  end
end
