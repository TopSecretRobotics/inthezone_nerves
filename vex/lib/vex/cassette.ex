defmodule Vex.Cassette do

  def close(id) do
    Vex.RPC.write(:cassette, :close, id)
  end

  def count() do
    with {:ok, %Vex.Message.Data.Cassette.Count{ value: value }} <- Vex.RPC.read(:cassette, :count) do
      {:ok, value}
    else _ ->
      :error
    end
  end

  def free() do
    with {:ok, %Vex.Message.Data.Cassette.Free{ value: value }} <- Vex.RPC.read(:cassette, :free) do
      {:ok, value}
    else _ ->
      :error
    end
  end

  def max() do
    with {:ok, %Vex.Message.Data.Cassette.Max{ value: value }} <- Vex.RPC.read(:cassette, :max) do
      {:ok, value}
    else _ ->
      :error
    end
  end

  def open(id) do
    with :ok <- Vex.RPC.write(:cassette, :open, id),
         {:ok, %Vex.Message.Data.Cassette.Open{ value: {^id, 0} }} <- Vex.RPC.read(:cassette, :open) do
      {:ok, id}
    else _ ->
      :error
    end
  end

  def read(id) do
    Vex.RPC.read(:cassette, id)
  end

  def write(id, data) do
    with {:ok, ^id} <- open(id) do
      do_write(data, 0, id)
    end
  end

  defp do_write(<< c, data :: binary() >>, pos, id) do
    with :ok <- Vex.RPC.write(:cassette, :write, {id, << c >>}) do
      :ok = :timer.sleep(2)
      do_write(data, pos + 1, id)
    end
  end
  defp do_write(<<>>, pos, id) do
    :ok = :timer.sleep(2)
    case Vex.RPC.read(:cassette, :open) do
      {:ok, %Vex.Message.Data.Cassette.Open{ value: {^id, ^pos} }} ->
        close(id)
      {:ok, %Vex.Message.Data.Cassette.Open{ value: {^id, position} }} ->
        _ = close(id)
        {:error, {:badwrite, position}}
      {:ok, message} ->
        {:error, {:badfile, message}}
      error ->
        error
    end
  end

end