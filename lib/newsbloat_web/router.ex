defmodule NewsbloatWeb.Router do
  use NewsbloatWeb, :router

  alias NewsbloatWeb.Plugs.UITheme
  import NewsbloatWeb.Plugs.BasicAuth, only: [auth: 2]
  alias NewsbloatWeb.Plugs.PutLanguage
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NewsbloatWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :auth
    plug UITheme
    plug PutLanguage
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NewsbloatWeb do
    pipe_through :browser

    # live "/", PageLive, :index
    # NOTE: See the scope
    get "/", Plugs.Redirecter, to: "/feeds"

    live "/feeds", FeedLive.Index, :index
    live "/feeds/new", FeedLive.Index, :new
    live "/feeds/:id/edit", FeedLive.Index, :edit

    live "/feeds/:id", FeedLive.Show, :show
    live "/feeds/:id/new", FeedLive.Show, :new
    live "/feeds/:id/show/edit", FeedLive.Show, :edit
    live "/feeds/:id/items/:item_id", FeedLive.ShowItem, :show
    live "/feeds/:id/:item_id", FeedLive.Show, :show

    live "/search", SearchLive.Index, :index

    # NOTE: make sure this is always under auth
    live_dashboard "/dashboard", metrics: NewsbloatWeb.Telemetry
  end

  # Other scopes may use custom stacks.
  # scope "/api", NewsbloatWeb do
  #   pipe_through :api
  # end
end
