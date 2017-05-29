#more complicated logic here in teh future
defmodule Amqplug.Manager do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def process_task_with_plug(task, plug) do
    GenServer.cast(__MODULE__, {:work, {task, plug}})
  end

  def init() do
    {:ok, []}
  end
  
  def handle_cast({:work, {task, plug}}, state) do
    Task.async(fn -> plug.call(task, plug.init([])) end)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
