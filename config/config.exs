# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :insta_markdown,
  ecto_repos: [InstaMarkdown.Repo]

# Configures the endpoint
config :insta_markdown, InstaMarkdownWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vlzywSsO+2L1dOf6SVsVn7VJPMJ/oyr10wH7jCLcNl++SAuXkPQ20t/qDSefGEgI",
  render_errors: [view: InstaMarkdownWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: InstaMarkdown.PubSub,
  live_view: [signing_salt: "5fx/EcCU"]

config :insta_markdown, InstaMarkdown.Content,
  root_folder: "/home/alfredbaudisch/Documents/content",
  cache_name: :content_cache

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
