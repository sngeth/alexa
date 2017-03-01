defmodule Alexa.AlexaController do
  use Alexa.Web, :controller

  require Logger

  @api_url "https://api.teamsnap.com/v3"

  def teamsnap(conn, params) do
    Logger.info("received request: #{inspect params}")

    response =
      case get_in(params, ["context","System","user","accessToken"]) do
        nil ->
          login_response()
        access_token ->
          Logger.info("will use access token: #{inspect access_token}")
          case get_in(params, ["request", "intent", "name"]) do
            "Teams" ->
              teams_response(access_token)
            "Schedule" ->
              schedule_response(access_token, get_in(params, ["request", "intent", "slots"]))
            _ ->
              unknown_response()
          end
      end
    Logger.info("sending response: #{inspect response}")
    json conn, response
  end

  def login_response() do
    %{
        "version" => "1.0",
        "response" => %{
            "outputSpeech" => %{
              "type" => "PlainText",
              "text" => "You must log in via the mobile app.",
            },
            "card" => %{
              "type" => "LinkAccount",
            },
            "shouldEndSession" => true
        },
        "sessionAttributes" => %{}
    }
  end

  def unknown_response() do
    %{
        "version" => "1.0",
        "response" => %{
            "outputSpeech" => %{
              "type" => "PlainText",
              "text" => "I have no idea what you just said. Ask me again, but be more clear next time!",
            },
            "shouldEndSession" => true
        },
        "sessionAttributes" => %{}
    }
  end

  def schedule_response(access_token, %{"Date" => %{"name" => "Date", "value" => date}}) do
    %{
        "version" => "1.0",
        "response" => %{
            "outputSpeech" => %{
              "type" => "PlainText",
              "text" => "You would like me to tell you your schedule for #{inspect date}, wouldn't you?",
            },
            "shouldEndSession" => true
        },
        "sessionAttributes" => %{}
    }
  end

  def teams_response(access_token) do
    client = OAuth2.Client.new(token: access_token)
    path = "/me"
    resp = OAuth2.Client.get!(client, @api_url <> path).body
    items = get_in(resp, ["collection", "items"])
    Logger.info("links are #{inspect items}")
    active_team_urls =
      items |> Enum.map(fn item ->
        item["links"] |> Enum.filter_map(fn link ->
          case link do
            %{"rel" => "active_teams"} -> true
            _ -> false
          end
        end,
        fn link ->
          link["href"]
        end
        )
      end) |> List.flatten
    Logger.info("active team urls: #{inspect active_team_urls}")
    teams =
      active_team_urls |> Enum.map(fn url ->
              resp = OAuth2.Client.get!(client, url).body
              Logger.info("response for #{inspect path} is #{inspect resp}")
              resp["collection"]["items"]
              |> Enum.map(fn item ->
                item["data"] |> Enum.filter_map(fn map ->
                  case map do
                      %{"name" => "name"} -> true
                      _ -> false
                  end
                end,
                fn map ->
                  map["value"]
                end
                )
              end) |> List.flatten
    end) |> List.flatten
    %{
        "version" => "1.0",
        "response" => %{
            "outputSpeech" => %{
              "type" => "PlainText",
              "text" => "Your teams are: #{Enum.join(teams, ", ")}",
            },
            "shouldEndSession" => true
        },
        "sessionAttributes" => %{}
    }
  end
end
