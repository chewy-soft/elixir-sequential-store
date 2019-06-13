defmodule SequentialStore do
  defstruct block_size: nil, store_size: nil, separator: nil, store_path: nil, loop: false

  def create(%__MODULE__{} = config, name) do
    if exists?(config, name) do
      {:error, :eexist}
    else
      SequentialStore.File.allocate_file(path(config, name), file_size(config))
    end
  end

  def open(config, name) do
    SequentialStore.File.open(path(config, name))
  end

  def close({:file_descriptor, _, _} = fp) do
    SequentialStore.File.close(fp)
  end

  def drop(config, name) do
    SequentialStore.File.delete_file(path(config, name))
  end

  def exists?(config, name) do
    File.exists?(path(config, name))
  end

  def read(config, name, index) do
    read(config, name, index, 1)
  end

  def read(config, name_or_fp, index, len)
      when is_number(index) and is_number(len) do
    path_or_fp = if is_binary(name_or_fp), do: path(config, name_or_fp), else: name_or_fp
    index = if config.loop, do: rem(index, config.store_size), else: index

    if config.loop and config.store_size < index + len do
      len_to_last = config.store_size - index
      len_from_start = index + len - config.store_size
      {:ok, pre} = do_read(config, path_or_fp, index, len_to_last)
      {:ok, post} = do_read(config, path_or_fp, 0, len_from_start)
      {:ok, pre <> config.separator <> post}
    else
      do_read(config, path_or_fp, index, len)
    end
  end

  defp do_read(config, path_or_fp, index, len) do
    sep_size = byte_size(config.separator)
    byte_length = (config.block_size + sep_size) * len - sep_size
    SequentialStore.File.read_file(path_or_fp, offset(config, index), byte_length)
  end

  def write(config, name_or_fp, index, binary)
      when is_number(index) and is_binary(binary) do
    path_or_fp = if is_binary(name_or_fp), do: path(config, name_or_fp), else: name_or_fp
    index = if config.loop, do: rem(index, config.store_size), else: index

    cond do
      is_binary(name_or_fp) and not exists?(config, name_or_fp) ->
        {:error, :file_notfound}

      index > config.store_size - 1 ->
        {:error, :store_exceeded}

      index < 0 ->
        {:error, :invalid_index}

      byte_size(binary) > config.block_size ->
        {:error, :toolong}

      true ->
        do_write(config, path_or_fp, index, binary)
    end
  end

  defp do_write(config, path_or_fp, index, block) do
    pad = String.duplicate(" ", config.block_size - byte_size(block))
    block = block <> pad
    block = block <> config.separator
    SequentialStore.File.write_file(path_or_fp, offset(config, index), block)
  end

  @doc """
  this func is dev usage only

  """
  def offset(config, index) do
    sep_size = config.separator |> byte_size()
    index * (config.block_size + sep_size)
  end

  def info(config, name) do
    SequentialStore.DevTool.info(path(config, name))
  end

  defp path(config, name) do
    Path.join([config.store_path, name])
  end

  defp file_size(%__MODULE__{} = config) do
    sep_size = config.separator |> byte_size()
    (config.block_size + sep_size) * config.store_size
  end
end
