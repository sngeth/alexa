defmodule Alexa.Router do
  use Alexa.Web, :router

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

  scope "/", Alexa do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/api", Alexa do
    pipe_through :api
    post "/alexa", AlexaController, :teamsnap
  end
end
