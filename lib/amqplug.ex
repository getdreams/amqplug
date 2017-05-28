defmodule Amqplug do
  use Application

  def start(_type, _args) do
    Amqplug.Rabbit.Supervisor.start_link(Amqplug.Config.get_routes)
  end
end
