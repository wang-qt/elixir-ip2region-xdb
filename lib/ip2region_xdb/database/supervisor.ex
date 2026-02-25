defmodule Ip2regionXdb.Database.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end


  @impl true
  def init(_opts) do
    database = Application.get_env(:ip2region_xdb, :database, [])

    children = [
      # Ip2regionXdb.Pool.child_spec,
      # {Ip2regionXdb.Server, []}
       Ip2regionXdb.Database.Storage,
       {Ip2regionXdb.Database.Loader, [database]}
    ]

    opts = [strategy: :one_for_one, name: Ip2regionXdb.Database.Supervisor]
    Supervisor.init(children, opts)
  end

end
