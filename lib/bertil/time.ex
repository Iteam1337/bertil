defmodule Bertil.Time do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def user_changed_status(process, new_status) do
    GenServer.call(process, {:change_status, new_status})
  end

  def get_events(process) do
    date =
      DateTime.now!("Europe/Stockholm", Tzdata.TimeZoneDatabase)
      |> Calendar.strftime("%y-%m-%d")

    GenServer.call(process, {:get_events, date})
  end

  def handle_call({:change_status, new_status}, _, state) do
    datetime = DateTime.now!("Europe/Stockholm", Tzdata.TimeZoneDatabase)
    time_stamp = Calendar.strftime(datetime, "%I:%M")
    date = Calendar.strftime(datetime, "%y-%m-%d")

    first_today? =
      Map.get(state, date, []) |> Enum.all?(fn %{status: status} -> status == "away" end)

    new_event = %{status: new_status, time_stamp: time_stamp}
    upd_state = Map.update(state, date, [new_event], fn events -> [new_event | events] end)

    if first_today?,
      do: {:reply, "Good morning! Today you clocked in at #{time_stamp}", upd_state},
      else: {:reply, new_event, upd_state}
  end

  def handle_call({:get_events, date}, _, state), do: {:reply, Map.get(state, date), state}
end
