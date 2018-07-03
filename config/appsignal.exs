use Mix.Config

config :appsignal, :config,
  active: Mix.env() not in [:dev, :test],
  name: "randon-aviation",
  push_api_key: "e6c5ebe7-ea51-4eb8-bcfa-b23071f09340",
  env: Mix.env()
