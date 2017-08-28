defmodule Amqplug.Debug do
  require Logger
  use AMQP

  def new_debug_channel do
    case Connection.open(Amqplug.Config.host) do
      {:ok, conn} ->
        case Channel.open(conn) do
          {:ok, %AMQP.Channel{} = chan} -> {conn, chan}
          err -> err
        end
      err -> err
    end
  end

  def close_channel_and_connection({conn, chan}) do
    Channel.close(chan)
    Connection.close(conn)
  end

  def publish({_con, channel}, {routing_key, payload}) do
    exchange = "world"
    Logger.debug("#{__MODULE__} publishing: #{exchange} #{routing_key}, #{payload}")
    Basic.publish(channel, exchange, routing_key, payload)
  end

  def publish({_con, channel}, {routing_key, payload, opts}) do
    exchange = "world"
    Logger.debug("#{__MODULE__} publishing: #{exchange} #{routing_key}, #{payload}")
    Basic.publish(channel, exchange, routing_key, payload, opts)
  end
end
