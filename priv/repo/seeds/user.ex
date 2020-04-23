role_name = List.first(System.argv())

defmodule Seeds.User do
  def seed(role_name, amount \\ 99, school \\ Flight.Repo.one(Flight.Accounts.School)) do
    role = user_role(role_name)

    first_names = [
      "Constance",
      "Maxie",
      "Andy",
      "Barry",
      "Maverick",
      "Roxane",
      "Reid",
      "America",
      "Dolly",
      "Rylan",
      "Maurice",
      "Chesley",
      "Pierce",
      "Camila",
      "Torey",
      "Aiyana",
      "Ophelia",
      "Jeremie",
      "Niko",
      "Ariane",
      "Rosendo"
    ]

    last_names = [
      "Breitenberg",
      "Bartoletti",
      "Greenfelder",
      "Kihn",
      "Shields",
      "Pouros",
      "Schamberger",
      "Bogan",
      "Strosin",
      "Green",
      "Fisher",
      "Thompson",
      "Marquardt",
      "Heidenreich",
      "Bruen",
      "Kling",
      "Toy",
      "Ziemann",
      "Upton",
      "Funk",
      "Schuster"
    ]

    Enum.each(1..amount, fn _i ->
      school_context = %Plug.Conn{assigns: %{current_user: %{school_id: school.id}}}

      phone_number =
        Integer.to_string(Enum.random(100..999)) <>
          "-" <>
          Integer.to_string(Enum.random(100..999)) <>
          "-" <>
          Integer.to_string(Enum.random(1000..9999))

      user_data = %{
        email: "#{role_name}+#{Flight.Random.hex(15)}@gmail.com",
        first_name: Enum.random(first_names),
        last_name: Enum.random(last_names),
        phone_number: phone_number,
        school_id: school.id,
        timezone: "America/Denver",
        password: "password",
        balance: Enum.random(0..99999)
      }

      case Flight.Accounts.create_user(user_data, school_context) do
        {:ok, user} ->
          if role_name == "student",
            do: Stripe.Card.create(%{customer: user.stripe_customer_id, source: "tok_visa"})

          Flight.Accounts.assign_roles(user, [role])

        _ ->
          IO.puts("err")
      end
    end)
  end

  def user_role(role_name) do
    case role_name do
      "dispatcher" ->
        Flight.Accounts.Role.dispatcher()

      "instructor" ->
        Flight.Accounts.Role.instructor()

      "renter" ->
        Flight.Accounts.Role.renter()

      _ ->
        Flight.Accounts.Role.student()
    end
  end
end
