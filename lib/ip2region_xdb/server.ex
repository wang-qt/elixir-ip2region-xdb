defmodule Ip2regionXdb.Server do
  use GenServer

  def start_link(default \\ %{}) do
    GenServer.start_link(__MODULE__, default)
  end


  def init(_) do
    {:ok, nil}
  end

  @doc """
  处理客户端的查询请求.
  调用 Ip2regionXdb.Database.lookup 方法查询 IP 对应的地域信息.
  ip: {a,b,c,d}
  """
  def handle_call({ :lookup, ip }, _, state) do
    { :reply, Ip2regionXdb.Database.lookup(ip), state }
  end
end
