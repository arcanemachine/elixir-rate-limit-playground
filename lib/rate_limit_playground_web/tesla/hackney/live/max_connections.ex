defmodule RateLimitPlaygroundWeb.Tesla.Hackney.Live.MaxConnections do
  use RateLimitPlaygroundWeb, :live_view

  defmodule Client do
    defstruct [:struct, :stats]
  end

  defmodule Request do
    defstruct [:id, :client, status: :created]
  end

  defp get_default_values do
    [
      clients: [
        # %Client{
        #   struct:
        #     Tesla.client(
        #       [],
        #       {Tesla.Adapter.Hackney,
        #        pool: :pool_1, max_connections: 4, recv_timeout: 10_000, checkout_timeout: 8_000}
        #     ),
        #   stats: nil,
        #   ok: 0,
        #   timeout: 0,
        #   checkout_timeout: 0,
        # }
      ],
      requests: [
        # %{id: 1, client: :hello_world, status: :created}
      ],
      # Create a ticker that shows the number of seconds since the socket was mounted. If you see
      # this value updating in the page every second, then the page update logic is working
      ticker: 0
    ]
  end

  ## Lifecycle
  @impl true
  def mount(_params, _session, socket) do
    # Set up initial background job
    if connected?(socket), do: schedule_data_refresh()

    {:ok, socket |> assign(get_default_values())}
  end

  defp schedule_data_refresh() do
    Process.send_after(self(), :update_page_data, 500)
  end

  @impl true
  def handle_info(:update_page_data, socket) do
    schedule_data_refresh()

    clients =
      Enum.map(socket.assigns.clients, fn %Client{} = client ->
        pool = get_pool_by_client(client)
        Map.put(client, :stats, get_hackney_pool_stats(pool))
      end)

    {:noreply,
     socket
     |> assign(
       clients: clients,
       ticker: socket.assigns.ticker + 1
     )}
  end

  @impl true
  def handle_event("debug", _params, socket) do
    require IEx
    IEx.pry()
    {:noreply, socket}
  end

  def handle_event(
        "create_client",
        %{
          "recv_timeout" => recv_timeout,
          "checkout_timeout" => checkout_timeout,
          "max_connections" => max_connections
        } = _params,
        socket
      ) do
    pool = "pool_#{length(socket.assigns.clients) + 1}" |> String.to_atom()

    adapter =
      {
        Tesla.Adapter.Hackney,
        # Set `timeout` to 0 to ensure no keep-alive connections are actually kept alive
        pool: pool,
        timeout: 0,
        max_connections: String.to_integer(max_connections),
        recv_timeout: String.to_integer(recv_timeout),
        checkout_timeout: String.to_integer(checkout_timeout)
      }

    client = %Client{
      struct: Tesla.client(_middleware = [], adapter),
      stats: []
    }

    {:noreply, socket |> assign(clients: socket.assigns.clients ++ [client])}
  end

  def handle_event(
        "create_request",
        %{"pool" => pool, "response_delay" => response_delay} = _params,
        socket
      ) do
    client = get_client_by_pool(socket.assigns.clients, String.to_atom(pool))

    request = %Request{
      id: length(socket.assigns.requests) + 1,
      client: client,
      status: :created
    }

    Task.start(fn ->
      {status, _resp} =
        res =
        Tesla.get(
          client.struct,
          "http://localhost:4000/#{Enum.random(["wait", "delay", "hang"])}?response_delay=#{response_delay}"
        )

      if status == :ok do
        IO.inspect("Request ##{request.id} status: #{status}")
      else
        IO.inspect(res)
      end
    end)

    {:noreply, socket |> assign(requests: socket.assigns.requests ++ [request])}
  end

  def get_client_by_pool(clients, pool) do
    Enum.find(clients, fn client ->
      get_pool_by_client(client) == pool
    end)
  end

  def get_hackney_pool_stats(pool) do
    if :hackney_pool.find_pool(pool) == :undefined do
      nil
    else
      :hackney_pool.get_stats(pool)
    end
  end

  def get_max_connections_by_client(%Client{} = client),
    do: get_max_connections_by_client(client.struct)

  def get_max_connections_by_client(client),
    do: client.adapter |> elem(2) |> List.first() |> Keyword.get(:max_connections)

  def get_recv_timeout_by_client(%Client{} = client),
    do: get_recv_timeout_by_client(client.struct)

  def get_recv_timeout_by_client(client),
    do: client.adapter |> elem(2) |> List.first() |> Keyword.get(:recv_timeout)

  def get_checkout_timeout_by_client(%Client{} = client),
    do: get_checkout_timeout_by_client(client.struct)

  def get_checkout_timeout_by_client(client),
    do: client.adapter |> elem(2) |> List.first() |> Keyword.get(:checkout_timeout)

  def get_pool_by_client(%Client{} = client), do: get_pool_by_client(client.struct)

  def get_pool_by_client(client),
    do: client.adapter |> elem(2) |> List.first() |> Keyword.get(:pool)

  def get_pool_by_request(%Request{} = request), do: get_pool_by_client(request.client)

  defp get_requests_by_client(requests, %Client{} = client) do
    Enum.filter(requests, fn request ->
      get_pool_by_request(request) == get_pool_by_client(client)
    end)
  end
end
