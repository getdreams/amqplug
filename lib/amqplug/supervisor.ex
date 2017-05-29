defmodule Amqplug.Supervisor do
  def start_link(pipelines) do
    Supervisor.start_link(__MODULE__, pipelines, name: __MODULE__)
  end

  def init(pipelines) do
    import Supervisor.Spec

    children = [
      worker(Amqplug.Rabbit.Connection, [pipelines], [id: make_ref()]),
      worker(Amqplug.Manager, [], [id: make_ref()])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
