defmodule SequentialStore.File do
  def open(path) when is_binary(path) do
    File.open!(path, [:raw, :read, :write, :binary])
  end

  def close({:file_descriptor, _, _} = fp) do
    File.close(fp)
  end

  def allocate_file(path, size) when is_number(size) do
    case System.cmd("fallocate", [path, "-l", size |> to_string]) do
      {_, 0} -> :ok
      {_, 1} -> {:error, :cmd}
    end
  end

  def write_file(path, offset, binary)
      when is_binary(path) and is_number(offset) and is_binary(binary) do
    with {:ok, fp} <- File.open(path, [:raw, :read, :write, :binary]) do
      result = write_file(fp, offset, binary)
      File.close(fp)
      result
    end
  end

  def write_file({:file_descriptor, _, _} = fp, offset, binary)
      when is_number(offset) and is_binary(binary) do
    :file.pwrite(fp, offset, binary)
  end

  def read_file(path, offset, len)
      when is_binary(path) and is_number(offset) and is_number(len) do
    with {:ok, fp} <- File.open(path, [:raw, :read, :write, :binary]) do
      result = read_file(fp, offset, len)
      File.close(fp)
      result
    end
  end

  def read_file({:file_descriptor, _, _} = fp, offset, len)
      when is_number(offset) and is_number(len) do
    :file.pread(fp, offset, len)
  end

  def delete_file(path) when is_binary(path) do
    File.rm(path)
  end
end
