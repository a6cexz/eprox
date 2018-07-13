defmodule Eprox do
  use Application

  def start(_type, _args) do
    IO.puts "Eprox start"
    opts = [strategy: :one_for_one, name: Eprox]
    Supervisor.start_link([], opts)
  end

end
