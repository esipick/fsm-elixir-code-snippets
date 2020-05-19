# Flight

## Run Tests
`mix test` for fast tests

`mix test --include=integration` for all tests

## Dev env setup

1. Install elixir 1.10.1
2. Install node 13.5.0

3. Install dependencies and run setup
```bash
# Install elixir dependencies
mix deps.get
mix deps.compile

# Install frontend dependencies
cd assets && yarn

# Setup database
mix ecto.setup

# Run server
mix phx.server
```

4. Login with example user:
- Email: `admin-1@example.com`
- Password: `password`

## Bootstrap first school and user on a new server

```bash
mix run priv/repo/seeds.exs # is also running automatically with mix ecto.setup
```

This will create sample schools, users and aircrafts. Check `priv/repo/seeds.ex` for the login details.

# Deployment

## Staging application

Staging application is being deployed automatically from master branch to https://randon-aviation-staging.herokuapp.com. But if for some reason you need to deploy to staging manually:

```
git remote add staging https://git.heroku.com/randon-aviation-staging.git
git push staging master
```

## Production application

```
git remote add prod https://git.heroku.com/randon-aviation.git
git push prod master
```

# CI

We use [SemaphoreCI](https://russellaviation.semaphoreci.com/dashboards/my-work) for running tests suite.
