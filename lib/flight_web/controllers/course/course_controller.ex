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
    participant_course = Flight.General.get_course_lesson(current_user, course_id,user_id)
    Logger.info fn -> "course info--------------------------------: #{inspect participant_course}" end

    props = %{
      courseId: course_id,
      participantCourse: participant_course,
      courseProgress: get_course_progress(participant_course),
      userRoles: Flight.Accounts.get_user_roles(conn) |> Enum.map(fn r -> r.slug end)
    }

    render(
      conn,
      "selection.html",
      props: props
    )
  end


  def get_course_progress(participant_course) when is_nil(participant_course), do: 0
  def get_course_progress(participant_course) do
    participant_course.total_lessons_completed || 0
  end

end
