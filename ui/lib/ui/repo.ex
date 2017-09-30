defmodule Ui.Repo do
  use Ecto.Repo, otp_app: :ui

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end

  # @doc """
  # Returns `{:ok, record}` or `:error` based on the queryable or id.
  # """
  # def fetch(module, queryable, opts \\ [])
  # def fetch(module, {queryable, id}, opts) when is_binary(id) or is_integer(id) do
  #   case get(queryable, id, opts) do
  #     nil ->
  #       :error
  #     record = %^module{} ->
  #       {:ok, record}
  #   end
  # end
  # def fetch(module, id, opts) when is_binary(id) or is_integer(id) do
  #   case get(module, id, opts) do
  #     nil ->
  #       :error
  #     record = %^module{} ->
  #       {:ok, record}
  #   end
  # end
  # def fetch(module, record = %module{}, opts) do
  #   {:ok, record}
  # end
  # def fetch(module, queryable, opts) do
  #   case one(queryable, opts) do
  #     nil ->
  #       :error
  #     record = %^module{} ->
  #       {:ok, record}
  #   end
  # end

  # @doc """
  # Raises an error if it can't find the record.
  # """
  # def fetch!(module, queryable, opts \\ [])
  # def fetch!(module, {queryable, id}, opts) when is_binary(id) or is_integer(id) do
  #   %^module{} = get!(queryable, id, opts)
  # end
  # def fetch!(module, id, opts) when is_binary(id) or is_integer(id) do
  #   %^module{} = get!(module, id, opts)
  # end
  # def fetch!(module, record = %module{}, _opts) do
  #   record
  # end
  # def fetch!(module, queryable, opts) do
  #   %^module{} = one!(queryable, opts)
  # end
end
