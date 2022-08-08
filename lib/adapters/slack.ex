defmodule Bertil.Adapters.Slack do
  use WebSockex
  @bot_token Application.get_env(:bertil, :slack_bot_token)

  def start_link(_) do
    headers = [Authorization: "Bearer #{@bot_token}", Accept: "Application/json; Charset=utf-8"]

    socket_url =
      HTTPoison.get!("https://slack.com/api/rtm.connect?pretty=1", headers)
      |> Map.get(:body)
      |> Jason.decode!()
      |> Map.get("url")

    WebSockex.start_link(
      socket_url,
      __MODULE__,
      [""],
      name: __MODULE__
    )
  end

  def init(_) do
    {:ok, []}
  end

  def handle_frame({type, msg}, state) do
    IO.puts("Received Message with type: #{inspect(type)}")

    msg
    |> Jason.decode!()
    |> IO.inspect()
    |> handle_message(state)
  end

  def encode_msg(msg), do: {:text, Jason.encode!(msg)}

  def handle_message(%{"text" => "register", "user" => user_id}, state) do
    {:reply, encode_msg(%{type: "presence_sub", ids: [user_id]}), state}
  end

  def handle_message(msg, state) do
    IO.inspect(msg, label: "unhandled")
    {:ok, state}
  end
end
