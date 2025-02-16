defmodule UpWeb.Router do
  use UpWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {UpWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", UpWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/stories/new", Live.Products.Dynamic.Story.New, :new
    live "/stories/:hash", Live.Products.Dynamic.Story, :show
    live "/stories/:hash/slideshow", Live.Products.Dynamic.Story.Slideshow, :slideshow
  end

  # Other scopes may use custom stacks.
  # scope "/api", UpWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:up, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: UpWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  if Application.compile_env(:up, :dev_routes) do
    import AshAdmin.Router

    scope "/admin" do
      pipe_through :browser
      import Oban.Web.Router

      ash_admin "/ash"
      oban_dashboard("/oban")
    end
  end
end
