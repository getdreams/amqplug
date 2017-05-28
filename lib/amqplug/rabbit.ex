defmodule Amqplug.Rabbit do
  def run(pipelines) do
    Amqplug.Rabbit.Supervisor.start_link(pipelines)
  end

  def shutdown() do
  end
end
