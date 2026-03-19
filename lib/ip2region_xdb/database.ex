defmodule Ip2regionXdb.Database  do
  @moduledoc """
  IP2Region XDB 数据库查询模块, 负责查询 IP 对应的地域信息.
  xdb文件格式描述: https://ip2region.net/doc/xdb/structure
  Database 模块负责查询，xdb数据在启动后，已经加载到 ets 和 agent 中.
  """

  alias Ip2regionXdb.Database.Storage
  alias Ip2regionXdb.Utils

  @xdb_vector_cols  256  # xdb 向量索引段 列数
  @vector_index_table  :vector_index_table
  @xdb_per_segment_index_size   14        # 每个segment索引项 字节数

  @xdb_header_size  256  # xdb 头部段 字节数
  # 所以整个vector索引段占据的空间为：256 × 256 × 8 = 524288 Bytes = 512 KiB
  @bytes_512k  524288

  @doc """
  查询 IP 对应的地域信息.
  ip: {a,b,c,d} 格式的 IP 地址元组
  返回 {:ok, "中国|陕西省|西安市|电信|CN"} 格式的地域信息字符串

  前提: 在ip2region_xdb app初始化时, 读取并解析 xdb 文件
  1. 把 VECTOR_INDEX 向量索引段，加载到ets中。
  2. 地域信息段，加载到 agent中
  3. SEGMENT_INDEX 二分索引段数据加载到 agent中

  查询流程:
  1. 根据 IP 地址的前 2 个字节，在向量索引段中查找对应的 VECTOR_INDEX 索引项，
     VECTOR_INDEX 索引项: {_index, s_ptr, e_ptr}, s_ptr和e_ptr 为文件绝对位置，可以极大的缩小查询范围。
  2. 根据上步获取到的 {_index, s_ptr, e_ptr}, 在二分索引段中， 通过二分法，找到ip所在的 二分索引项.
     二分索引项: {s_ip, e_ip, data_len, data_ptr}, 含义: 开始 IP, 	结束 IP, 	数据长度, 	数据指针.
     当目标int_ip 落在 s_ip, e_ip 之间时， 则该二分索引项为目标项.
  3. 根据找到的 data_len, data_ptr，从 地域信息段中对应位置( data_ptr),读取(data_len)字节数据
  4. 注意: agent中的 data和segment_index 都是纯数据，而 文件中的位置 都是相对文件开始(bof)的偏移量，
     所以要从 data和segment_index 读取数据时，都要 使用全局文件位置 - data 或  segment_index 的初始偏移。
     segment_index 的初始偏移为 meta.segment_index_first
     data的初始偏移为 @bytes_512k + @xdb_header_size
  """
  def lookup(ip) do
    # IO.inspect(ip, label: "要查询的 IP 地址")

    meta = Storage.get(:meta)    #  数据库描述
    # vector_index = Storage.get(:vector_index)    # 向量索引段
    data = Storage.get(:data)                    #  地域信息段
    segment_index = Storage.get(:segment_index)  #  二分索引段数据

    # IO.inspect(meta, label: "从 agent 中获取的 meta 元数据")

    # 1. 根据 IP 地址的前 2 个字节，在向量索引段中查找对应的 segment 索引项
    int_ip = Utils.ip_to_int(ip)
    # IO.inspect(int_ip, label: "IP 地址转换为整数")
    <<a::8, b::8, _rest::binary>> = <<int_ip::32>>

    vector_idx = a * @xdb_vector_cols + b
    [{_, s_ptr, e_ptr}] = :ets.lookup(@vector_index_table, vector_idx)

    segment_index_first = meta.segment_index_first

    # 2. 在二分索引段中， 通过二分法，找到ip所在的 二分索引项
    case search_ip(segment_index, segment_index_first, int_ip, s_ptr, e_ptr, 0, div(e_ptr - s_ptr, @xdb_per_segment_index_size ) ) do
      {:ok, {_s_ip, _e_ip, data_len, data_ptr}} ->
        # 3.从 地域信息段 中读取 数据项
        data_segment_term = read_data_segment_item(data, data_ptr, data_len)
        {:ok, data_segment_term}
      {:error, msg }   ->
        #  IO.puts("错误信息: #{msg}")
        {:error, msg}

    end
  end


  @doc """
  递归查询 IP 对应的地域信息.
  segment_index: 二分索引段数据, 从中读取索引项时，需要从  全局文件位置 - segment_index_first
  segment_index_first: 二分索引段 开始地址
  int_ip: 要查询的 IP 地址转换为整数
  s_ptr: 搜索范围开始地址，  在文件中的位置
  e_ptr: 搜索范围结束地址， 在文件中的位置
  low: 二分索引段  索引项 开始id，转换为地址 s_ptr + low * @xdb_per_segment_index_size
  high: 二分索引段 索引项 结束id，转换为地址 s_ptr + high * @xdb_per_segment_index_size
  成功返回 {:ok, {s_ip, e_ip, data_len, data_ptr} }，地域数据段的 项
  失败返回 {:error, msg}
  """
  def search_ip(segment_index, segment_index_first, int_ip, s_ptr, e_ptr, low, high) when low <= high do
    mid = div(low + high, 2)
    s_ptr2 = s_ptr + mid * @xdb_per_segment_index_size

    # 从中位 读取 二分索引项
    {s_ip, e_ip, data_len, data_ptr} = read_segment_index(segment_index, s_ptr2 - segment_index_first)


    if int_ip < s_ip do
      search_ip(segment_index, segment_index_first, int_ip, s_ptr, e_ptr, low, mid - 1)
    else
        if int_ip > e_ip do
           search_ip(segment_index, segment_index_first, int_ip, s_ptr, e_ptr, mid + 1, high)
        else
          # s_ip <= int_ip <= e_ip, 找到 ip 对应的 索引项, 从 地域信息段 读取 数据
          # data_segment_term = read_data_segment_item( data_ptr, data_len)
          # {:ok, data_segment_term}
          #  
          {:ok, {s_ip, e_ip, data_len, data_ptr} }
        end
    end
  end

  def search_ip(_segment_index, _segment_index_first, _int_ip, _s_ptr, _e_ptr, _low, _high)  do
    {:error, "IP 地址不在数据库的搜索范围中"}
  end

  @doc """
  从 地域信息段 中读取 数据项.
  data_ptr: 数据项在 地域信息段 中的偏移地址
  data_len: 数据项的字节数
  """
  def read_data_segment_item(data, data_ptr, data_len) do
    #  data = Storage.get(:data)                    #  地域信息段
    data_ptr = data_ptr - @bytes_512k - @xdb_header_size
     :binary.part(data, data_ptr, data_len)
  end

  #  从二分索引段 对应偏移，读取索引项 14
  # 开始 IP 	结束 IP 	数据长度 	数据指针
  # 4 Bytes 	4 Bytes 	2 Bytes 	4 Bytes
  def read_segment_index(segment_index, offset) do
    <<s_ip::little-size(32), e_ip::little-size(32), data_len::little-size(16), data_ptr::little-size(32)>> = :binary.part(segment_index, offset, @xdb_per_segment_index_size)
    {s_ip, e_ip, data_len, data_ptr}
  end

end
