defmodule LiveViewStudioWeb.LicenseLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Licenses
  import Number.Currency

  def mount(_params, _session, socket) do
    expiration_time = Timex.shift(Timex.now(), minutes: 1)

    if connected?(socket) do
      Process.send_after(self(), :tick, 1000)
    end

    socket =
      assign(socket,
        seats: 3,
        amount: Licenses.calculate(3),
        expiration_time: expiration_time,
        time_remaining: time_remaining(expiration_time)
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <h1>Team License</h1>
    <div id="license">
      <div class="card">
        <div class="content">
          <div class="seats">
            <img src="images/license.svg">
            <span>
              Your license is currently for
              <strong><%= @seats %></strong> seats.
            </span>
          </div>

          <form phx-change="update">
            <input type="range" min="1" max="10"
                  name="seats" value="<%= @seats %>" />
          </form>

          <div class="amount">
            <%= number_to_currency(@amount) %>
          </div>

          <p class="m-4 font-semibold text-indigo-800">
            <%= @time_remaining %> remaining for a huge saving.
          </p>
        </div>
      </div>
    </div>
    """
  end

  def handle_info(:tick, socket) do
    time_remaining = time_remaining(socket.assigns.expiration_time)

    socket = assign(socket, :time_remaining, time_remaining)

    Process.send_after(self(), :tick, 1000)

    {:noreply, socket}
  end

  def handle_event("update", %{"seats" => seats}, socket) do
    seats = String.to_integer(seats)

    socket =
      assign(socket,
        seats: seats,
        amount: Licenses.calculate(seats)
      )

    {:noreply, socket}
  end

  defp time_remaining(expiration_time) do
    try do
      Timex.Interval.new(from: Timex.now(), until: expiration_time)
      |> Timex.Interval.duration(:seconds)
      |> Timex.Duration.from_seconds()
      |> Timex.format_duration(:humanized)
    rescue
      _ -> 0
    end
  end
end
