#more complicated logic here in teh future
defmodule Amqplug.EventDispatcher do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def dispatch_event(event, plug) do
    GenServer.cast(__MODULE__, {:work, {event, plug}})
  end

  def init() do
    {:ok, []}
  end
  
  def handle_cast({:work, {event, plug}}, state) do
    Task.async(fn -> plug.call(event, plug.init([])) end)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
