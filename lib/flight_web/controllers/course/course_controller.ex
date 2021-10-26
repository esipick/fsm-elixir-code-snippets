defmodule FlightWeb.Course.CourseController do
  use FlightWeb, :controller
  alias Flight.Auth.Authorization
  alias Flight.Billing.{Invoice, InvoiceCustomLineItem}
  alias Flight.Repo
  require Logger

  def index(%{assigns: %{current_user: current_user}} = conn, _) do

    isAdmin =  Authorization.is_admin?(current_user)
    staff_member =  Authorization.staff_member?(current_user)
    Logger.info fn -> "staff_member:-----------------------=============================== #{inspect staff_member}" end
    adminLoginUrl =  case  isAdmin do
      true->
        Flight.General.get_lms_admin_login_url(current_user)
      false->
        nil
    end
    Logger.info fn -> "adminLoginUrl: #{inspect adminLoginUrl}" end

    loginUrl = Flight.General.get_student_login_url(current_user)
    courses = Flight.General.get_lms_courses(current_user, isAdmin)

    Logger.info fn -> "loginUrl: #{inspect loginUrl}" end
    Logger.info fn -> "courses: #{inspect courses}" end


    render(conn, "index.html",
      courses: courses,
      login_url: loginUrl,
      admin_login_url: adminLoginUrl,
      is_admin: isAdmin,
      staff_member: staff_member
    )
  end

  def participants(%{assigns: %{current_user: current_user}} = conn, %{"course_id" => course_id}) do
    course_details = Flight.General.get_course_detail(current_user, course_id)
    Logger.info fn -> "course_details: #{inspect course_details}" end
    render(
     conn,
    "participants.html",
    course_details: course_details
    )
  end

  def participant_info(conn, _) do
    render(
      conn,
      "participant_info.html"
    )
  end

  def selection(%{assigns: %{current_user: current_user}} = conn, %{"course_id" => course_id, "user_id" => user_id}) do
    selections = Flight.General.get_course_lesson(current_user, course_id,user_id)
    Logger.info fn -> "selections--------------------------------: #{inspect selections.lessons}" end
    render(
      conn,
      "selection.html",
      lessons: selections.lessons
    )
  end

end
