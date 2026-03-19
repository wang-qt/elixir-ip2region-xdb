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

  ##
    iex> Ip2regionXdb.lookup("1.80.153.93")
        {:ok, "中国|陕西省|西安市|电信|CN"}
    ex> Ip2regionXdb.lookup("127.0.0.1")
        {:ok, "Reserved|Reserved|Reserved|0|0"}
    iex> Ip2regionXdb.lookup("abcd")
        {:error, :invalid_ip}
    iex> Ip2regionXdb.lookup("1234")
         {:error, :invalid_ip}
    iex> Ip2regionXdb.lookup(1234)
        {:error, :invalid_ip}
  """
  def lookup(ip) when is_binary(ip) do
    case parse_ipv4(ip) do
      {:ok, parsed} -> do_lookup(parsed)
      {:error, :invalid_ip} -> {:error, :invalid_ip}
    end
  end

  def lookup(_ip)   do
    {:error, :invalid_ip}
  end

  # ip: {a,b,c,d}
  defp do_lookup({_a, _b, _c, _d} = parsed_ip) do
    :poolboy.transaction(Pool, &GenServer.call(&1, { :lookup, parsed_ip }))
  end
  defp do_lookup(_parsed_ip) do
    {:error, :invalid_ip}
  end

  defp parse_ipv4(ip) do
    with parts when length(parts) == 4 <- String.split(ip, ".", trim: true),
         {:ok, octets} <- parse_octets(parts) do
      case octets do
        [a, b, c, d] -> {:ok, {a, b, c, d}}
        _ -> {:error, :invalid_ip}
      end
    else
      _ -> {:error, :invalid_ip}
    end
  end

  defp parse_octets(parts) do
    Enum.reduce_while(parts, {:ok, []}, fn part, {:ok, acc} ->
      case Integer.parse(part) do
        {value, ""} when value in 0..255 ->
          {:cont, {:ok, [value | acc]}}

        _ ->
          {:halt, {:error, :invalid_ip}}
      end
    end)
    |> case do
      {:ok, octets} -> {:ok, Enum.reverse(octets)}
      {:error, :invalid_ip} -> {:error, :invalid_ip}
    end
  end



end
