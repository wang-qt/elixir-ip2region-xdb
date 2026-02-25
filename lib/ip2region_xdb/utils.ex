defmodule Ip2regionXdb.Utils do


  @doc """
  将 IP 地址转换为整数.
  Ip2regionXdb.Utils.ip_to_int("192.168.1.1")
  Ip2regionXdb.Utils.ip_to_int( { 192, 168, 1, 1 })
  Ip2regionXdb.Utils.ip_to_int( 3232235777)
  """
  def ip_to_int(ip) when is_integer(ip), do: ip
  def ip_to_int({a,b,c,d} = _ip)  do
    << int_ip :: 32 >> = << a :: size(8), b :: size(8), c  :: size(8), d :: size(8) >>
    int_ip
  end
  def ip_to_int(ip) when is_binary(ip) do
    ip = String.to_charlist(ip)

    case :inet.parse_address(ip) do
      { :ok, parsed } -> ip_to_int(parsed)
      { :error, _ }   -> nil
    end
  end


end
