defmodule FlightWeb.Course.CourseController do
  use FlightWeb, :controller
  alias Flight.Auth.Authorization
  alias Flight.Billing.{Invoice, InvoiceCustomLineItem}
  alias Flight.Repo
  require Logger
  def index(%{assigns: %{current_user: current_user}} = conn, _) do
    Logger.info fn -> "Authorization.is_admin?(current_user): #{inspect Authorization.is_admin?(current_user)}" end
    adminLoginUrl =  case  Authorization.is_admin?(current_user) do
      true->
        Flight.General.get_lms_admin_login_url(current_user)
      false->
        nil
    end
    Logger.info fn -> "adminLoginUrl: #{inspect adminLoginUrl}" end

    loginUrl = Flight.General.get_student_login_url(current_user)

    courses = Flight.General.get_lms_courses(current_user, current_user.school_id)

    Logger.info fn -> "loginUrl: #{inspect loginUrl}" end
    Logger.info fn -> "courses: #{inspect courses}" end

    #get course payment information from DB
    invoices = Flight.Queries.Invoice.course_invoices(current_user.id)
               |> Repo.all()

    course_ids = Enum.map(invoices, fn (invoice) ->
      invoice.course_id
    end)

    updated_courses = Enum.map(courses, fn (course) ->
      if Enum.any?(course_ids, fn(id)-> id == Map.get(course, :id) end) do
        course
        |> Map.put(:is_paid, true)
      else
        course
        |> Map.put(:is_paid, false)
      end
    end)

    Logger.info fn -> "courses: #{inspect courses}" end
    Logger.info fn -> "updated_courses: #{inspect updated_courses}" end


    render(conn, "index.html",
      courses: updated_courses,
      login_url: loginUrl,
      admin_login_url: adminLoginUrl,
      is_admin: Authorization.is_admin?(current_user)
    )
  end


end
