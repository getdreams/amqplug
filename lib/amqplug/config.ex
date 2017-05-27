defmodule Amqplug.Config do

  def get_host() do
    case Application.fetch_env(:amqplug, :connect_options) do
      {:ok, host} -> host 
      _ -> nil
    end
  end

  def get_queues() do
    case Application.fetch_env(:amqplug, :queues) do
      {:ok, queues} -> queues
      _ -> nil
    end
  end
end
