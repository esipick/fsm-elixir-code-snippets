defmodule FlightWeb.Course.CourseController do
  use FlightWeb, :controller
  alias Flight.Auth.Authorization
  alias Flight.Billing.{Invoice, InvoiceCustomLineItem}
  require Logger

  def index(%{assigns: %{current_user: current_user}} = conn, _) do
    is_lms_beta_school = Flight.General.is_lms_beta_school(current_user)
    isAdmin =  Authorization.is_admin?(current_user)
    staff_member =  Authorization.staff_member?(current_user)
    #Logger.info fn -> "staff_member:-----------------------=============================== #{inspect staff_member}" end
    adminLoginUrl =  case  isAdmin &&  is_lms_beta_school do
      true->
        Flight.General.get_lms_admin_login_url(current_user)
      false->
        nil
    end
    #Logger.info fn -> "adminLoginUrl: #{inspect adminLoginUrl}" end
    loginUrl = Flight.General.get_student_login_url(current_user)
    courses =   Flight.General.get_lms_courses(current_user, isAdmin)
    #Logger.info fn -> "loginUrl: #{inspect loginUrl}" end
    #Logger.info fn -> "courses: #{inspect courses}" end
    IO.inspect(courses, label: "courses")

    render(conn, "index.html",
      courses: courses,
      login_url: loginUrl,
      admin_login_url: adminLoginUrl,
      is_admin: isAdmin,
      staff_member: staff_member
    )
  end

  def participants(%{assigns: %{current_user: current_user}} = conn, %{"course_id" => course_id}) do
    course_details = Flight.General.get_course_participants(current_user, course_id)
    #Logger.info fn -> "course_details11111111111: #{inspect course_details}" end
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

    participant_course = Flight.General.get_participant_course_lessons(current_user, course_id, user_id)

    #Logger.info fn -> "course info--------------------------------: #{inspect participant_course}" end

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

  def course_detail(%{assigns: %{current_user: current_user}} = conn, %{"course_id" => course_id}) do
    # create moodle user id using fsm user id
    user_id = "fsm2m" <> to_string(current_user.id)

    participant_course = Flight.General.get_participant_course_lessons(current_user, course_id, user_id)

    #Logger.info fn -> "course info--------------------------------: #{inspect participant_course}" end
    if participant_course.completed_lessons == nil do

      render(
        conn,
        "error.html",
        error_message: "You haven't purchased any course."
      )
    else
      props = %{
        courseId: course_id,
        participantCourse: participant_course,
        courseProgress: get_course_progress(participant_course),
        userRoles: ["student", "renter"]
      }

      render(
        conn,
        "selection.html",
        props: props
      )
    end

  end


  def get_course_progress(participant_course) when is_nil(participant_course), do: 0
  def get_course_progress(participant_course) do
    participant_course.total_lessons_completed || 0
  end

  def get_user_courses_progress(current_user) do
    courses_info =  Flight.General.get_lms_courses(current_user, false)
               |> Enum.filter(fn course -> course.is_paid end)
               |>  Enum.map(fn course ->
                      user_id = "fsm2m" <> to_string(current_user.id)
                      participant_course = Flight.General.get_participant_course_lessons(current_user, course.id, user_id)

                      course_info = %{
                        id: course.id,
                        course_name: course.course_name,
                        progress: get_course_progress(participant_course)
                      }
                      course_info
                  end)
  #  courses_info = Enum.map(courses, fn course ->
  #                    participant_course = Flight.General.get_participant_course_lessons(current_user, course.id, current_user.id)
  #                    course_info = %{
  #                      id: course.id,
  #                      course_name: course.course_name,
  #                      progress: get_course_progress(participant_course)
  #                    }
  #                    course_info
  #                 end)
   courses_info
  end

end
