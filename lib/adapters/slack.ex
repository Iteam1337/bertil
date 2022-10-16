defmodule Bertil.Adapters.Slack do
  use WebSockex
  alias Bertil.Messages
  alias Bertil.Time

  def start_link(_) do
    bot_token = Application.get_env(:bertil, :slack_bot_token)

    headers = [Authorization: "Bearer #{bot_token}", Accept: "Application/json; Charset=utf-8"]

    %{"url" => socket_url} =
      HTTPoison.get!("https://slack.com/api/rtm.connect?pretty=1", headers)
      |> Map.get(:body)
      |> Jason.decode!()

    WebSockex.start_link(
      socket_url,
      __MODULE__,
      %{},
      name: __MODULE__
    )
  end

  def init(_) do
    {:ok, %{}}
  end

  # Endpoint for all messages from Slack
  def handle_frame({type, msg}, state) do
    IO.puts("Received Message with type: #{inspect(type)}")

    msg
    |> Jason.decode!()
    |> handle_message(state)
  end

  ### Handlers

  # Register handlers
  def handle_message(%{"text" => "register", "user" => user_id, "channel" => channel_id}, state)
      when is_map_key(state, user_id),
      do: reply(Messages.reply_text_message("Already Registered!"), state, channel_id)

  def handle_message(%{"text" => "register", "user" => user_id, "channel" => channel_id}, state) do
    new_state =
      Map.put_new(state, user_id, %{
        pid: Time.start_link([]) |> elem(1),
        channel_id: channel_id
      })

    IO.puts("Registering #{user_id}")

    user_id
    |> Messages.subscribe_to_presence_change()
    |> reply(new_state, channel_id)
  end

  # Command handlers
  # Check that user is registered
  def handle_message(%{"text" => _, "user" => user_id, "channel" => channel_id}, state)
      when not is_map_key(state, user_id),
      do: reply(Messages.reply_not_registered(), state, channel_id)

  def handle_message(%{"text" => "get", "user" => user_id}, state) do
    %{pid: pid, channel_id: channel_id} = Map.get(state, user_id)

    Time.get_events(pid)
    |> IO.inspect()
    |> Messages.list_events()
    |> reply(state, channel_id)
  end

  def handle_message(
        %{"presence" => presence, "type" => "presence_change", "user" => user_id},
        state
      ) do
    %{pid: pid, channel_id: channel_id} = Map.get(state, user_id)

    Bertil.Time.user_changed_status(pid, presence)
    |> Messages.presence_change()
    |> reply(state, channel_id)
  end

  # Formal Slack-Server init message
  def handle_message(%{"type" => "hello", "start" => true}, state) do
    IO.puts("Server connected to Slack!")
    {:ok, state}
  end

  # "Message sent successfully" message from Slack
  def handle_message(%{"ok" => true}, state) do
    {:ok, state}
  end

  def handle_message(msg, state) do
    IO.inspect(msg, label: "unhandled")
    {:ok, state}
  end

  def encode_msg(msg), do: {:text, Jason.encode!(msg)}

  defp reply(message, state, channel_id) do
    payload = message |> Map.put(:channel, channel_id) |> encode_msg
    {:reply, payload, state}
  end
end
