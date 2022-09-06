defmodule Bertil.Adapters.Slack do
  use WebSockex
  alias Bertil.Messages
  alias Bertil.Time
  @bot_token Application.get_env(:bertil, :slack_bot_token)

  def start_link(_) do
    headers = [Authorization: "Bearer #{@bot_token}", Accept: "Application/json; Charset=utf-8"]

    %{"url" => socket_url} =
      HTTPoison.get!("https://slack.com/api/rtm.connect?pretty=1", headers)
      |> Map.get(:body)
      |> Jason.decode!()
      |> IO.inspect()

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

  def handle_frame({type, msg}, state) do
    IO.puts("Received Message with type: #{inspect(type)}")

    msg
    |> Jason.decode!()
    |> handle_message(state)
  end

  def encode_msg(msg), do: {:text, Jason.encode!(msg)}

  ### Handlers

  # Register handlers
  def handle_message(%{"text" => "register", "user" => user_id, "channel" => channel_id}, state)
      when is_map_key(state, user_id),
      do:
        {:reply,
         Messages.reply_text_message("Already Registered!") |> Map.put(:channel, channel_id),
         state}

  def handle_message(%{"text" => "register", "user" => user_id, "channel" => channel_id}, state) do
    new_state =
      Map.put_new(state, user_id, %{
        pid: Time.start_link([]) |> elem(1),
        channel_id: channel_id
      })

    msg = Messages.subscribe_to_presence_change(user_id)

    {:reply, encode_msg(msg), new_state}
  end

  # Command handlers
  # Check that user is registered
  def handle_message(%{"text" => _, "user" => user_id, "channel" => channel_id}, state)
      when not is_map_key(state, user_id),
      do:
        {:reply, Messages.reply_not_registered() |> Map.put(:channel, channel_id) |> encode_msg,
         state}

  def handle_message(%{"text" => "get", "user" => user_id}, state) do
    %{channel_id: channel_id, pid: pid} = Map.get(state, user_id)

    reply =
      Time.get_events(pid)
      |> Map.put(:channel, channel_id)
      |> encode_msg()

    {:reply, reply, state}
  end

  def handle_message(
        %{"presence" => presence, "type" => "presence_change", "user" => user_id},
        state
      ) do
    user = Map.get(state, user_id)

    reply =
      user
      |> Map.get(:pid)
      |> Bertil.Time.user_changed_status(presence)
      |> Map.put(:channel, user.channel_id)
      |> encode_msg()

    {:reply, reply, state}
  end

  def handle_message(msg, state) do
    IO.inspect(msg, label: "unhandled")
    {:ok, state}
  end
end
