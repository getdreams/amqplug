defmodule Amqplug.Rabbit.Connection do
  use GenServer
  require Logger

  @reconnect_interval 5_000
  def start_link({_, _, _} = state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def start_link(pipelines) do
    host = Amqplug.Config.host()
    start_link({host, nil, pipelines})
  end

  def add_worker(pipeline) do
    GenServer.cast(__MODULE__, {:add_worker, pipeline})
  end

  def init({_, conn, _} = state) do
    if !conn, do: send(self(), :connect)
    {:ok, state}
  end

  def handle_info(:connect, {host, _, pipelines}) do
    case do_connect(host) do
      {:ok, connection} ->
        Logger.info("#{__MODULE__}: connected to broker")
        Process.monitor(connection.pid)
        setup_workers(connection, pipelines)
        {:noreply, {host, connection, pipelines}}

      _error ->
        Logger.warn(
          "#{__MODULE__}: failed to connect to broker. Retrying in: #{@reconnect_interval} ms"
        )

        Process.send_after(self(), :connect, @reconnect_interval)
        {:noreply, {host, nil, pipelines}}
    end
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, {_host, _, _} = state) do
    Logger.warn("#{__MODULE__}: disconnected from broker")
    {:stop, {:connection_lost, reason}, state}
  end

  defp setup_workers(connection, pipelines) do
    Enum.each(pipelines, fn pipeline ->
      {:ok, listener_pid} = Amqplug.Rabbit.Worker.start_link(connection, pipeline)
      Process.link(listener_pid)
    end)
  end

  defp do_connect(host) do
    AMQP.Connection.open(host)
  rescue
    error -> {:error, error}
  end

  def disconnect do
    GenServer.cast(__MODULE__, :disconnect)
  end

  def handle_cast(:disconnect, {_, connection, _} = _state) do
    AMQP.Connection.close(connection)
    GenServer.stop(self())
    # {:noreply, state}
  end

  def handle_cast({:add_worker, pipeline}, {_, connection, _} = state) do
    {:ok, listener_pid} = Amqplug.Rabbit.Worker.start_link(connection, pipeline)
    Process.link(listener_pid)
    {:noreply, state}
  end
end
