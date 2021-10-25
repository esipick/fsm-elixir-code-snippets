defmodule FsmWeb.GraphQL.Courses.CoursesTypes do
    use Absinthe.Schema.Notation
  
    alias FsmWeb.GraphQL.Middleware
    alias FsmWeb.GraphQL.Courses.CoursesResolvers

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
        @desc "Get Cumulative Results_lesson_level"
        field :get_cumulative_results_lesson_level, :cumulative_results_lesson_level do
            arg :course_id, non_null(:id)
            arg :lesson_id, non_null(:id)
            resolve &CoursesResolvers.get_cumulative_results_lesson_level/3
        end
        @desc "Get Cumulative Results_course_level"
        field :get_cumulative_results_course_level, :cumulative_results_course_level do
            arg :course_id, non_null(:id)
            resolve &CoursesResolvers.cumulative_results_course_level/3
        end

    end
    object :courses_mutations do
        @desc "Insert Checklist Objective Remarks"
        field :checklist_objective_remarks, :checklist_objective_remarks do
            arg :course_id, non_null(:id)
            arg :teacher_mark, non_null(:id)
            arg :item_id, non_null(:id)
            arg :comment, :string
            resolve &CoursesResolvers.checklist_objective_remarks/3
        end
    end
        # Types
    object :checklist_objective_remarks do
        field :status, :string
        field :message, :string
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
        field :price, :float
        field :total_lessons, :integer
        field :image_url, :string
        field :participants, list_of(:participant)

    end
    object :participant do
        field :user_id, :integer
        field :fsm_user_id, :string
        field :first_name, :string
        field :last_name, :string
        field :course_completed, :boolean
        field :completed_lessons, :integer
        field :total_lessons, :integer
        field :total_lessons_completed, :float
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
