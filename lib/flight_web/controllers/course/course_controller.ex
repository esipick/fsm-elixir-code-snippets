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
        Flight.General.getLSMLoginUrl(current_user.school,current_user)
      false->
      nil
    end
    Logger.info fn -> "adminLoginUrl: #{inspect adminLoginUrl}" end

    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    encodedWebtoken = Base.encode64(webtoken)

    loginUrl = Application.get_env(:flight, :lms_endpoint)
      <>"/auth/fsm2moodle/user_mgt.php?action=login&webtoken="
      <> encodedWebtoken
      <> "&email="
      <> current_user.email
      <> "&username="
      <> current_user.email
      <> "&userid="
      <> to_string(current_user.id)
      <> "&role=student&firstname="
      <> current_user.first_name
      <> "&lastname="
      <> current_user.last_name
      <> "&courseid="

   Logger.info fn -> "loginUrl: #{inspect loginUrl}" end
   Logger.info fn -> "webtoken: #{inspect webtoken}" end
   Logger.info fn -> "current_user: #{inspect current_user}" end

    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postBody = Poison.encode!(%{
      "action": "courses_retrieved",
      "webtoken": webtoken
    })

    courses = case HTTPoison.post(url,postBody) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, courses} ->
            # we're getting a list of length 1 for "courses" key
            [courses | _] = Map.get(courses, "courses")
            courses |> Enum.map(fn ({id, course}) -> course end)
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
       []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.info fn -> "reason: #{inspect reason}" end
       []
    end

    Logger.info fn -> "courses: #{inspect courses}" end

#get course payment information from DB
  invoices = Flight.Queries.Invoice.course_invoices(current_user.id)
              |> Repo.all()

  course_ids = Enum.map(invoices, fn (invoice) ->
    invoice.course_id
  end)

    updated_courses = Enum.map(courses, fn (course) ->

      if Enum.any?(course_ids, fn(id)-> id == Map.get(course, "id") end) do
        course
        |> Map.put("isPaid", true)
      else
        course
        |> Map.put("isPaid", false)
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
