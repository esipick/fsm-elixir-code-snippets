# Flight School Manager

## Run Tests
`mix test` for fast tests

`mix test --include=integration` for all tests

## Setup dev environment

1. Install elixir 1.10.1 and erlang 22.2.7

2. Install node 16.13.0

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

## Deployment

### Staging application

Staging application is being deployed automatically from develop branch to https://randon-aviation-staging.herokuapp.com but if for some reason we need to deploy to staging manually:

```
git remote add develop https://git.heroku.com/randon-aviation-staging.git
git push develop develop:master -f
```


### Production application

Production application is being deployed automatically from master branch to https://app.flightschoolmanager.co but if for some reason 
we need to deploy to master manually:

```
git remote add prod https://git.heroku.com/randon-aviation.git
git push prod prod:master
```

**Note**: Also we can trigger deployment from heroku dashboard for both staging and production from any branch. We also need to be careful application slug size (build size) which has soft limit of `300MB` and `500MB` as hard limit. If build failed because of application slug-size, we can do following activities:

- Purge build-cache using herko CLI [Slug Size](https://devcenter.heroku.com/articles/slug-compiler#slug-size)
- Check removed unused dependencies for mix and node_modules
- Move assets on internet and access on run-time

Once deployement done either on staging or production, we update application version by running method directly
into `iex` remote console. In order to access elixir remote console, we need to run following command

```bash
heroku run iex -S mix -a randon-aviation # for production

heroku run iex -S mix -a randon-aviation-staging # for staging
```

Once iex remote console isready, then we can do 

```ex
Fsm.AppVersions.update_app_version("4.1.0")
```
It updates all clients iOS, android and web versions directly in database. App version is basically version of
current release on GitHub or current milestone number.

## Database

We're using PostgreSQL and managing database interactions with Ecto. In order to perform `ecto` actions e.g. `ecto.migrate`, `ecto.rollback`
we can run mix tasks directly through heroku CLI as:

```bash
heroku run mix ecto.migrate -a randon-aviation # for production

heroku run mix ecto.migrate -a randon-aviation-staging # for staging
```
## Application Logging

To view deployed application logs either on staging or production, we can check logs through heroku CLI as

```bash
heroku logs --tail -a randon-aviation # for production

heroku logs --tail -a randon-aviation-staging # for staging
```
# CI

We use [SemaphoreCI](https://russellaviation.semaphoreci.com/dashboards/my-work) for running tests suite.
