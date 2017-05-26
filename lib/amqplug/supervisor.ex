defmodule Amqplug.Supervisor do
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    import Supervisor.Spec

    children = [
      worker(Amqplug.Adapters.Rabbit.Connection, [], [id: make_ref()])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
