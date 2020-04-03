defmodule FlightWeb.PasswordController do
  use FlightWeb, :controller

  alias Flight.Accounts

  def forgot(conn, _) do
    render(conn, "forgot_password.html")
  end

  def forgot_submit(conn, %{"email" => email}) do
    conn =
      cond do
        email == "" ->
          conn |> put_flash(:error, "Please enter your email")

        String.match?(email, Flight.Format.email_regex()) ->
          check_user(conn, email)

        true ->
          conn |> put_flash(:error, "Invalid email format")
      end

    conn
    |> forgot_password_redirect()
  end

  def reset(conn, params) do
    case Accounts.get_password_reset_from_token(params["token"] || "") do
      %{} = reset ->
        render(conn, "reset_password.html", password_reset: reset, password: "", confirmation: "")

      _ ->
        conn
        |> put_flash(
          :error,
          "The reset link you clicked is either expired or invalid. Please attempt to reset your password again by entering your email."
        )
        |> forgot_password_redirect()
    end
  end

  def reset_submit(conn, %{
        "token" => token,
        "password" => password,
        "password_confirmation" => confirmation
      }) do
    case Accounts.get_password_reset_from_token(token || "") do
      %{} = reset ->
        password = String.trim(password)
        confirmation = String.trim(confirmation)

        case password == confirmation do
          true ->
            case Accounts.set_password(reset.user, password) do
              {:ok, _user} ->
                render(conn, "reset_password_success.html")

              {:error, %Ecto.Changeset{errors: [password: {message, _}]}} ->
                conn
                |> put_flash(:error, "Password #{message}.")
                |> redirect(to: "/reset_password?token=#{token}")
            end

          false ->
            conn
            |> put_flash(:error, "Password and confirmation didn't match. Please try again.")
            |> redirect(to: "/reset_password?token=#{token}")
        end

      _ ->
        conn
        |> put_flash(
          :error,
          "The reset link you clicked is either expired or invalid. Please attempt to reset your password again by entering your email."
        )
        |> forgot_password_redirect()
    end
  end

  defp forgot_password_redirect(conn), do: redirect(conn, to: "/forgot_password")

  defp check_user(conn, email) do
    user = Accounts.get_user_by_email(email)

    cond do
      user && user.archived ->
        conn |> put_flash(:error, "Account is suspended. Please contact your school administrator to reinstate it.")

      user && !user.archived ->
        {:ok, reset} = Accounts.create_password_reset(user)
          reset
          |> Flight.Repo.preload(:user)
          |> Flight.Email.reset_password_email()
          |> Flight.Mailer.deliver_later()

        conn
          |> put_flash(:success, "Please check your email for password reset instructions.")

      user == nil ->
        conn |> put_flash(:error, "This email is not registered")
    end
  end
end
