defmodule FlightWeb.ViewHelpers do
  import Flight.Walltime
  alias FlightWeb.ErrorHelpers
  alias Flight.Accounts

  def avatar_url(conn, user) do
    Flight.AvatarUploader.urls({user.avatar, user})[:thumb] ||
      FlightWeb.Router.Helpers.static_path(conn, "/images/avatar.png")
  end

  def format_date(date) when is_binary(date), do: date
  def format_date(nil), do: ""

  def format_date(date) do
    Flight.Date.format(date)
  end

  def is_dev?() do
    Mix.env() == :dev
  end

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)
  end

  def human_error_messages(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn _, _, {message, _} ->
      message
    end)
    |> Enum.reduce([], fn {key, message_list}, acc ->
      humanize_message_list(key, message_list) ++ acc
    end)
  end

  def humanize_message_list(key, message_list) do
    cond do
      is_list(message_list) ->
        Enum.map(message_list, fn message ->
          "#{Phoenix.Naming.humanize(human_key_transform(key))} #{message}"
        end)

      is_map(message_list) ->
        Enum.map(Map.keys(message_list), fn subkey ->
          "#{Phoenix.Naming.humanize(human_key_transform(key))} " <>
            "#{Phoenix.Naming.humanize(human_key_transform(subkey))} " <>
            "#{message_list[subkey]}"
        end)
    end
  end

  def human_error_messages_for_user(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn _, _, {message, _} ->
      message
    end)
    |> Map.take([:user])
    |> Enum.reduce([], fn {key, message_list}, acc ->
      humanize_message_list(key, message_list) ++ acc
    end)
  end

  def human_error_messages_for_user_without_key(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn _, _, {message, _} ->
      message
    end)
    |> Map.take([:user])
    |> Enum.reduce([], fn {_key, message_list}, acc ->
      humanize_message_list_without_key(message_list) ++ acc
    end)
  end

  def humanize_message_list_without_key(message_list) do
    cond do
      is_list(message_list) ->
        Enum.map(message_list, fn message -> "#{message}" end)

      is_map(message_list) ->
        Enum.map(Map.keys(message_list), fn subkey ->
          "#{Phoenix.Naming.humanize(human_key_transform(subkey))} " <>
            "#{message_list[subkey]}"
        end)
    end
  end

  def human_key_transform(key) do
    case key do
      :medical_expires_at -> :medical_expiration
      :zipcode -> :zip_code
      :contact_first_name -> :first_name
      :contact_last_name -> :last_name
      :contact_phone_number -> :phone_number
      :contact_email -> :email
      :rate_per_hour -> :RPH
      :block_rate_per_hour -> :BRPH
      :start_at -> :start_time
      :end_at -> :end_time
      :expiration -> :expiration_date
      :instructor_user_id -> :instructor_id
      other -> other
    end
  end

  def plural_label_for_role(role) do
    case role.slug do
      "admin" -> "Admins"
      "instructor" -> "Instructors"
      "student" -> "Students"
      "renter" -> "Renters"
      "dispatcher" -> "Dispatchers"
    end
  end

  def singular_label_for_role(role) do
    case role.slug do
      "admin" -> "Admin"
      "instructor" -> "Instructor"
      "student" -> "Student"
      "renter" -> "Renter"
      "dispatcher" -> "Dispatcher"
    end
  end

  def display_boolean(boolean) do
    case boolean do
      true -> "Yes"
      false -> "No"
    end
  end

  def currency(amount) do
    Flight.Format.currency(amount)
  end

  def currency(amount, :short) do
    Flight.Format.currency(amount, :short)
  end

  def display_date(date, :student) do
    Timex.format!(date, "%d/%m/%Y", :strftime)
  end

  def display_date(date, :short) do
    Timex.format!(date, "%B %-d, %Y", :strftime)
  end

  def display_date(date, :long) do
    Timex.format!(date, "%A %b %-d, %Y", :strftime)
  end

  def display_walltime_time(date, timezone) do
    utc_to_walltime(date, timezone)
    |> Timex.format!("%-I:%M%p", :strftime)
  end

  def display_walltime_date(date, timezone, format) do
    utc_to_walltime(date, timezone)
    |> display_date(format)
  end

  def display_walltime_datetime(date, timezone) do
    utc_to_walltime(date, timezone)
    |> Timex.format!("%-d %B %-I:%M%p", :strftime)
  end

  def school_name_with_timezone(school) do
    timezone_info = Timex.Timezone.get(school.timezone)
    timezone_info.full_name

    "<span class=\"navbar-brand\" id=\"current-school\" data-school-id=#{school.id}>#{school.name} (#{
      timezone_info.full_name
    } Timezone)</span>"
  end

  def school_select(%{assigns: %{hide_school_info: true}}), do: ""

  def school_select(
        %{
          assigns: %{
            current_user: %{school: %{id: school_id}} = current_user,
            skip_shool_select: true
          }
        } = conn
      ) do
    school =
      case Accounts.is_superadmin?(current_user) do
        true -> Accounts.get_school_with_fallback(conn.req_cookies["school_id"], school_id)
        false -> Accounts.get_school(school_id)
      end

    content = school_name_with_timezone(school)

    Phoenix.HTML.raw(content)
  end

  def school_select(%{assigns: %{current_user: current_user}} = conn) do
    content =
      case Accounts.is_superadmin?(current_user) do
        true ->
          school =
            Accounts.get_school_with_fallback(
              conn.req_cookies["school_id"],
              current_user.school.id
            )

          list_items = Accounts.get_schools_without_selected(school.id)

          case Enum.empty?(list_items) do
            true ->
              school_name_with_timezone(school)

            false ->
              content =
                "<div id=\"schoolSelect\" class=\"form-group\"><button type=\"button\" class=\"btn btn-primary dropdown-toggle\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\">Change school</button><div class=\"dropdown-menu open\" role=\"combobox\">"

              content =
                Enum.reduce(
                  list_items,
                  content,
                  fn item, content ->
                    content <>
                      "<span class=\"dropdown-item\" data-school-id=\"#{item.id}\">#{item.name}</span>"
                  end
                )

              content <>
                "</div></div><div class=\"container-fluid\">" <>
                school_name_with_timezone(school) <>
                "</div><script>require(\"js/admin/school-select.js\")</script>"
          end

        false ->
          school = Accounts.get_school(current_user.school.id)
          "<span class=\"navbar-brand\">#{school.name}</span>"
      end

    Phoenix.HTML.raw(content)
  end

  def display_date(date) do
    display_date(date, :short)
  end

  def aircraft_display_name(aircraft, :short) do
    "#{aircraft.make} #{aircraft.tail_number}"
  end

  def aircraft_display_name(aircraft, :long) do
    "#{aircraft.make} #{aircraft.model} #{aircraft.tail_number}"
  end

  def aircraft_display_name(aircraft) do
    aircraft_display_name(aircraft, :short)
  end

  def display_name(user) do
    "#{user.first_name} #{user.last_name}"
  end

  def display_phone_number(number) do
    Flight.Format.display_phone_number(number)
  end

  def stripe_status_html(stripe_account) do
    {class, text} =
      case Accounts.StripeAccount.status(stripe_account) do
        :running -> {"badge-success", "Good"}
        _ -> {"badge-danger", "Error"}
      end

    Phoenix.HTML.raw("<span class=\"badge #{class}\">#{text}</span>")
  end

  def display_hour_tenths(tenths) do
    tenths
    |> Flight.Format.hours_from_tenths()
    |> Decimal.cast()
    |> Decimal.round(1)
    |> Decimal.to_string()
  end

  def label_for_line_item(line_item) do
    case line_item.type do
      "aircraft" -> "Aircraft"
      "instructor" -> "Instructor"
      "sales_tax" -> "Sales Tax"
      "add_funds" -> "Added Funds"
      "remove_funds" -> "Removed Funds"
      "credit" -> "Credit"
      "custom" -> "Custom"
    end
  end

  def show_to_superadmin?(%{assigns: %{current_user: current_user}}) do
    Accounts.is_superadmin?(current_user)
  end

  def hide_sidebar_for_table(conn) do
    pages = ["/billing/invoices", "/billing/transactions", "/admin/aircrafts"]

    if Enum.member?(pages, conn.request_path) do
      "hide-sidebar-for-table"
    else
      ""
    end
  end
end
