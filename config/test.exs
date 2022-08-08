import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bertil, BertilWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "OtQzxv3Oqm0LnJ9dS3P15wILb/Lzjl18/baO56+1PU+9XAfcCX1vqbSc4hgxqzWn",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
