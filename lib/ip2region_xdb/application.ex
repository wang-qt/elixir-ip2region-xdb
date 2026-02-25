defmodule Ip2regionXdb.Application do

  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Ip2regionXdb.Application start")

    children = [
      # {Ip2regionXdb.Server, []}
      Ip2regionXdb.XdbSupervisor
    ]

    opts = [strategy: :one_for_one, name: Ip2regionXdb.Supervisor]
    Supervisor.start_link(children, opts)
  end


end
