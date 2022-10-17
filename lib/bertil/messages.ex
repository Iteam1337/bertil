defmodule Bertil.Messages do
  def reply_text_message(msg),
    do: %{id: 1_234_141, type: "message", text: msg}

  def reply_not_registered,
    do: %{id: 1_234_141, type: "message", text: "Register first!"}

  def presence_change({"away", _time_stamp}),
    do: %{id: 12314, type: "message", text: "See you soon!"}

  def presence_change({"active", _time_stamp}),
    do: %{id: 12314, type: "message", text: "Welcome back!"}

  def presence_change({"first_active", time_stamp}),
    do: %{id: 12314, type: "message", text: "Good morning! Today you clocked in at #{time_stamp}"}

  def list_events(events) do
    time = List.first(events) |> Map.get(:time_stamp)

    hours =
      DateTime.now!("Europe/Stockholm", Tzdata.TimeZoneDatabase)
      |> DateTime.to_time()
      |> Time.diff(Time.from_iso8601(time <> ":00") |> elem(1))
      |> div(360)

    msg =
      events
      |> Enum.reverse()
      |> Enum.drop_while(fn %{status: status} -> status === "away" end)
      |> Enum.chunk_every(2)
      |> IO.inspect(label: "Label")
      |> Enum.reduce(
        "You've worked #{hours} hours today. Here are the records for today \n",
        fn
          [%{status: "active", time_stamp: ts_start}, %{status: "away", time_stamp: ts_end}],
          acc ->
            "#{acc}#{ts_start}-#{ts_end} \n"

          [%{status: "active", time_stamp: ts_start}], acc ->
            "#{acc}#{ts_start}-\n"
        end
      )

    %{
      id: 1_234_414,
      type: "message",
      text: msg
    }
  end

  def subscribe_to_presence_change(user_id), do: %{type: "presence_sub", ids: [user_id]}
end
