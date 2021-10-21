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
        field :first_name, :string
        field :last_name, :string
        field :lessons, list_of(:lesson)
    end
    object :lesson do
        field :id, :integer
        field :visible, :integer
        field :summary, :string
        field :summaryformat, :integer
        field :section, :integer
        field :uservisible, :boolean
        field :visited, :boolean
        field :last_visit_datetime, :string
        field :completed, :boolean
        field :checklists, list_of(:checklist)
    end
    object :checklist do
        field :id, :integer
        field :name, :string
        field :checklist_objectives, list_of(:checklist_objective)
    end
    object :checklist_objective do
        field :objective_id, :integer
        field :name, :string
        field :comment, :string
        field :remarks, :string

    end
    object :course_data do
        field :courses, list_of(:course)
    end


end
