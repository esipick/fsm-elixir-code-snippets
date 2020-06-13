defmodule FlightWeb.Admin.InvitationController do
  use FlightWeb, :controller

  alias Flight.Accounts

  plug(:get_invitation when action in [:resend, :delete])
  plug(:check_invitation when action in [:create])

  def index(conn, %{"role" => "user" = role_slug}) do
    invitations = Accounts.visible_invitations_with_role(role_slug, conn)
    available_user_roles = Accounts.get_user_roles(conn)

    render(
      conn,
      "users.html",
      invitations: invitations,
      changeset: Accounts.Invitation.create_changeset(%Accounts.Invitation{}, %{}),
      request_path: invite_request_path(conn),
      role: %{slug: "user"},
      available_user_roles: available_user_roles
    )
  end

  def index(conn, %{"role" => role_slug}) do
    invitations = Accounts.visible_invitations_with_role(role_slug, conn)

    render(
      conn,
      "index.html",
      invitations: invitations,
      changeset: Accounts.Invitation.create_changeset(%Accounts.Invitation{}, %{}),
      request_path: invite_request_path(conn),
      role: Accounts.role_for_slug(role_slug)
    )
  end

  def create(conn, %{"data" => %{} = data}) do
    case Accounts.create_invitation(data, conn) do
      {:ok, invitation} ->
        conn
        |> put_flash(
          :success,
          "Successfully sent invitation. Please have #{invitation.first_name} check their email to complete the sign up process."
        )
        |> redirect(to: "/admin/invitations?role=user")

      {:error, changeset} ->
        invitations = Accounts.visible_invitations_with_role(conn.assigns.role.slug, conn)
        available_user_roles = Accounts.get_user_roles(conn)

        render(conn, "index.html",
          invitations: invitations,
          changeset: changeset,
          request_path: invite_request_path(conn),
          role: conn.assigns.role,
          available_user_roles: available_user_roles
        )
    end
  end

  def delete(conn, _params) do
    Accounts.delete_invitation!(conn.assigns.invitation)

    conn
    |> put_flash(:success, "Invitation deleted")
    |> redirect(to: "/admin/invitations?role=user")
  end

  def resend(conn, _params) do
    Accounts.send_invitation_email(conn.assigns.invitation)

    conn
    |> put_flash(
      :success,
      "Successfully sent invitation email to #{conn.assigns.invitation.email}"
    )
    |> redirect(to: "/admin/invitations?role=user")
  end

  defp get_invitation(conn, _) do
    invitation = Accounts.get_invitation(conn.params["id"] || conn.params["invitation_id"], conn)
    role = invitation && Accounts.get_role(invitation.role_id)
    slug = invitation && String.capitalize(role.slug)

    cond do
      invitation && invitation.accepted_at ->
        conn
        |> put_flash(:error, "#{slug} already registered.")
        |> redirect(to: "/admin/invitations?role=user")
        |> halt()

      invitation ->
        conn
        |> assign(:invitation, invitation)
        |> assign(:role, role.slug)

      true ->
        conn
        |> put_flash(:error, "Invitation already removed.")
        |> redirect(to: "/admin/dashboard")
        |> halt()
    end
  end

  defp check_invitation(conn, _) do
    email = conn.params["data"]["email"]
    invitation = Accounts.get_invitation_for_email(email, conn)
    user = Accounts.get_user_by_email(email)
    role = invitation && Accounts.get_role!(invitation.role_id)
    slug = invitation && String.capitalize(role.slug)

    cond do
      invitation && invitation.accepted_at && user.archived ->
        conn
        |> put_flash(
          :error,
          "#{slug} already removed with this email address. You may reinstate this account using \"Restore\" button below"
        )
        |> redirect(to: "/admin/users?role=user&tab=archived")
        |> halt()

      invitation && invitation.accepted_at && !user.archived ->
        conn
        |> put_flash(:error, "Email already exists.")
        |> redirect(to: "/admin/users?role=user")
        |> halt()

      invitation ->
        conn
        |> put_flash(
          :error,
          "#{slug} already invited at this email address. Please wait for invitation acceptance or resend invitation"
        )
        |> redirect(to: "/admin/invitations?role=user")
        |> halt()

      true ->
        assign(conn, :role, Accounts.get_role!(conn.params["data"]["role_id"]))
    end
  end

  def invite_request_path(%{assigns: %{current_user: user}} = conn, path \\ "/admin/invitations") do
    case Flight.Accounts.is_superadmin?(user) do
      true -> "#{path}?school_id=#{Flight.SchoolScope.school_id(conn)}"
      false -> path
    end
  end
end
