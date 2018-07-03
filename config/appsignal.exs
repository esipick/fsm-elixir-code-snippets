use Mix.Config

config :appsignal, :config,
  active: !(System.get_env("APPSIGNAL_ACTIVE") == "false"),
  name: "randon-aviation",
  push_api_key: "e6c5ebe7-ea51-4eb8-bcfa-b23071f09340",
  env: System.get_env("APPSIGNAL_ENV") || Mix.env()
