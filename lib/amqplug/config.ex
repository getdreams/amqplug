defmodule Amqplug.Config do

  def get_host() do
    case Application.fetch_env(:amqplug, :connect_options) do
      {:ok, host} -> host 
      _ -> nil
    end
  end
end
