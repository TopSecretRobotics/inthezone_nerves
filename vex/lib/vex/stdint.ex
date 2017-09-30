defmodule Vex.Stdint do

  @type int8_t() :: -0x80..0x7f
  @type int16_t() :: -0x8000..0x7fff
  @type int32_t() :: -0x80000000..0x7fffffff
  @type int64_t() :: -0x8000000000000000..0x7fffffffffffffff
  @type uint8_t() :: 0x00..0xff
  @type uint16_t() :: 0x0000..0xffff
  @type uint32_t() :: 0x00000000..0xffffffff
  @type uint64_t() :: 0x0000000000000000..0xffffffffffffffff

  defmacro __using__(_opts) do
    quote do
      import Vex.Stdint, only: :macros
    end
  end

  defmacro is_int8_t(n) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= -0x80 and unquote(n) <= 0x7f)
    end
  end

  defmacro is_int16_t(n) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= -0x8000 and unquote(n) <= 0x7fff)
    end
  end

  defmacro is_int32_t(n) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= -0x80000000 and unquote(n) <= 0x7fffffff)
    end
  end

  defmacro is_int64_t(n) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= -0x8000000000000000 and unquote(n) <= 0x7fffffffffffffff)
    end
  end

  defmacro is_uint8_t(n) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= 0 and unquote(n) <= 0xff)
    end
  end

  defmacro is_uint16_t(n) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= 0 and unquote(n) <= 0xffff)
    end
  end

  defmacro is_uint32_t(n) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= 0 and unquote(n) <= 0xffffffff)
    end
  end

  defmacro is_uint64_t(n) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= 0 and unquote(n) <= 0xffffffffffffffff)
    end
  end

end