defmodule Amqplug.Adapters.Rabbit do
  def run(pipelines) do
    Amqplug.Adapters.Rabbit.Supervisor.start_link(pipelines)
  end

  def shutdown() do
  end
end
