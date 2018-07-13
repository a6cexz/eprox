# Eprox

Simple reverse proxy implemented using Elixir programming language. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add eprox to your list of dependencies in `mix.exs`:

        def deps do
          [{:eprox, "~> 0.0.1"}]
        end

  2. Ensure eprox is started before your application:

        def application do
          [applications: [:eprox]]
        end