defmodule NewsbloatWeb.Router do
  use NewsbloatWeb, :router

  alias NewsbloatWeb.Plugs.ReturnToQueryParamToAssigns

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NewsbloatWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug ReturnToQueryParamToAssigns
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NewsbloatWeb do
    pipe_through :browser

    live "/", PageLive, :index

    live "/feeds", FeedLive.Index, :index
    live "/feeds/new", FeedLive.Index, :new
    live "/feeds/:id/edit", FeedLive.Index, :edit

    live "/feeds/:id", FeedLive.Show, :show
    live "/feeds/:id/:item_id", FeedLive.Show, :show
    live "/feeds/:id/new", FeedLive.Show, :new
    live "/feeds/:id/show/edit", FeedLive.Show, :edit

  end

  # Other scopes may use custom stacks.
  # scope "/api", NewsbloatWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: NewsbloatWeb.Telemetry
    end
  end
end
