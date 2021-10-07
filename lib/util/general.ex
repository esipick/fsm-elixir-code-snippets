defmodule Flight.Course do
  defstruct [:id ,:course_name,:start_date ,:summary ,:end_date ,:sort_order ,:is_paid ,:price,:img_url]
end

defmodule Flight.General do
  require Logger

  def get_lms_admin_login_url(current_user) do
    webtoken = Application.get_env(:flight, :webtoken_key) <> "_" <>  to_string(current_user.school.id)
               |>  Flight.Webtoken.encrypt
    encodedWebtoken = Base.encode64(webtoken)

    Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/user_mgt.php?action=login&webtoken=" <> encodedWebtoken <> "&email=" <> current_user.email <> "&username=" <> current_user.email <> "&userid=" <> to_string(current_user.id) <> "&role=catmanager&firstname=" <> current_user.first_name <> "&lastname=" <> current_user.last_name <> "&courseid=0"
  end

  def get_lms_courses(current_user, school_id) do
    webtoken = Flight.Utils.get_webtoken(school_id)
    Logger.info fn -> "webtoken: #{inspect webtoken}" end

    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postBody = Poison.encode!(%{
      "action": "courses_retrieved",
      "webtoken": webtoken
    })

    courses = case HTTPoison.post(url,postBody) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, courses} ->
            for course <- courses do
             %Flight.Course{
               id: Map.get(course, "id"),
               course_name: Map.get(course, "coursename"),
               start_date: Map.get(course, "startdate"),
               summary: Map.get(course, "summary"),
               end_date: Map.get(course, "enddate"),
               sort_order: Map.get(course, "sortorder"),
               is_paid: Map.get(course, "isPaid"),
               price: Map.get(course, "price"),
               img_url: Map.get(course, "img_url"),
              }
             end
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
   Enum.sort_by(courses, fn(course) -> course.sort_order end)
  end

  def get_student_login_url(current_user) do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    encodedWebtoken = Base.encode64(webtoken)
    Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/user_mgt.php?action=login&webtoken=" <> encodedWebtoken <> "&email=" <> current_user.email <> "&username=" <> current_user.email <> "&userid=" <> to_string(current_user.id) <> "&role=catmanager&firstname=" <> current_user.first_name <> "&lastname=" <> current_user.last_name <> "&courseid="
  end
end


