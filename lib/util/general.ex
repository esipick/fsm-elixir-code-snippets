defmodule Flight.Course do
  defstruct [
    :id,
    :course_name,
    :start_date,
    :summary,
    :end_date,
    :sort_order,
    :is_paid,
    :price,
    :img_url
  ]
  @keys ~w(id course_name start_date summary end_date sort_order is_paid price img_url)
  def decode(%{} = map) do
    map
    |> Map.take(@keys)
    |> Enum.map(fn({k, v}) -> {String.to_existing_atom(k), v} end)
    |> Enum.map(&decode/1)
    |> fn(data) -> struct(__MODULE__, data) end.()
  end

  def decode({k, v}), do: {k, v}
end


defmodule Flight.ChecklistObjective do
  defstruct [
    :objective_id,
    :name,
    :comment,
    :remarks
  ]
  @keys ~w(objective_id name comment remarks)
  def decode(%{} = map) do
    map
    |> Map.take(@keys)
    |> Enum.map(fn({k, v}) -> {String.to_existing_atom(k), v} end)
    |> Enum.map(&decode/1)
    |> fn(data) -> struct(__MODULE__, data) end.()
  end

  def decode({k, v}), do: {k, v}
end

defmodule Flight.Checklist do
  defstruct [
    :id,
    :name,
    checklist_objectives: [%Flight.ChecklistObjective{}]
  ]

  @keys ~w(id name checklist_objectives)
  def decode(%{} = map) do
    map
    |> Map.take(@keys)
    |> Enum.map(fn({k, v}) -> {String.to_existing_atom(k), v} end)
    |> Enum.map(&decode/1)
    |> fn(data) -> struct(__MODULE__, data) end.()
  end

  def decode({:checklist_objectives, objectives}) when is_list(objectives) do
    {:checklist_objectives, Enum.map(objectives, &Flight.ChecklistObjective.decode/1)}
  end
  def decode({k, v}), do: {k, v}

end

defmodule Flight.Lesson do
  defstruct [
    :id,
    :visible,
    :summary,
    :summaryformat,
    :section,
    :uservisible,
    :visited,
    :last_visit_datetime,
    :completed,
    checklists: [%Flight.Checklist{}]
  ]

  @keys ~w(id visible summary summaryformat section uservisible visited last_visit_datetime completed checklists)
  def decode(%{} = map) do
    map
    |> Map.take(@keys)
    |> Enum.map(fn({k, v}) -> {String.to_existing_atom(k), v} end)
    |> Enum.map(&decode/1)
    |> fn(data) -> struct(__MODULE__, data) end.()
  end

  def decode({:checklists, checklists}) when is_list(checklists) do
    {:checklists, Enum.map(checklists, &Flight.Checklist.decode/1)}
  end

  def decode({k, v}), do: {k, v}
end

defmodule Flight.CourseParticipant do
  defstruct [
    :user_id,
    :first_name,
    :last_name,
    lessons: [%Flight.Lesson{}]
  ]

  @keys ~w(user_id first_name last_name lessons)
  def decode(%{} = map) do
    map 
    |> Map.take(@keys)
    |> Enum.map(fn({k, v}) -> {String.to_existing_atom(k), v} end)
    |> Enum.map(&decode/1)
    |> fn(data) -> struct(__MODULE__, data) end.()
  end

  def decode({:lessons, lessons}) when is_list(lessons) do
    {:lessons, Enum.map(lessons, &Flight.Lesson.decode/1)}
  end

  def decode({k, v}), do: {k, v}
end

defmodule Flight.CourseDetail do
  defstruct [
    :id,
    :course_name,
    :start_date,
    :summary,
    :end_date,
    :sort_order,
    :is_paid,
    :price,
    :image_url,
    participants: [%Flight.CourseParticipant{}]
  ]

  @keys ~w(id course_name start_date summary end_date sort_order is_paid price image_url participants)
  def decode(%{} = map) do
    map
    |> Map.take(@keys)
    |> Enum.map(fn({k, v}) -> {String.to_existing_atom(k), v} end)
    |> Enum.map(&decode/1)
    |> fn(data) -> struct(__MODULE__, data) end.()
  end

  def decode({:participants, participants}) when is_list(participants) do
    {:participants, Enum.map(participants, &Flight.CourseParticipant.decode/1)}
  end

  def decode({k, v}), do: {k, v}
end


defmodule Flight.General do
  require Logger
  alias Flight.Auth.Authorization
  alias Flight.Billing.{Invoice, InvoiceCustomLineItem}
  alias Flight.Repo

  def get_lms_admin_login_url(current_user) do
    webtoken = Application.get_env(:flight, :webtoken_key) <> "_" <>  to_string(current_user.school.id)
               |>  Flight.Webtoken.encrypt
    encodedWebtoken = Base.encode64(webtoken)

    Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/user_mgt.php?action=login&webtoken=" <> encodedWebtoken <> "&email=" <> current_user.email <> "&username=" <> current_user.email <> "&userid=" <> to_string(current_user.id) <> "&role=catmanager&firstname=" <> current_user.first_name <> "&lastname=" <> current_user.last_name <> "&courseid=0"
  end

  def get_lms_courses(current_user, isAdmin) do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
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

    #get course payment information from DB
    invoices = Flight.Queries.Invoice.course_invoices(current_user.id)
               |> Repo.all()

    course_ids = Enum.map(invoices, fn (invoice) ->
      invoice.course_id
    end)

    updated_courses = Enum.map(courses, fn (course) ->
      case isAdmin do
        true->
          course
          |> Map.put(:is_paid, true)
        false->
          if Enum.any?(course_ids, fn(id)-> id == Map.get(course, :id) end) do
            course
            |> Map.put(:is_paid, true)
          else
            course
            |> Map.put(:is_paid, false)
          end
      end
    end)

    Enum.sort_by(updated_courses, fn(course) -> course.sort_order end)
  end

  def get_course_detail(current_user, course_id)do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postBody = Poison.encode!(%{
      "action": "get_course_structure",
      "webtoken": "amgE48/4ft/3zwKw0nwwbPoE8zep5s5OeX+9bRpGYY4=",
      "courseid": course_id
    })
    
    Logger.info fn -> "postBody: #{inspect postBody}" end

    course = case HTTPoison.post(url,postBody) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        case Poison.decode(body) do
          {:ok, course} ->
            Logger.info fn -> "postBody: #{inspect Flight.CourseDetail.decode(course)}" end
            Flight.CourseDetail.decode(course)
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def get_student_login_url(current_user) do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    encodedWebtoken = Base.encode64(webtoken)
    Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/user_mgt.php?action=login&webtoken=" <> encodedWebtoken <> "&email=" <> current_user.email <> "&username=" <> current_user.email <> "&userid=" <> to_string(current_user.id) <> "&role=catmanager&firstname=" <> current_user.first_name <> "&lastname=" <> current_user.last_name <> "&courseid="
  end
end