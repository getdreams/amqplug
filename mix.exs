defmodule Amqplug.Mixfile do
  use Mix.Project

  @version "0.1.0-dev"

  def project do
    [
      app: :amqplug,
      name: "Amqplug",
      description:
        "A specification and conveniences for composable " <>
          "modules for rabbitmq micro services. Inspired by Plug",
      version: @version,
      elixir: ">= 1.6.0",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :amqp],
      mod: {Amqplug, []}
    ]
  end

  defp deps do
    [
      {:amqp, "~> 0.2.1"},
      {:poison, "~> 3.1"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["Apache 2"],
      maintainers: ["Kiril Videlov"],
      links: %{"GitHub" => "https://github.com/krlvi/amqplug"}
    }
  end
end
