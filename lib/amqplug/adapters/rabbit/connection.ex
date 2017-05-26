defmodule Amqplug.Adapters.Rabbit.Connection do
  use GenServer
  require Logger
  alias Amqplug.Config
  alias Amqplug.Adapters.Rabbit.{Connection, Subscriber}

  @reconnect_interval 5_000
  def start_link({host, _, _} = state) do
    Logger.debug("#{__MODULE__}: start_link with broker at #{host}")
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def start_link() do
    host = Config.get_host()
    start_link({host, nil, []})
  end

  def init({_, conn, _} = state) do
    if !conn, do: send(self(), :connect)
    {:ok, state}
  end

  def handle_info(:connect, {host, _, listeners}) do
    case do_connect(host) do
      {:ok, connection} -> 
        Logger.info("#{__MODULE__}: connected to broker at #{host}")
        Process.monitor(connection.pid)
        publish_connection(connection, listeners)
        {:noreply, {host, connection, listeners}}
      error -> 
        Logger.warn("#{__MODULE__}: failed to connect to broker at #{host}. Error: #{IO.inspect(error)}. Retrying in: #{@reconnect_interval} ms")
        Process.send_after(self(), :connect, @reconnect_interval)
        {:noreply, {host, nil, listeners}}
    end
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, {host, _, _}) do
    Logger.warn "#{__MODULE__}: disconnected from #{host}. PID: #{inspect self()}"
    {:stop, {:connection_lost, reason}, {host, nil, []}}
  end

  defp publish_connection(connection, listeners) do
    Enum.each(listeners, fn(pid) ->
      if Process.alive?(pid), do: send(pid, {:connected, connection})
    end)
  end

  defp do_connect(host) do
    AMQP.Connection.open(host)
    rescue
    error -> {:error, error} 
  end
end
