defmodule Exserver do
  def start(_type, _args) do
    dispatch_config = build_dispatch_config
    IO.puts "starting server in port 8000"
    { :ok, _ } = :cowboy.start_clear(:api,
                                     [{:port, 8000}],
                                     %{:env => %{:dispatch => build_dispatch_config}})
  end

  def build_dispatch_config do
    :cowboy_router.compile([
      {:_, [
        {"/", :cowboy_static, {:file, "../public/index.html"}},
        {"/ws", WebsocketHandler, []},
        {"/[...]", :cowboy_static, {:dir, "../public/"}},
      ]}
    ])
  end
end
