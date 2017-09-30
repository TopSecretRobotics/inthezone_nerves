defmodule UiWeb.Router do
  use UiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", UiWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/" do
    forward "/graphql", Absinthe.Plug, [
      schema: UiGraph.Schema,
      json_codec: OJSON
    ]
    forward "/graphiql", Absinthe.Plug.GraphiQL, [
      schema: UiGraph.Schema,
      socket: UiWeb.UserSocket,
      interface: :simple,
      json_codec: OJSON
    ]
  end

  # Other scopes may use custom stacks.
  # scope "/api", UiWeb do
  #   pipe_through :api
  # end
end
