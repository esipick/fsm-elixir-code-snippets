# Flight

## Run Tests
`mix test` for fast tests

`mix test --include=integration` for all tests

## Dev env setup

1. Install elixir 1.9.1

2. Install dependencies and run setup
```bash
# Install elixir dependencies
mix deps.get
mix deps.compile

# Install frontend dependencies
cd assets && npm i

# Setup database
mix ecto.setup

# Run server
mix phx.server
```

3. Login with example user:
- Email: `bryan@brycelabs.com`
- Password: `password`

## Bootstrap first school and user on a new server

```bash
mix run priv/repo/seeds.exs # is also running automatically with mix ecto.setup
```

This will create school with name `Example School` and user with email `bryan@brycelabs.com` and password `password`.

Populate database with sample data:
```bash
mix run priv/repo/user_seeds.ex # create 100 students
mix run priv/repo/user_seeds.ex instructor # create 100 instructors
mix run priv/repo/user_seeds.ex renter # create 100 renters

mix run priv/repo/aircraft_seeds.ex # create 100 aircrafts
```

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
