defmodule Ip2regionXdb.Pool  do

  @size Application.compile_env(:ip2region_xdb, :pool)[:size] || 5
  @max_overflow Application.compile_env(:ip2region_xdb, :pool)[:max_overflow] || 10

  def child_spec do
    opts = [
      name:          { :local, __MODULE__ },
      worker_module: Ip2regionXdb.Server,
      size:          @size,
      max_overflow:  @max_overflow
    ]

    :poolboy.child_spec(__MODULE__, opts, [])
  end

end
