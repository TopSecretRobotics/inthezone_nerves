defprotocol Vex.MessageEncoder do
  @spec encode(term) :: {:ok, binary()} | :error
  def encode(term)
end