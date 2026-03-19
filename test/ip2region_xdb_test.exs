defmodule Ip2regionXdbTest do
  use ExUnit.Case, async: false

  alias Ip2regionXdb.Database
  alias Ip2regionXdb.Database.Loader

  describe "lookup/1" do
    test "returns location data for a known public ip" do
      assert {:ok, location} = Ip2regionXdb.lookup("1.80.153.93")
      assert location == "中国|陕西省|西安市|电信|CN"
    end

    test "returns reserved region for loopback ip" do
      assert {:ok, location} = Ip2regionXdb.lookup("127.0.0.1")
      assert location == "Reserved|Reserved|Reserved|0|0"
    end

    test "rejects invalid ip strings" do
      assert {:error, :invalid_ip} = Ip2regionXdb.lookup("abcd")
      assert {:error, :invalid_ip} = Ip2regionXdb.lookup("1234")
      assert {:error, :invalid_ip} = Ip2regionXdb.lookup("999.1.1.1")
    end

    test "rejects non-binary inputs" do
      assert {:error, :invalid_ip} = Ip2regionXdb.lookup(1234)
      assert {:error, :invalid_ip} = Ip2regionXdb.lookup({127, 0, 0})
    end
  end

  describe "Database.search_ip/7" do
    test "returns not found when search range is empty" do
      assert {:error, "IP 地址不在数据库的搜索范围中"} =
               Database.search_ip(<<>>, 0, 0, 0, 0, 1, 0)
    end
  end

  describe "Database.Loader" do
    test "loads vector index data into ets during application startup" do
      assert [{0, s_ptr, e_ptr}] = Loader.get_vector_index(0)
      assert is_integer(s_ptr)
      assert is_integer(e_ptr)
      assert s_ptr <= e_ptr
    end
  end
end
