defmodule FsmWeb.GraphQL.Courses.CoursesTypes do
    use Absinthe.Schema.Notation
  
    alias FsmWeb.GraphQL.Middleware
    alias FsmWeb.GraphQL.Courses.CoursesResolvers

    #Enums
    enum(:action, values: [:read, :unread])

    # Queries
    object :courses_queries do
        @desc "Get Courses"
        field :get_courses, list_of(:course) do
            resolve &CoursesResolvers.get_courses/3
        end
        @desc "Get Course detail data"
        field :get_course, :course_detail do
            arg :id, non_null(:id)
            resolve &CoursesResolvers.get_course/3
        end
        @desc "Get Course participants"
        field :get_course_participants, :course_detail do
            arg :course_id, non_null(:id)
            resolve &CoursesResolvers.get_course_participants/3
        end

        @desc "Get Course lesson detail"
        field :get_course_lesson, :participant do
            arg :course_id, non_null(:id)
            arg :lms_user_id, non_null(:id)
            resolve &CoursesResolvers.get_course_lesson/3
        end
    end
    object :courses_mutations do
        @desc "Insert sub lesson Remarks"
        field :sub_lesson_remarks, :checklist_objective_remarks do
            arg :remark_input, non_null(:remark_input)
            resolve &CoursesResolvers.insert_lesson_sub_lesson_remarks/3
        end

        @desc "Insert course module view"
        field :add_course_module_view, :input_course_module_view_response do
            arg :input_course_module_view, non_null(:input_course_module_view)
            resolve &CoursesResolvers.add_course_module_view/3
        end
    end

    input_object :remark_input do
        field(:course_id,  non_null(:id))
        field(:teacher_mark, :integer)
        field(:fsm_user_id, non_null(:integer))
        field(:sub_lesson_id, :integer)
        field(:note, :string)
    end
    input_object :input_course_module_view do
        field(:course_id,  non_null(:id))
        field(:course_module_id,  non_null(:id))
        field(:action,  non_null(:action))
    end

    # Types
    object :checklist_objective_remarks do
        field :status, :string
        field :message, :string
        field :participant, :participant
    end
    object :input_course_module_view_response do
        field :status, :string
        field :message, :string
        field :operation, :string
    end
    object :cumulative_results_course_level do
        field :ratio, :string
        field :percentage, :string
    end
    object :cumulative_results_lesson_level do
        field :ratio, :string
        field :percentage, :string
    end
    object :course do
        field :id, :integer
        field :course_name, :string
        field :start_date, :string
        field :summary, :string
        field :end_date, :string
        field :price, :float
        field :is_paid, :boolean
        field :img_url, :string
        field :sort_order, :string
    end
    object :course_detail do
        field :id, :integer
        field :sort_order, :integer
        field :course_name, :string
        field :start_date, :string
        field :end_date, :string
        field :summary, :string
        field :price, :decimal
        field :total_lessons, :integer
        field :image_url, :string
        field :participants, list_of(:participant)

    end
    object :participant do
        field :user_id, :integer
        field :fsm_user_id, :string
        field :first_name, :string
        field :last_name, :string
        field :token, :string
        field :course_completed, :boolean
        field :completed_lessons, :integer
        field :total_lessons, :integer
        field :total_lessons_completed, :integer
        field :lessons, list_of(:lesson)
    end
    object :lesson do
        field :id, :integer
        field :name, :string
        field :summary, :string
        field :lesson_completed, :boolean
        field :completed_sub_lessons, :integer
        field :total_sub_lessons, :integer
        field :sub_lessons, list_of(:sub_lesson)
    end
    object :sub_lesson do
        field :id, :integer
        field :name, :string
        field :visible, :integer
        field :sub_lessontype, :string
        field :summaryformat, :string
        field :section, :integer
        field :uservisible, :boolean
        field :visited, :boolean
        field :last_visit_datetime, :string
        field :sub_lesson_completed, :boolean
        field :completed_modules, :integer
        field :total_modules, :integer
        field :notes, :string
        field :remarks, :string
        field :modules, list_of(:module)
    end
    object :module do
        field :id, :integer
        field :url, :string
        field :name, :string
        field :instance, :integer
        field :contextid, :integer
        field :visible, :integer
        field :uservisible, :boolean
        field :visibleoncoursepage, :integer
        field :modicon, :string
        field :modname, :string
        field :modplural, :string
        field :availability, :string
        field :indent, :integer
        field :onclick, :string
        field :afterlink, :string
        field :customdata, :string
        field :noviewlink, :boolean
        field :completion, :integer
        field :completionstate, :boolean
        field :vieweddate, :string
        field :contents, list_of(:content)
    end

    object :content do
        field :type, :string
        field :filename, :string
        field :filepath, :string
        field :filesize, :integer
        field :fileurl, :string
        field :timecreated, :integer
        field :timemodified, :integer
        field :sortorder, :integer
        field :userid, :string
        field :author, :string
        field :license, :string
    end
    object :course_data do
        field :courses, list_of(:course)
    end


end
