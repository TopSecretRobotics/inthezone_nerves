defmodule UiWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :ui
  # use Absinthe.Phoenix.Endpoint

  @behaviour Absinthe.Subscription.Pubsub

  def publish_mutation(topic, mutation_result, subscribed_fields) do
    Absinthe.Phoenix.Endpoint.publish_mutation(@otp_app, __MODULE__, topic, mutation_result, subscribed_fields)
  end

  def publish_subscription(topic, data) do
    case data do
      %{ data: %{ "events" => [] } } ->
        # Ignore empty events
        :ok
      _ ->
        Absinthe.Phoenix.Endpoint.publish_subscription(@otp_app, __MODULE__, topic, data)
    end
  end

  socket "/socket", UiWeb.UserSocket

  plug :static_index

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :ui, gzip: false,
    only_matching: ~w(fonts img js statics app index.html robots.txt)
    # only: ~w(css fonts img js statics favicon.ico index.html robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: OJSON

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_ui_key",
    signing_salt: "MPR1RejT"

  plug UiWeb.Router

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end

  @doc false
  defp static_index(conn = %Plug.Conn{ path_info: [] }, _opts) do
    %{ conn | path_info: ["index.html"] }
  end
  defp static_index(conn, _opts) do
    conn
  end
end
