# Flight

## Run Tests
`mix test` for fast tests

`mix test --include=integration` for all tests

## Bootstrap first school on a new server

Start an iex session.

Create a school invitation:

```
Flight.Accounts.create_school_invitation(%{email: "bryan@brycelabs.com", first_name: "Bryan", last_name: "Bryce"})
```

Accept the invitation by getting the invitation token from the database and navigating to `school_invitations/:token` in the browser:

Example: 
```
http://0.0.0.0:4000/school_invitations/34cfb36c210b9249cc4384500b1ee37a14f1374917f0170bac
```

## Cloud 9 Instructions:

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
