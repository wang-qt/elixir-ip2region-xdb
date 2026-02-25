defmodule Ip2regionXdb.Metadata  do
  @moduledoc """
  IP2Region XDB 元数据结构体, 包含了 XDB 文件的所有元数据信息.
  """

  defstruct [
    :filename,      # 文件名
    :file_len,      # 文件大小
    :buffer_len,    # 读取内存大小

    # 第一层 Header段
    :header,        # 头部段数据
    :header_len,    # 头部段字节数

    # 第二层 vector索引段
    :vector_index,        # VECTOR_INDEX 向量索引段
    :vector_index_len,    # VECTOR_INDEX 向量索引段字节数

    # 第三层 地域信息段
    :data,            # 地域信息段
    :data_len,      # 地域信息段字节数

    # 第四层 二分索引空间段
    :segment_index,         # SEGMENT_INDEX 二分索引段数据
    :segment_index_len,         # SEGMENT_INDEX 二分索引段数据 字节数
    :segment_index_first,   # SEGMENT_INDEX 二分索引段开始地址
    :segment_index_last,    # SEGMENT_INDEX 二分索引段结束地址
    :segment_index_count,   # SEGMENT_INDEX 二分索引段索引块个数
  ]

end
