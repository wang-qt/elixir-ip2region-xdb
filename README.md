# Ip2regionXdb

[ip2region](https://github.com/lionsoul2014/ip2region) - 是一个离线IP地址定位库和IP定位数据管理框架，10微秒级别的查询效率，提供了众多主流编程语言的 xdb 数据生成和查询客户端实现。

Ip2regionXdb - 是ip2region v3.0 elixir语言客户端。支持 xdb文件格式，[xdb文件格式](https://ip2region.net/doc/xdb/structure). 使用 poolboy进程池，适用于高并发场景。

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ip2region_xdb` to your list of dependencies in `mix.exs`:

```elixir
def application do
  [applications: [:ip2region_xdb]]
end

def deps do
  [
    {:ip2region_xdb, github: "wang-qt/elixir-ip2region-xdb"},
  ]
end
```

 

## Configuration

Add the path of the ip2region database to your project's configuration:

```elixir
ip2region_xdb = [ __DIR__, "../priv/data/ip2region_v4.xdb" ] |> Path.join() |> Path.expand()
config :ip2region_xdb,
       database: ip2region_xdb,
       pool: [ size: 5, max_overflow: 10 ]
```

安装本包，从 deps下本包安装位置找到 ip2region_v4.xdb，拷贝到项目的 priv/data目录下。

如果要获取最新的数据文件，使用下面命令克隆 ip2region项目， 从中找到  ip2region_v4.xdb，并拷贝到项目的 priv/data目录下。

```shell
git clone https://github.com/lionsoul2014/ip2region.git
```



## Usage

```elixir
 Ip2regionXdb.lookup("1.80.167.78")
 ~ {:ok, "中国|陕西省|西安市|电信|CN"}
```





## Benchmarking

```elixir
 :timer.tc(fn -> Ip2regionXdb.lookup("1.80.167.78") end )
~ {343, {:ok, "中国|陕西省|西安市|电信|CN"}}
```

