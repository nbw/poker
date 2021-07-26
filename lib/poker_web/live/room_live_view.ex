defmodule PokerWeb.RoomLiveView do
  use Phoenix.LiveView

  alias PokerWeb.Presence

  @scores [1, 2, 3, 4, 5, 8, 10, 20]
  def scores, do: @scores

  def render(assigns) do
    PokerWeb.RoomView.render("show.html", assigns)
  end

  def mount(_, %{"room_id" => room_id, "user_token" => user_token, "locale" => locale}, socket) do
    # Subscribe to webhook to:
    # 1. send/broadcast messages
    # 2. receive presence_diff messages
    Phoenix.PubSub.subscribe(Poker.PubSub, topic(room_id))
    Phoenix.PubSub.subscribe(Poker.PubSub, topic_state(room_id))

    if connected?(socket), do: Process.send_after(self(), :heartbeat, 1000)

    {:ok,
     assign(socket,
       state: get_game_state(room_id),
       current_user: nil,
       room_id: room_id,
       user_name: "",
       user_observer: false,
       user_token: user_token,
       users: users_list(room_id),
       locale: locale,
       heartbeat: 0
     )}
  end

  def handle_info(:heartbeat, %{assigns: %{heartbeat: h}} = socket) do
    Process.send_after(self(), :heartbeat, 1000)

    {:noreply, assign(socket, :heartbeat, rem(h + 1, 100))}
  end

  # Channels/Presence: handle "reset" message
  def handle_info(
        %{event: "reset"},
        %{assigns: %{room_id: room_id, user_observer: true}} = socket
      ) do
    update_game_state(create_game_state(room_id), room_id)

    {:noreply, socket}
  end

  def handle_info(
        %{event: "reset"},
        %{
          assigns: %{
            room_id: room_id,
            user_token: user_token,
            user_name: name,
            user_observer: obs
          }
        } = socket
      ) do
    # Reset user to defaults
    user =
      create_user(user_token, name, obs)
      |> update_user(room_id, user_token)

    # Reset game state
    update_game_state(create_game_state(room_id), room_id)

    {:noreply, assign(socket, current_user: user)}
  end

  # Channels/Presence: When a change on a Presense object occurs
  def handle_info(
        %{event: "presence_diff", payload: _},
        %{assigns: %{room_id: room_id, user_token: user_token}} = socket
      ) do
    new_state = [
      users: users_list(room_id),
      state: get_game_state(room_id),
      current_user: get_current_user(room_id, user_token)
    ]

    {:noreply, assign(socket, new_state)}
  end

  # LiveView: Handle card selection
  def handle_event("card", _, %{assigns: %{current_user: %{observer: true}}} = socket),
    do: {:noreply, socket}

  def handle_event("card", _, %{assigns: %{state: %{edit_lock: true, finish: true}}} = socket),
    do: {:noreply, socket}

  def handle_event(
        "card",
        %{"num" => num},
        %{assigns: %{room_id: room_id, user_token: user_token}} = socket
      ) do
    # Convert to integer
    {num, _} = Integer.parse(num)

    update_user(%{score: num}, room_id, user_token)

    if all_users_voted?(room_id) do
      update_game_state(%{finish: true}, room_id)
    end

    {:noreply, socket}
  end

  # LiveView: Task title update
  def handle_event(
        "task_title",
        %{"title" => %{"query" => query}},
        %{assigns: %{room_id: room_id}} = socket
      ) do
    update_game_state(%{task_title: query}, room_id)

    {:noreply, socket}
  end

  # LiveView: Task URL update
  def handle_event(
        "task_url",
        %{"url" => %{"query" => query}},
        %{assigns: %{room_id: room_id}} = socket
      ) do
    update_game_state(%{task_url: query}, room_id)

    {:noreply, socket}
  end

  # LiveView: Start button
  def handle_event("start", _, %{assigns: %{room_id: room_id}} = socket) do
    update_game_state(%{start: true}, room_id)

    {:noreply, socket}
  end

  # LiveView: Finish button
  def handle_event("finish", _, %{assigns: %{room_id: room_id}} = socket) do
    update_game_state(%{finish: true}, room_id)

    {:noreply, socket}
  end

  # LiveView: Reset button
  def handle_event("reset", _, %{assigns: %{room_id: room_id}} = socket) do
    # Broadcast a "reset" message to everyone via webhook.
    # 理由: can only update presence objects you're tracking,
    # which doesn't include other users.
    PokerWeb.Endpoint.broadcast(topic(room_id), "reset", %{})

    {:noreply, socket}
  end

  def handle_event(
        "edit_lock",
        _,
        %{
          assigns: %{
            room_id: room_id,
            state: %{edit_lock: edit_lock}
          }
        } = socket
      ) do
    update_game_state(%{edit_lock: !edit_lock}, room_id)

    {:noreply, socket}
  end

  # LiveView: User's name input
  def handle_event("name-input", %{"name" => %{"query" => query}}, socket) do
    {:noreply, assign(socket, user_name: query)}
  end

  # LiveView: Join button
  # - Do nothing if name is blank
  def handle_event("create_user", %{"name" => ""}, socket), do: {:noreply, socket}

  def handle_event(
        "create_user",
        %{"obs" => obs},
        %{assigns: %{room_id: room_id, user_token: user_token, user_name: name}} = socket
      ) do
    user = create_user(user_token, name, observe(obs))

    Presence.track(
      self(),
      topic(room_id),
      user_token,
      user
    )

    {:noreply, assign(socket, current_user: user, user_observer: observe(obs))}
  end

  defp users_list(room_id) do
    Presence.list(topic(room_id))
    |> Enum.map(fn {_user_id, data} ->
      data[:metas]
      |> List.first()
    end)
  end

  defp get_current_user(room_id, user_token) do
    users_list(room_id)
    |> Enum.filter(fn user -> user[:id] == user_token end)
    |> List.first()
  end

  # Default user
  defp create_user(user_token, name, observer) do
    %{
      id: user_token,
      name: name,
      observer: observer,
      score: -1
    }
  end

  # Default game state
  defp create_game_state(id) do
    %{
      id: id,
      start: false,
      finish: false,
      task_title: "",
      task_url: "",
      edit_lock: true
    }
  end

  defp update_user(params, room_id, user_token) do
    user = Map.merge(get_current_user(room_id, user_token), params)
    Presence.update(
      self(),
      topic(room_id),
      user_token,
      user
    )

    user
  end

  defp update_game_state(params, room_id) do
    state = Map.merge(get_game_state(room_id), params)
    pid = Process.whereis(String.to_atom(room_id))

    # Only the PID tracking the presence object has update
    # access. So retrieve the PID we registered before
    Presence.update(
      pid,
      topic_state(room_id),
      room_id,
      state
    )
  end

  # Get game state
  # - Create Presence object if one doesn't exist
  # - Otherwise grab existing one
  defp get_game_state(room_id) do
    topic = topic_state(room_id)

    Presence.list(topic)
    |> Map.fetch(room_id)
    |> case do
      {:ok, s} ->
        s

      :error ->
        # Register the process so everyone can access it.
        # (this is so anyone can update the presence object)
        #
        # Issue: memory; not handling unregistering of processes
        Process.whereis(String.to_atom(room_id))
        |> case do
          nil -> Process.register(self(), String.to_atom(room_id))
          p -> p
        end

        Presence.track(
          self(),
          topic,
          room_id,
          create_game_state(room_id)
        )

        Presence.list(topic)
        |> Map.fetch!(room_id)
    end
    |> Map.fetch!(:metas)
    |> List.first()
  end

  defp topic(room_id), do: "room:#{room_id}"
  defp topic_state(room_id), do: "room:#{room_id}_state"

  defp all_users_voted?(room_id) do
    users_list(room_id)
    |> Enum.reject(fn u -> u[:observer] end)
    |> Enum.all?(fn u -> u[:score] > -1 end)
  end

  def observe("true"), do: true
  def observe("false"), do: false
end
