defmodule SequentialStoreTest do
  use ExUnit.Case
  import SequentialStore
  doctest SequentialStore

  setup _context do
    drop(config(), "test")
    create(config(), "test")
    create(config_loop(), "loop")
    :ok
  end

  defp config do
    %SequentialStore{
      block_size: 1000,
      store_size: 1000,
      separator: ",",
      store_path: "data/"
    }
  end

  defp config_loop do
    %SequentialStore{
      block_size: 1000,
      store_size: 100,
      separator: ",",
      store_path: "data/",
      loop: true
    }
  end

  test "create store" do
    drop(config(), "test")
    assert :ok = create(config(), "test")
  end

  test "delete store" do
    assert :ok = drop(config(), "test")
  end

  test "inspect store" do
    assert info(config(), "test")
           |> Map.get(:file_frag) == 1
  end

  test "invalid length block" do
    assert {:error, :toolong} = write(config(), "test", 0, String.duplicate("A", 2000))
  end

  test "invalid index write" do
    assert {:error, :store_exceeded} = write(config(), "test", 2000, String.duplicate("A", 1000))
  end

  test "write" do
    assert :ok = write(config(), "test", 0, String.duplicate("ABC", 100))
  end

  test "read single block" do
    :ok = write(config(), "test", 0, String.duplicate("ABC", 10))
    {:ok, binary} = read(config(), "test", 0)
    assert binary == String.duplicate("ABC", 10) <> String.duplicate("\s", 970)
  end

  test "read multi blocks" do
    :ok = write(config(), "test", 0, String.duplicate("ABC", 10))
    :ok = write(config(), "test", 1, String.duplicate("ABC", 10))
    {:ok, binary} = read(config(), "test", 0, 2)

    assert binary ==
             String.duplicate("ABC", 10) <>
               String.duplicate("\s", 970) <>
               "," <> String.duplicate("ABC", 10) <> String.duplicate("\s", 970)
  end

  test "write json" do
    json = "あああ" |> Poison.encode!()
    json2 = "いいい" |> Poison.encode!()
    json3 = "ううううう" |> Poison.encode!()
    write(config(), "test", 0, json)
    write(config(), "test", 1, json2)
    write(config(), "test", 2, json3)
    write(config(), "test", 1, json3)

    {:ok, binary} = read(config(), "test", 0, 3)

    assert ["あああ", "ううううう", "ううううう"] =
             ("[" <> binary <> "]")
             |> Poison.decode!()
  end

  test "loop" do
    0..130
    |> Enum.each(fn i ->
      message = "message:" <> to_string(i)
      write(config_loop(), "loop", i, message |> Poison.encode!())
    end)

    {:ok, binary} = read(config_loop(), "loop", 0, 10)

    messages =
      100..109
      |> Enum.map(fn i ->
        "message:" <> to_string(i)
      end)

    assert messages ==
             ("[" <> binary <> "]")
             |> Poison.decode!()
  end
end
