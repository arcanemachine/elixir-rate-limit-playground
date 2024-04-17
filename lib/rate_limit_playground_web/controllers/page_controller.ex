defmodule RateLimitPlaygroundWeb.PageController do
  use RateLimitPlaygroundWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def wait(conn, params) do
    response_delay = (params["response_delay"] || "2000") |> String.to_integer()

    Process.sleep(response_delay)

    text(conn, "ok")
  end
end
