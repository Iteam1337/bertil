defmodule Bertil.Time do
  use GenServer
  alias Bertil.Messages

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def user_changed_status(process, new_status),
    do: GenServer.call(process, {:change_status, new_status})

  def get_events(process) do
    date =
      DateTime.now!("Europe/Stockholm", Tzdata.TimeZoneDatabase)
      |> Calendar.strftime("%y-%m-%d")

    GenServer.call(process, {:get_events, date})
  end

  ### Internal 

  def handle_call({:change_status, new_status}, _, state) when new_status in ["active", "away"] do
    datetime = DateTime.now!("Europe/Stockholm", Tzdata.TimeZoneDatabase)
    time_stamp = Calendar.strftime(datetime, "%H:%M")
    date = Calendar.strftime(datetime, "%y-%m-%d")

    first_today? =
      Map.get(state, date, []) |> Enum.all?(fn %{status: status} -> status == "away" end)

    new_event = %{status: new_status, time_stamp: time_stamp}
    upd_state = Map.update(state, date, [new_event], fn events -> [new_event | events] end)

    if first_today?,
      do: {:reply, {"first_active", time_stamp}, upd_state},
      else: {:reply, {new_status, time_stamp}, upd_state}
  end

  def handle_call({:get_events, date}, _, state), do: {:reply, Map.get(state, date), state}
end
