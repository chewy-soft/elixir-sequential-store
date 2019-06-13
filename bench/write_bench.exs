defmodule WriteTestStore do
  use SequentialStore,
    block_size: 1000,
    store_size: 1000,
    separator: ",",
    store_path: "data/"
end

defmodule WriteBench do
  use Benchfella
  import WriteTestStore

  @list Enum.to_list(0..999)
  @message "message"

  before_each_bench _ do
    @list
    |> Enum.map(&to_string/1)
    |> Enum.map(&create/1)

    fps =
      @list
      |> Enum.map(&to_string/1)
      |> Enum.map(&open/1)
      |> Enum.map(fn {:ok, fp} -> fp end)

    {:ok, fps}
  end

  after_each_bench fps do
    fps
    |> Enum.each(&close/1)
    :ok
  end

  bench "write 1 message to 1000 store" do
    @list
    |> Enum.map(&to_string/1)
    |> Enum.each(fn name -> write(name, 0, @message) end)

    :ok
  end

  bench "write 1 message to 1000 store with fp" do
    bench_context
    |> Enum.each(fn fp -> write(fp, 0, @message) end)

    :ok
  end


  bench "write 1000 messages to 1 store" do
    @list
    |> Enum.each(fn index -> write("0", index, @message) end)
  end

  bench "write 1000 mesages to 1 store with fp" do
    name = "0"
    {:ok, fp} = open(name)

    @list
    |> Enum.each(fn index -> write(fp, index, @message) end)

    close(fp)
  end

  bench "write 1 messages to random 1 store 1000 times" do
    for index <- @list do
      store = :rand.uniform(999) |> to_string
      write(store, index, @message)
    end
  end
end
