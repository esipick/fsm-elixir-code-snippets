defmodule FlightWeb.API.SessionController do
  use FlightWeb, :controller

  alias Flight.Accounts
  alias Flight.Accounts.User

  def api_login(conn, %{"email" => email, "password" => password}) do
    case user = Accounts.get_user_by_email(email) do
      %User{archived: true} ->
        conn
        |> put_status(401)
        |> json(%{human_errors: [FlightWeb.AuthenticateApiUser.account_suspended_error()]})

      %User{archived: false} ->
        case Accounts.check_password(user, password) do
          {:ok, user} ->
            user =
              user
              |> FlightWeb.API.UserView.show_preload()

            render(conn, "login.json",
              user: user,
              token: FlightWeb.AuthenticateApiUser.token(user)
            )

          {:error, _} ->
            conn
            |> put_status(401)
            |> json(%{human_errors: ["Invalid email or password."]})
        end

      _ ->
        Comeonin.Bcrypt.dummy_checkpw()

        conn
        |> put_status(401)
        |> json(%{human_errors: ["Invalid email or password."]})
    end
  end

  def user_info(conn, _params) do
    user = 
      conn.assigns.current_user
      |> Flight.Repo.preload([:roles])

    roles = Enum.map(user.roles, &(&1.slug))
    
    {student_ids, aircraft_ids, instructor_ids} =
      cond do
        "student" in roles ->
          IO.inspect("Here i Come")
          user = Flight.Repo.preload(user, [:aircrafts])
          aircraft_ids = Enum.map(user.aircrafts, & &1.id)
          instructor_ids = Accounts.get_student_instructor_ids(user.id)
          instructor_ids = 
            if user.main_instructor_id != nil, do: [user.main_instructor_id | instructor_ids], else: instructor_ids

          {[], aircraft_ids, instructor_ids}

        "instructor" in roles -> 
          # In db table user_instructors, records are saved such as the instructor id goes to user_id column and the user_id goes to instructor_id column
          student_ids = Accounts.get_instructor_student_ids(user.id)
          main_student_ids = Accounts.get_main_instructor_student_ids(user.id)

          {main_student_ids ++ student_ids, [], []}

        true -> {[], [], []}
      end

    user = 
      user
      |> Map.take([:id, :first_name, :last_name])
      |> Map.put(:roles, roles)
      |> Map.put(:instructors, instructor_ids)
      |> Map.put(:aircrafts, aircraft_ids)
      |> Map.put(:students, student_ids)

    json(conn, user)
  end
end
