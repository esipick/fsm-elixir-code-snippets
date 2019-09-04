# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Flight.Repo.insert!(%Flight.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

{:ok, invitation} = Flight.Accounts.create_school_invitation(%{
  email: "bryan@brycelabs.com",
  first_name: "Bryan",
  last_name: "Bryce"
})

 user_data = %{
   email: "bryan@brycelabs.com",
   first_name: "Bryan", last_name: "Bryce",
   phone_number: "555-555-5555",
   school_name: "Example School",
   timezone: "America/Denver",
   password: "password"
 }

{:ok, _records} = Flight.Accounts.create_school_from_invitation(user_data, invitation)
