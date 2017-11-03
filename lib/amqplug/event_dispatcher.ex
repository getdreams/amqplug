#more complicated logic here in teh future
defmodule Amqplug.EventDispatcher do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def dispatch_event(event, plug, plug_init) do
    GenServer.cast(__MODULE__, {:work, {event, plug, plug_init}})
  end

  def init() do
    {:ok, []}
  end

  def handle_cast({:work, {event, plug, plug_init}}, state) do
    Task.async(fn -> plug.call(event, plug_init) end)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
