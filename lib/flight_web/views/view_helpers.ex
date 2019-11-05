defmodule FlightWeb.ViewHelpers do
  alias FlightWeb.ErrorHelpers

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
      Enum.map(message_list, fn message ->
        "#{Phoenix.Naming.humanize(human_key_transform(key))} #{message}"
      end) ++ acc
    end)
  end

  def human_key_transform(key) do
    case key do
      :medical_expires_at -> :medical_expiration
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

  def display_date(date, :short) do
    Timex.format!(date, "%B %-d, %Y", :strftime)
  end

  def display_date(date, :long) do
    Timex.format!(date, "%A %b %-d, %Y", :strftime)
  end

  def display_time(date) do
    Timex.format!(date, "%-I:%M%p", :strftime)
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
      case Flight.Accounts.StripeAccount.status(stripe_account) do
        :running -> {"badge-success", "Good"}
        _ -> {"badge-danger", "Error"}
      end

    Phoenix.HTML.raw("<span class=\"badge #{class}\">#{text}</span>")
  end

  def display_hour_tenths(tenths) do
    tenths
    |> Flight.Format.hours_from_tenths()
    |> Decimal.new()
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
end
