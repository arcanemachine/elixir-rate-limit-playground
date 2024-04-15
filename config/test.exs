import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :rate_limit_playground, RateLimitPlaygroundWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "eo4Md/rMYxHgfj+wBF3l4w0n25W/wCg3duvq8KTpfhmJldXot0gut13DpW6DMp/l",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true
