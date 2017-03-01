defmodule Alexa.AlexaController do
  use Alexa.Web, :controller

  def teamsnap(conn, _params) do
    json conn, %{
      "version" => "1.0",
      "response" => %{
        "outputSpeech" => %{
          "type" => "PlainText",
          "text" => "Hello World!",
        },
        "shouldEndSession" => true
      }
    }
  end
end
