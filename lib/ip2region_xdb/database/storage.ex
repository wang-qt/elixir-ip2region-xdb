defmodule Ip2regionXdb.Database.Storage do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  获取存储中的值
  Ip2regionXdb.Database.Storage.get(:meta)
  """
  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key, nil))
  end

  def set(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

end
