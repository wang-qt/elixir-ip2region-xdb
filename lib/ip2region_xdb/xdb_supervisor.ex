defmodule Ip2regionXdb.XdbSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end


  @impl true
  def init(_opts) do
    children = [
      Ip2regionXdb.Pool.child_spec,
      Ip2regionXdb.Database.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Ip2regionXdb.XdbSupervisor]
    Supervisor.init(children, opts)
  end

end
