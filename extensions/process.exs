defmodule Nb.Proc do
  def start(function, subscribe_function, initial_state) do
    spawn(fn -> run(function, subscribe_function, initial_state) end)
  end

  def run(function, subscribe_function, initial_state) do
    subscribe_function.()
    watch(initial_state, function, now(), initial_state)
  end

  defp now, do: System.system_time(:millisecond)

  def watch(state, function, start, initial_state) do
    receive do
      {:state, parent} ->
        send(parent, {state, now() - start})
        watch(state, function, start, initial_state)

      {:flush, parent} ->
        send(parent, {state, now() - start})
        watch(initial_state, function, now(), initial_state)

      message ->
        watch(function.(message, state), function, start, initial_state)
    after
      1000 ->
        watch(state, function, start, initial_state)
    end
  end

  def state(pid) do
    send(pid, {:state, self()})

    receive do
      value -> value
    end
  end

  def flush(pid) do
    send(pid, {:flush, self()})

    receive do
      value -> value
    end
  end
end

defmodule Nb.Actor do
  def start_link(args) do
    name = Keyword.get(args, :name)
    handler = Keyword.fetch!(args, :handler)
    initial_state = Keyword.get(args, :initial_state, nil)

    spawn_link(fn ->
      if name, do: Process.register(self(), name)
      run(handler, initial_state)
    end)
  end

  def fire(pid, message) do
    send(pid, {:"$actor_fire", message})
    :ok
  end

  def fetch(pid, message) do
    send(pid, {:"$actor_fetch", self(), message})

    receive do
      {:"$actor_fetch_response", response} ->
        response
    end
  end

  defp run(handler, state) do
    case receive_message(handler, state) do
      :stop ->
        :ok

      new_state ->
        run(handler, new_state)
    end
  end

  defp receive_message(handler, state) do
    receive do
      :stop ->
        :stop

      {:"$actor_fire", message} ->
        handler.(message, state)

      {:"$actor_fetch", from, message} ->
        case handler.(message, state) do
          {response, state} ->
            send(from, {:"$actor_fetch_response", response})

            state

          state ->
            send(from, {:"$actor_fetch_response", nil})
            state
        end

      message ->
        handler.(message, state)
    end
  end
end
