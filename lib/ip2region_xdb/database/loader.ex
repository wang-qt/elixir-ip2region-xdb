defmodule Ip2regionXdb.Database.Loader do
  @moduledoc """
  IP2Region XDB 数据库加载器, 负责加载 XDB 文件到内存中.
  保存在   :meta, :vector_index, :data , :segment_index  key下
  :meta 包含了 XDB 文件的所有元数据信息.
  :vector_index 包含了 XDB 文件的向量索引段数据.
  :data 包含了 XDB 文件的地域信息段数据.
  :segment_index 包含了 XDB 文件的二分索引段数据.
  """

  use GenServer
  require Logger

  alias  Ip2regionXdb.Database.Storage

  @xdb_header_size  256  # xdb 头部段 字节数
  # @xdb_vector_cols  256  # xdb 向量索引段 列数

  # 所以整个vector索引段占据的空间为：256 × 256 × 8 = 524288 Bytes = 512 KiB
  @bytes_512k  524288
  @xdb_vector_index_size    @bytes_512k  # xdb 向量索引段 总字节数

  @xdb_per_segment_index_size   14        # 每个segment索引项 字节数

  @vector_index_table  :vector_index_table


  def start_link(filename \\ []) do
    GenServer.start_link(__MODULE__, filename, name: __MODULE__)
  end

  @impl true
  def init(filename) do
    # 创建 ets 表
    :ets.new(@vector_index_table, [:named_table, :set, :public])

    # 加载数据库文件到内存
    case load_database(filename) do
      :ok ->
        {:ok, %{database: filename}}

      {:stop, reason} ->
        {:stop, reason}
    end
  end


  defp load_database(database) do
    case File.regular?(database) do
      # false -> { :error, "File '#{database}' does not exists!" }
      false -> { :stop, "File '#{database}' does not exists!" }
      true ->
        database
        |> read_database()
        |> save_data()
    end
  end

  @doc """
  读取 XDB 文件数据到内存中, 把文件 拆分为 vector_index, data, segment_index 三部分.
  1. 把 VECTOR_INDEX 向量索引段，加载到ets中。
  2. 把 地域信息段data，和 二分索引段segment_index 返回，最终加载到 agent中
  """
  def read_database(filename) do

    raw_data = File.read!(filename)

    <<header     :: binary-size(@xdb_header_size),  # 头部段数据
      vector_index      :: binary-size(@xdb_vector_index_size), # vector索引段数据
      rest              :: binary >> = raw_data

    # 解析header段， segment_index_first ， segment_index_last
    <<_header      :: binary-size(8),
      segment_index_first :: little-size(32), # SEGMENT_INDEX 二分索引段开始地址
      segment_index_last  :: little-size(32), # SEGMENT_INDEX 二分索引段结束地址
      _header_rest        :: binary >> = header

      # 地域信息段   数据长度为 segment_index_first - @bytes_512k - 256
      data_len = segment_index_first -  @bytes_512k - 256

    <<data     :: binary-size(data_len),  # 地域信息段数据
    segment_index  :: binary >> = rest


    {:ok, stat} = File.stat(filename)

    meta = %Ip2regionXdb.Metadata{
        filename: filename,
        file_len: stat.size,
        buffer_len: byte_size(raw_data),
        header_len: byte_size(header),
        # 向量索引段
        vector_index_len: byte_size(vector_index),
        # 数据段
        data_len: byte_size(data),
        # 二分索引段
        segment_index_len: byte_size(segment_index),
        segment_index_first: segment_index_first,
        segment_index_last: segment_index_last,
        segment_index_count: div(segment_index_last - segment_index_first, @xdb_per_segment_index_size),
      }

    # 把 向量索引段 拆分 保存到 ets 表中, 共 65536 个索引项
    load_vector_index_aux(vector_index, 0)



      # 返回 meta, 数据区，索引区
    { meta, vector_index, data , segment_index}

  end


  @doc """
  递归加载向量索引段数据到 ets 表中
  """
  def load_vector_index_aux(<<>> = _vector_index, _index), do: :ok

  def load_vector_index_aux(<<s_ptr::little-size(32), e_ptr::little-size(32), rest::binary>>, index) do
    term =  {index, s_ptr, e_ptr}

    :ets.insert(@vector_index_table, term)

    load_vector_index_aux(rest, index + 1)
  end


  @doc """
  获取向量索引项
  Ip2regionXdb.Database.Loader.get_vector_index(0)
  [{0, 3297468, 3297482}]
  """
  def get_vector_index(index) do
    :ets.lookup(@vector_index_table, index)
  end



  defp save_data({ meta, vector_index, data , segment_index}) do
    Storage.set(:meta, meta)
    Storage.set(:vector_index, vector_index)
    Storage.set(:data, data)
    Storage.set(:segment_index, segment_index)
    :ok
  end

end
