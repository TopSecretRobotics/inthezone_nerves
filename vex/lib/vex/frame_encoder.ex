defprotocol Vex.FrameEncoder do
  @spec encode(term) :: binary()
  def encode(term)
end