import Config

ip2region_xdb = [ __DIR__, "../priv/data/ip2region_v4.xdb" ] |> Path.join() |> Path.expand()
config :ip2region_xdb,
       database: ip2region_xdb,
       pool: [ size: 5, max_overflow: 10 ]
