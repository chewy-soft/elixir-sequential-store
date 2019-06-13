defmodule TestStore do
  use SequentialStore,
    block_size: 1000,
    store_size: 1000,
    separator: ",",
    store_path: "data/"
end

defmodule CreateBench do
  use Benchfella
  import TestStore

  @list Enum.to_list(1..1000)

  before_each_bench _ do
    @list
    |> Enum.map(&to_string/1)
    |> Enum.each(&drop/1)

    {:ok, nil}
  end

  bench "create store" do
    @list
    |> Enum.map(&to_string/1)
    |> Enum.each(&create/1)

    :ok
  end
end
