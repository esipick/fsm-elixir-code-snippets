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
    :created_at,
    :img_url
  ]
  @keys ~w(id course_name start_date summary end_date sort_order is_paid price created_at img_url)
  def decode(%{} = map) do
    map
    |> Map.take(@keys)
    |> Enum.map(fn({k, v}) -> {String.to_existing_atom(k), v} end)
    |> Enum.map(&decode/1)
    |> fn(data) -> struct(__MODULE__, data) end.()
  end

  def decode({k, v}), do: {k, v}
end
defmodule Flight.LessonResult do
  defstruct [
    :percentage,
    :ratio
  ]
end

defmodule Flight.CourseResult do
  defstruct [
    :percentage,
    :ratio
  ]
end

defmodule Flight.ApiResult do
  defstruct [
    :status,
    :message,
    participant: Flight.CourseParticipant
  ]
end

defmodule Flight.Content do
  defstruct [
    :type,
    :filename,
    :filepath,
    :filesize,
    :fileurl,
    :timecreated,
    :timemodified,
    :sortorder,
    :userid,
    :author,
    :license,
  ]

  @keys ~w(type filename filepath filesize fileurl timecreated timemodified sortorder userid author license)
  def decode(%{} = map) do
    map
    |> Map.take(@keys)
    |> Enum.map(fn({k, v}) -> {String.to_existing_atom(k), v} end)
    |> Enum.map(&decode/1)
    |> fn(data) -> struct(__MODULE__, data) end.()
  end
  def decode({k, v}), do: {k, v}

end

defmodule Flight.Module do
  defstruct [
    :id,
    :url,
    :name,
    :instance,
    :contextid,
    :visible,
    :uservisible,
    :visibleoncoursepage,
    :modicon,
    :modname,
    :modplural,
    :indent,
    :onclick,
    :afterlink,
    :customdata,
    :noviewlink,
    :completion,
    :completionstate,
    :vieweddate,
    contents: [%Flight.Content{}]
  ]

  @keys ~w(id url name instance contextid visible uservisible visibleoncoursepage modicon modname modplural modplural indent onclick afterlink customdata noviewlink completion completionstate vieweddate contents  )
  def decode(%{} = map) do
    map
    |> Map.take(@keys)
    |> Enum.map(fn({k, v}) -> {String.to_existing_atom(k), v} end)
    |> Enum.map(&decode/1)
    |> fn(data) -> struct(__MODULE__, data) end.()
  end

  def decode({:contents, contents}) when is_list(contents) do
    {:contents, Enum.map(contents, &Flight.Content.decode/1)}
  end

  def decode({k, v}), do: {k, v}
end

defmodule Flight.SubLesson do
  defstruct [
    :id,
    :visible,
    :name,
    :sub_lessontype,
    :summaryformat,
    :section,
    :summary,
    :uservisible,
    :visited,
    :last_visit_datetime,
    :sub_lesson_completed,
    :completed_modules,
    :total_modules,
    :notes,
    :remarks,
     modules: [%Flight.Module{}]
  ]

  @keys ~w(id visible name sub_lessontype summaryformat section summary uservisible visited last_visit_datetime sub_lesson_completed completed_modules total_modules  notes remarks modules)
  def decode(%{} = map) do
    map
    |> Map.take(@keys)
    |> Enum.map(fn({k, v}) -> {String.to_existing_atom(k), v} end)
    |> Enum.map(&decode/1)
    |> fn(data) -> struct(__MODULE__, data) end.()
  end

  def decode({:modules, modules}) when is_list(modules) do
    {:modules, Enum.map(modules, &Flight.Module.decode/1)}
  end

  def decode({k, v}), do: {k, v}
end

defmodule Flight.Lesson do
  defstruct [
    :id,
    :name,
    :section_id,
    :summary,
    :lesson_completed,
    :lesson_complete_status,
    :completed_sub_lessons,
    :total_sub_lessons,
    sub_lessons: [%Flight.SubLesson{}]
  ]

  @keys ~w(id name name section_id summary lesson_completed  lesson_complete_status completed_sub_lessons total_sub_lessons sub_lessons)
  def decode(%{} = map) do
    map
    |> Map.take(@keys)
    |> Enum.map(fn({k, v}) -> {String.to_existing_atom(k), v} end)
    |> Enum.map(&decode/1)
    |> fn(data) -> struct(__MODULE__, data) end.()
  end

  def decode({:sub_lessons, sub_lessons}) when is_list(sub_lessons) do
    {:sub_lessons, Enum.map(sub_lessons, &Flight.SubLesson.decode/1)}
  end

  def decode({k, v}), do: {k, v}
end

defmodule Flight.CourseParticipant do
  defstruct [
    :user_id,
    :fsm_user_id,
    :first_name,
    :last_name,
    :token,
    :course_completed,
    :completed_lessons,
    :total_lessons,
    :total_lessons_completed,
    lessons: [%Flight.Lesson{}]
  ]

  @keys ~w(user_id fsm_user_id first_name last_name token course_completed completed_lessons total_lessons total_lessons_completed lessons)
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
    :sort_order,
    :course_name,
    :start_date,
    :end_date,
    :summary,
    :price,
    :total_lessons,
    :image_url,
    :is_paid,
    participants: [%Flight.CourseParticipant{}]
  ]

  @keys ~w(id sort_order course_name start_date end_date summary price total_lessons image_url is_paid participants)
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
  def get_course_info(current_user, course_id)do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postBody = Poison.encode!(%{
      "action": "get_course_v2",
      "webtoken": webtoken,
      "courseid": course_id
    })

    #Logger.info fn -> "postBody: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]

    course = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        case Poison.decode(body) do
          {:ok, course} ->
            %Flight.CourseDetail{
              id: Map.get(course, "id"),
              price: Map.get(course, "price"),
            }
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end

  end

  def get_lms_admin_login_url(current_user) do
    webtoken = Application.get_env(:flight, :webtoken_key) <> "_" <>  to_string(current_user.school.id)
               |>  Flight.Webtoken.encrypt
    encodedWebtoken = Base.encode64(webtoken)

    Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/user_mgt.php?action=login&webtoken=" <> encodedWebtoken <> "&email=" <> current_user.email <> "&username=" <> current_user.email <> "&userid=" <> to_string(current_user.id) <> "&role=catmanager&firstname=" <> current_user.first_name <> "&lastname=" <> current_user.last_name <> "&courseid=0"
  end

  def get_school_lms_courses(school_id) do
    webtoken = Flight.Utils.get_webtoken(school_id)
    #Logger.info fn -> "webtoken: #{inspect webtoken}" end

    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postBody = Poison.encode!(%{
      "action": "courses_retrieved",
      "webtoken": webtoken
    })
    options = [timeout: 150_000, recv_timeout: 150_000]

    courses = case HTTPoison.post(url,postBody, [],options) do
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
                created_at: Map.get(course, "created_at"),
                price: Map.get(course, "price"),
                img_url: Map.get(course, "img_url"),
              }
            end
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def get_lms_courses(current_user, isAdmin) do
    if  Flight.General.is_lms_beta_school(current_user) do
        courses = get_school_lms_courses(current_user.school_id)

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
      else
        []
    end

  end

  def get_course_detail(current_user, course_id)do
    if  Flight.General.is_lms_beta_school(current_user) do
      webtoken = Flight.Utils.get_webtoken(current_user.school_id)
      url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
      postBody = Poison.encode!(%{
        "action": "get_course_structure",
        "webtoken": webtoken,
        "courseid": course_id
      })

      # Logger.info fn -> "postBody: #{inspect postBody}" end
      options = [timeout: 150_000, recv_timeout: 150_000]

      course = case HTTPoison.post(url,postBody, [],options) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

          case Poison.decode(body) do
            {:ok, course} ->
              Flight.CourseDetail.decode(course)
            {:error, error} -> error
          end
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          []
        {:error, %HTTPoison.Error{reason: reason}} ->
          # Logger.info fn -> "reason: #{inspect reason}" end
          []
      end
    else
      %{}
    end

  end

  def get_course_lesson(current_user, course_id, lms_user_id)do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postBody = Poison.encode!(%{
      "action": "get_user_course_lessons",
      "webtoken": webtoken,
      "courseid": course_id,
      "userid": lms_user_id
    })

    #Logger.info fn -> "postBody: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]
    participant = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        case Poison.decode(body) do
          {:ok, participant} ->
            Flight.CourseParticipant.decode(participant)
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def get_course_participants(current_user, course_id)do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postBody = Poison.encode!(%{
      "action": "get_course_participants",
      "webtoken": webtoken,
      "courseid": course_id
    })

    #Logger.info fn -> "postBody: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]
    course = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        case Poison.decode(body) do
          {:ok, course} ->
            Flight.CourseDetail.decode(course)
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def insert_lesson_sub_lesson_remarks(current_user,attrs)do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    teacher_mark =  case Map.has_key?(attrs, :teacher_mark) do
      true->
        attrs.teacher_mark
      false->
      nil
    end
    note =  case Map.has_key?(attrs, :note) do
      true->
        attrs.note
      false->
        nil
    end
    postBody = Poison.encode!(%{
      "action": "insert_lesson_sublesson_remarks",
      "webtoken": webtoken,
      "courseid": attrs.course_id,
      "teachermark": teacher_mark ,
      "note": note,
      "sub_lesson_id": attrs.sub_lesson_id,
      "userid": attrs.fsm_user_id
    })

    #Logger.info fn -> "postBody: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]
    course = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        case Poison.decode(body) do
          {:ok, result} ->

            #Logger.info fn -> "result: #{inspect result}" end

            participant = Map.get(result, "participant")

            participant = if(!is_nil(participant)) do
              [participant | _] = participant
              Flight.CourseParticipant.decode(participant)
            end

            %Flight.ApiResult{
              status: Map.get(result, "status"),
              message: Map.get(result, "message"),
              participant: participant || %Flight.CourseParticipant{}
            }
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def insert_lesson_sub_lesson_remarks_v2(current_user,attrs)do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    teacher_mark =  case Map.has_key?(attrs, :teacher_mark) do
      true->
        attrs.teacher_mark
      false->
        nil
    end
    note =  case Map.has_key?(attrs, :note) do
      true->
        attrs.note
      false->
        nil
    end
    postBody = Poison.encode!(%{
      "action": "insert_lesson_sublesson_remarks_v2",
      "webtoken": webtoken,
      "courseid": attrs.course_id,
      "teachermark": teacher_mark ,
      "note": note,
      "sub_lesson_id": attrs.sub_lesson_id,
      "userid": attrs.fsm_user_id
    })

    #Logger.info fn -> "postBody: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]
    course = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        case Poison.decode(body) do
          {:ok, result} ->

            #Logger.info fn -> "result: #{inspect result}" end

            participant = Map.get(result, "participant")

            participant = if(!is_nil(participant)) do
              [participant | _] = participant
              Flight.CourseParticipant.decode(participant)
            end

            %Flight.ApiResult{
              status: Map.get(result, "status"),
              message: Map.get(result, "message")
            }
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def insert_lesson_sub_lesson_remarks_v3(current_user,attrs)do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    teacher_mark =  case Map.has_key?(attrs, :teacher_mark) do
      true->
        attrs.teacher_mark
      false->
        nil
    end
    note =  case Map.has_key?(attrs, :note) do
      true->
        attrs.note
      false->
        nil
    end
    postBody = Poison.encode!(%{
      "action": "insert_lesson_sublesson_remarks_v2",
      "webtoken": webtoken,
      "courseid": attrs.course_id,
      "teachermark": teacher_mark ,
      "note": note,
      "sub_lesson_id": attrs.sub_lesson_id,
      "userid": attrs.fsm_user_id,
      "lessonid": attrs.lesson_id,
      "lesson_section_id": attrs.lesson_section_id
    })

    #Logger.info fn -> "postBody: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]
    course = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        case Poison.decode(body) do
          {:ok, result} ->

            #Logger.info fn -> "result: #{inspect result}" end

            participant = Map.get(result, "participant")

            participant = if(!is_nil(participant)) do
              [participant | _] = participant
              Flight.CourseParticipant.decode(participant)
            end

            %Flight.ApiResult{
              status: Map.get(result, "status"),
              message: Map.get(result, "message")
            }
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def add_course_module_view_remarks(current_user,attrs)do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    userid =  case Map.has_key?(attrs, :fsm_user_id) do
      true->
        attrs.fsm_user_id
      false->
        current_user.id
    end
    postBody = Poison.encode!(%{
      "action": "insert_coursemodule_viewed",
      "webtoken": webtoken,
      "courseid": attrs.course_id,
      "coursemoduleid": attrs.course_module_id,
      "userid": userid,
      "operation": attrs.action
    })

    #Logger.info fn -> "postBody: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]
    course = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        case Poison.decode(body) do
          {:ok, result} ->

            %Flight.ApiResult{
              status: Map.get(result, "status"),
              message: Map.get(result, "message")
            }
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def enroll_student(current_user, course_id) do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/user_mgt.php"
    isAdmin =  Authorization.is_admin?(current_user)
    role = if (isAdmin) do
      "catmanager"
      else
      "student"
    end
    postBody = Poison.encode!(%{
      "action": "login",
      "webtoken": webtoken,
      "email": current_user.email ,
      "username": current_user.email ,
      "userid": current_user.id ,
      "role": role,
      "firstname": current_user.first_name,
      "lastname": current_user.last_name,
      "courseid": [course_id],
    })

    # Logger.info fn -> "postBody11111111111111111111111111111111111111111111111111: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]
    course = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        case Poison.decode(body) do
          {:ok, result} ->
            result
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def get_student_login_url(current_user) do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    encodedWebtoken = Base.encode64(webtoken)
    Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/user_mgt.php?action=login&webtoken=" <> encodedWebtoken <> "&email=" <> current_user.email <> "&username=" <> current_user.email <> "&userid=" <> to_string(current_user.id) <> "&role=student&firstname=" <> current_user.first_name <> "&lastname=" <> current_user.last_name <> "&courseid="
  end

  def is_lms_beta_school(current_user) do
    if Application.get_env(:flight, :enable_lms_for_all) == "NO" do
      if current_user.school_id in Application.get_env(:flight, :lms_beta_schools_ids, []) do
       true
      else
        false
      end
    else
      true
    end
  end

  def create_category_at_lms(school) do
    webtoken = Flight.Utils.get_webtoken(school.id)

    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postData=%{
      "action": "category_creation",
      "name": school.name,
      "webtoken": webtoken
    }

    postBody = Poison.encode!(postData)
    #Logger.info fn -> "url: #{inspect url}" end
    #Logger.info fn -> "postData: #{inspect postData}" end
    category = case HTTPoison.post(url,postBody) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, category} ->category
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def get_participant_course_lessons(current_user, course_id, fsm_or_lms_user_id)do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postBody = Poison.encode!(%{
      "action": "get_user_course_lessons_v2",
      "webtoken": webtoken,
      "courseid": course_id,
      "userid": fsm_or_lms_user_id
    })

    #Logger.info fn -> "postBody: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]
    participant = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, participant} ->
            Flight.CourseParticipant.decode(participant)
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def get_participant_course_sub_lessons(current_user, course_id, lms_user_id, section_id)do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postBody = Poison.encode!(%{
      "action": "get_user_course_sub_lessons",
      "webtoken": webtoken,
      "courseid": course_id,
      "userid": lms_user_id,
      "section_id": section_id
    })

    #Logger.info fn -> "postBody: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]
    sub_lessons = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, sub_lessons} ->
            #Logger.info fn -> "sub_lesson: #{inspect sub_lessons}" end
            sub_lessons
            |> Enum.map(fn sub_lesson ->
              %Flight.SubLesson{
                id: Map.get(sub_lesson, "id"),
                visible: Map.get(sub_lesson, "visible"),
                name: Map.get(sub_lesson, "name"),
                summary: Map.get(sub_lesson, "summary"),
                sub_lessontype: Map.get(sub_lesson, "sub_lessontype"),
                sub_lesson_completed: Map.get(sub_lesson, "sub_lesson_completed"),
                completed_modules: Map.get(sub_lesson, "completed_modules"),
                total_modules: Map.get(sub_lesson, "total_modules"),
                notes: Map.get(sub_lesson, "notes"),
                remarks: Map.get(sub_lesson, "remarks"),
              }
            end)

          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def get_participant_course_sub_lesson_modules(current_user, course_id, lms_user_id, sub_lesson_id) do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postBody = Poison.encode!(%{
      "action": "get_user_sub_lessons_modules",
      "webtoken": webtoken,
      "courseid": course_id,
      "userid": lms_user_id,
      "sub_lesson_id": sub_lesson_id
    })

    #Logger.info fn -> "postBody: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]
    sub_lesson_modules = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, sub_lesson_modules} ->

            sub_lesson_modules
            |> Enum.map(fn sub_lesson_module ->
              %Flight.Module{
                id: Map.get(sub_lesson_module, "id"),
                url: Map.get(sub_lesson_module, "url"),
                name: Map.get(sub_lesson_module, "name"),
                modicon: Map.get(sub_lesson_module, "modicon"),
                modname: Map.get(sub_lesson_module, "modname"),
                completionstate: Map.get(sub_lesson_module, "completionstate"),
                vieweddate: Map.get(sub_lesson_module, "vieweddate"),
                contents: Enum.map(Map.get(sub_lesson_module, "contents"), &Flight.Content.decode/1) ,
              }
            end)
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end

  def update_lesson_status(current_user,attrs)do
    webtoken = Flight.Utils.get_webtoken(current_user.school_id)
    url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
    postBody = Poison.encode!(%{
      "action": "insert_user_lesson_status",
      "webtoken": webtoken,
      "status": attrs.status ,
      "lessonid": attrs.lesson_id,
      "userid": attrs.lms_user_id
    })

    #Logger.info fn -> "postBody: #{inspect postBody}" end
    options = [timeout: 150_000, recv_timeout: 150_000]
    course = case HTTPoison.post(url,postBody, [],options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        case Poison.decode(body) do
          {:ok, result} ->

            #Logger.info fn -> "result: #{inspect result}" end

            %Flight.ApiResult{
              status: Map.get(result, "status"),
              message: Map.get(result, "message")
            }
          {:error, error} -> error
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        #Logger.info fn -> "reason: #{inspect reason}" end
        []
    end
  end


end
