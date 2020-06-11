# Setup:
1. Install `heroku-cli`
2. run `heroku login` and follow through steps
3. Add git remotes:
```
git remote add staging https://git.heroku.com/randon-aviation-staging.git
git remote add prod https://git.heroku.com/randon-aviation.git
```

# Deploy to staging
Being done automatically from master branch, if you need to deploy manually run:
```
git push staging master
```

# Deploy to production:
We have a `prod` branch to keep track of prod and be able to do cherry-picks
```
git push prod prod:master -f
```

# Migrations
Migrations are NOT running automatically. To run migrations:
```
heroku run mix.ecto migrate -r staging # or prod
```

# Console
```
heroku run iex -S mix -r staging # or prod
```

# ENV variables
Set env variables on Heroku in the "Settings" tab. E.g.
https://dashboard.heroku.com/apps/randon-aviation-staging/settings

# Resources
Manage available addons through "Resources" tab on Heroku. E.g.
https://dashboard.heroku.com/apps/randon-aviation-staging/resources
