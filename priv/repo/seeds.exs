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

alias Seeds.User
alias Seeds.Aircraft

admins_info = [
  %{
    email: "bryan@brycelabs.com",
    first_name: "Bryan",
    last_name: "Bryce",
    phone_number: "555-555-5555",
    school_name: "Example school",
    timezone: "America/Denver",
    password: "password"
  },
  %{
    email: "bruce_wayne@batman.com",
    first_name: "Bruce",
    last_name: "Wayne",
    phone_number: "555-555-5555",
    school_name: "Superhero school",
    timezone: "America/Denver",
    password: "password"
  },
  %{
    email: "washington@usa.com",
    first_name: "Donald J.",
    last_name: "Trump",
    phone_number: "555-555-5555",
    school_name: "White House",
    timezone: "America/Denver",
    password: "password"
  }
]

Enum.each(admins_info, fn admin_info ->
  {:ok, invitation} =
    Flight.Accounts.create_school_invitation(%{
      email: admin_info.email,
      first_name: admin_info.first_name,
      last_name: admin_info.last_name
    })

  {:ok, {school, _}} = Flight.Accounts.create_school_from_invitation(admin_info, invitation)
  {:ok, account} = Stripe.Account.retrieve("acct_1Cq50RA9eFdB5LRw")

  Flight.Accounts.StripeAccount.new(account)
  |> Flight.Accounts.StripeAccount.changeset(%{school_id: school.id})
  |> Flight.Repo.insert!()

  User.seed("dispatcher", 2, school)
  User.seed("instructor", 5, school)
  User.seed("student", Enum.random(5..10), school)
  Aircraft.seed(Enum.random(5..10), school)
end)

Flight.Accounts.Role.renter()
