defmodule Ip2regionXdb do
  @moduledoc """
  Documentation for `Ip2regionXdb`.


  """
  alias Ip2regionXdb.Pool

  @doc """
  查找 IP 对应的地域信息.
  从 pool中获取一个 worker 进程, 并调用其 lookup 方法.
  对应模块 Ip2regionXdb.Server 的 handle_call 方法.


  Ip2regionXdb.lookup("1.80.167.78")
  Ip2regionXdb.lookup("123.139.40.31")
  Ip2regionXdb.lookup("59.61.92.138")
  Ip2regionXdb.lookup("183.250.89.176")
  Ip2regionXdb.lookup("1.80.153.93")
  {:ok, "中国|陕西省|西安市|电信|CN"}
  添加注释，测试vscode git
  """
  def lookup(ip) when is_binary(ip) do
    ip = String.to_charlist(ip)

    case :inet.parse_address(ip) do
      { :ok, parsed } -> lookup(parsed)
      { :error, _ }   -> nil
    end
  end

  # ip: {a,b,c,d}
  def lookup(ip) do
    :poolboy.transaction(Pool, &GenServer.call(&1, { :lookup, ip }))
  end



end
