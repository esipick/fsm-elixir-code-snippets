defmodule FlightWeb.PasswordController do
  use FlightWeb, :controller

  def forgot(conn, _) do
    render(conn, "forgot_password.html")
  end

  def forgot_submit(conn, %{"email" => email}) do
    user = Flight.Accounts.get_user_by_email(email)

    if user do
      {:ok, reset} = Flight.Accounts.create_password_reset(user)

      reset
      |> Flight.Repo.preload(:user)
      |> Flight.Email.reset_password_email()
      |> Flight.Mailer.deliver_later()
    end

    conn
    |> put_flash(:success, "Please check your email for password reset instructions.")
    |> redirect(to: "/forgot_password")
  end

  def reset(conn, params) do
    reset = Flight.Accounts.get_password_reset_from_token(params["token"] || "")

    if reset do
      render(conn, "reset_password.html", password_reset: reset, password: "", confirmation: "")
    else
      conn
      |> put_flash(
        :error,
        "The reset link you clicked is either expired or invalid. Please attempt to reset your password again by entering your email."
      )
      |> redirect(to: "/forgot_password")
    end
  end

  def reset_submit(conn, %{
        "token" => token,
        "password" => password,
        "password_confirmation" => confirmation
      }) do
    reset = Flight.Accounts.get_password_reset_from_token(token || "")

    if reset do
      if password != confirmation do
        conn
        |> put_flash(:error, "Password and confirmation didn't match. Please try again.")
        |> redirect(to: "/reset_password?token=#{token}")
      else
        case Flight.Accounts.set_password(reset.user, password) do
          {:ok, _user} ->
            render(conn, "reset_password_success.html")

          {:error, %Ecto.Changeset{errors: [password: {message, []}]}} ->
            conn
            |> put_flash(:error, message)
            |> redirect(to: "/reset_password?token=#{token}")
        end
      end
    else
      conn
      |> put_flash(
        :error,
        "The reset link you clicked is either expired or invalid. Please attempt to reset your password again by entering your email."
      )
      |> redirect(to: "/forgot_password")
    end
  end
end
