defmodule Vex.Util do

  def ipv4() do
    with {:ok, ipv4} <- nerves_ipv4() do
      ipv4
    else _ ->
      << 127, 0, 0, 1 >>
    end
  end

  def nerves_ipv4() do
    try do
      with true <- Code.ensure_loaded?(Nerves.Network),
           %{ ipv4_address: ipv4_address } when is_binary(ipv4_address) <- :erlang.apply(Nerves.Network, :status, ["wlan0"]),
           strs = [_, _, _, _] <- String.split(ipv4_address, "."),
           ints = [_, _, _, _] <- (for s <- strs, into: [], do: String.to_integer(s)) do
        {:ok, :binary.list_to_bin(ints)}
      else error ->
        {:error, error}
      end
    catch class, reason ->
      {class, reason}
    end
  end

end