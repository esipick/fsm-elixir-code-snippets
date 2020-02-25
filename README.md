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

## Cloud 9 Instructions

#### Start FSM Server

Run -> Run Configurations -> Start FSM Server


#### Pull latest changes from git

```
git pull origin master
```

#### Commit latest changes to git

```
git commit -am "Your commit message."
```

#### Push new commits to GitHub

```
git push origin master
```
