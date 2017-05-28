defmodule Amqplug.Config do
  def host() do
    case Application.fetch_env(:amqplug, :host) do
      {:ok, host} -> host 
      _ -> nil
    end
  end

  def routes() do
    case Application.fetch_env(:amqplug, :routes) do
      {:ok, routes} -> routes
      _ -> nil
    end
  end
end
