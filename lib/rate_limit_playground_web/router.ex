defmodule RateLimitPlaygroundWeb.Router do
  use RateLimitPlaygroundWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RateLimitPlaygroundWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RateLimitPlaygroundWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/wait", PageController, :wait
    get "/delay", PageController, :wait
    get "/hang", PageController, :wait

    scope "/tesla" do
      scope "/hackney" do
        live "/max-connections", Tesla.Hackney.Live.MaxConnections
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", RateLimitPlaygroundWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:rate_limit_playground, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RateLimitPlaygroundWeb.Telemetry
    end
  end
end
