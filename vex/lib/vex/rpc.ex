defmodule Vex.RPC do
  @timeout 5000

  def read(topic, subtopic, timeout \\ @timeout) do
    with {:ok, read_message} <- Vex.Message.Read.cast(nil, topic, subtopic),
         {:ok, frames} <- Vex.Local.Server.read(read_message, timeout) do
      case decode_read_frames(frames, []) do
        :raw ->
          {:raw, frames}
        other ->
          other
      end
    end
  end

  def write(topic, subtopic, value) do
    with {:ok, write_message} <- Vex.Message.Write.cast(nil, topic, subtopic, value) do
      Vex.Local.Server.vex_rpc_send(write_message)
    end
  end

  def subscribe(topic, subtopic, timeout \\ @timeout) do
    with {:ok, subscribe_message} <- Vex.Message.Subscribe.cast(nil, topic, subtopic) do
      Vex.Local.Server.subscribe(subscribe_message, timeout)
    end
  end

  def unsubscribe(subscription, timeout \\ @timeout) do
    Vex.Local.Server.unsubscribe(subscription, timeout)
  end

  @doc false
  defp decode_read_frames([{:data, data_frame}, :end], []) do
    with {:ok, data_message} <- Vex.Message.decode(data_frame) do
      {:ok, data_message}
    else _ ->
      :raw
    end
  end
  defp decode_read_frames([{:error, error_frame}, :end], []) do
    with {:ok, error_message} <- Vex.Message.decode(error_frame) do
      {:error, error_message}
    else _ ->
      :raw
    end
  end
  defp decode_read_frames([{:data, data_frame} | rest], acc) do
    with {:ok, data_message} <- Vex.Message.decode(data_frame) do
      decode_read_frames(rest, [data_message | acc])
    else _ ->
      :raw
    end
  end
  defp decode_read_frames([:end], acc) do
    {:ok, :lists.reverse(acc)}
  end
  defp decode_read_frames(_frames, _acc) do
    :raw
  end
end
