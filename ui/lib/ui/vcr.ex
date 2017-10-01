defmodule Ui.VCR do

  def play(cassette_id) do
    Ui.VCR.Supervisor.play(cassette_id)
  end

  def record(cassette_id) do
    Ui.VCR.Supervisor.record(cassette_id)
  end

  def duration(cassette_id) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    case cassette do
      %Ui.Data.Cassette{ start_at: start_at, stop_at: stop_at } when start_at != nil and stop_at != nil ->
        {:ok, NaiveDateTime.diff(stop_at, start_at, :millisecond)}
      _ ->
        :error
    end
  end

  def runtime(cassette_id) do
    with {:ok, events} <- events(cassette_id) do
      cassette_runtime(events, 0)
    end
  end

  def stop(cassette_id) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    case cassette do
      %{ pid: pid } when is_binary(pid) ->
        pid =
          try do
            :erlang.binary_to_term(pid)
          catch _, _ ->
            nil
          end
        if is_pid(pid) and :erlang.is_process_alive(pid) do
          if is_nil(cassette.play_at) do
            Ui.VCR.Record.stop(cassette_id)
          else
            Ui.VCR.Play.stop(cassette_id)
          end
        else
          erase(cassette_id)
        end
      _ ->
        erase(cassette_id)
    end
  end

  def erase(cassette_id) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    if cassette do
      :ok = Ui.VCR.Record.stop(cassette_id)
      :ok = :timer.sleep(100)
      changeset = Ui.Data.Cassette.changeset(cassette, %{
        blank: true,
        pid: nil,
        data: nil,
        start_at: nil,
        stop_at: nil
      })
      Ecto.Multi.new()
      |> Ecto.Multi.update(:cassette, changeset)
      |> Ui.Repo.transaction()
      |> case do
        {:ok, %{ cassette: cassette }} ->
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, [cassette], [
            observe_cassettes: <<>>
          ])
          :ok = Absinthe.Subscription.publish(UiWeb.Endpoint, cassette, [
            observe_cassette: to_string(cassette.id)
          ])
          {:ok, true}
        _ ->
          {:ok, false}
      end
    else
      {:ok, false}
    end
  end

  def events(cassette_id) do
    cassette = Ui.Repo.get(Ui.Data.Cassette, cassette_id)
    case cassette do
      %Ui.Data.Cassette{ blank: false, start_at: start_at, stop_at: stop_at, data: data } when start_at != nil and stop_at != nil and is_binary(data) ->
        events =
          try do
            :erlang.binary_to_term(data)
          catch _, _ ->
            []
          end
        case events do
          _ when is_list(events) ->
            events = cassette_events(events, nil, nil, [])
            {:ok, events}
          _ ->
            :error
        end
      _ ->
        :error
    end
  end

  @doc false
  defp cassette_events([{ticks, motors} | rest], nil, second, acc) do
    event = {ticks - ticks, motors}
    cassette_events(rest, ticks, second, [event | acc])
  end
  defp cassette_events([{ticks, motors} | rest], first, nil, acc) do
    event = {ticks - first, motors}
    cassette_events(rest, first, ticks, [event | acc])
  end
  defp cassette_events([{ticks, motors} | rest], first, second, acc) do
    event = {ticks - second, motors}
    cassette_events(rest, first, second, [event | acc])
  end
  defp cassette_events([], _first, _second, acc) do
    :lists.reverse(acc)
  end

  @doc false
  defp cassette_runtime([], acc) do
    {:ok, acc}
  end
  defp cassette_runtime([{ticks, _} | [{next_ticks, _} | _] = next_events], acc) do
    duration = next_ticks - ticks
    duration =
      if duration <= 25 do
        25
      else
        duration
      end
    cassette_runtime(next_events, acc + duration)
  end
  defp cassette_runtime([{_ticks, _motors}], acc) do
    cassette_runtime([], acc + 25)
  end

end
