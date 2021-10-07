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
    end

    # Types
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


    object :course_data do
        field :courses, list_of(:course)
    end


end
