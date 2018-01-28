defmodule Amqplug do
  use Application

  def start(_type, _args) do
    Amqplug.Supervisor.start_link(Amqplug.Config.routes())
  end
end
