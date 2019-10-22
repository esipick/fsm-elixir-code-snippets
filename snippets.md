# Stripe Testing Examples

Attach invalid card to user without customer in stripe:

```elixir
{:ok, token} = Stripe.Token.create(%{card: %{number: "4000000000000341", exp_month: 10, exp_year: 2020, cvc: "123"}})

user = Flight.Accounts.dangerous_get_user_by(id)

{:ok, customer} = Stripe.Customer.create(%{email: user.email, source: token.id})

user |> Flight.Accounts.User.stripe_customer_changeset(%{ stripe_customer_id: customer.id }) |> Flight.Repo.update()
```


Attach invalid card to user with customer in stripe:

```elixir
{:ok, token} = Stripe.Token.create(%{card: %{number: "4000000000000341", exp_month: 10, exp_year: 2020, cvc: "123"}})

user = Flight.Accounts.dangerous_get_user_by(id)

Stripe.Customer.update(user.stripe_customer_id, %{source: token.id})
```
