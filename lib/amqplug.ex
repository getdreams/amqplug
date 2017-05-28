defmodule Amqplug do
  use Application

  def start(_type, _args) do
    Amqplug.Rabbit.Supervisor.start_link(Amqplug.Config.routes)
  end
end
