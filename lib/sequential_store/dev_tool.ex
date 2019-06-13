defmodule SequentialStore.DevTool do
  def info(path) do
    with {:ok, frag} <- filefrag(path) do
      %{
        file_frag: (frag |> length()) - 5
      }
    end
  end

  def filefrag(path) do
    case System.cmd("filefrag", ["-v", path]) do
      {result, 0} ->
        {:ok,
         result
         |> String.split("\n")}

      {error, 1} ->
        {:error, error}
    end
  end
end
