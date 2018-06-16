defmodule FlightWeb.API.CourseView do
  use FlightWeb, :view

  alias FlightWeb.API.CourseView

  def render("index.json", %{courses: courses}) do
    %{
      data: render_many(courses, CourseView, "course.json", as: :course)
    }
  end

  def render("course.json", %{course: course}) do
    %{
      id: course.id,
      name: course.name,
      course_downloads:
        render_many(
          course.course_downloads,
          CourseView,
          "course_download.json",
          as: :course_download
        ),
      lessons: render_many(course.lessons, CourseView, "lesson.json", as: :lesson)
    }
  end

  def render("course_download.json", %{course_download: download}) do
    %{
      name: download.name,
      url: "https://google.com"
    }
  end

  def render("lesson.json", %{lesson: lesson}) do
    %{
      id: lesson.id,
      name: lesson.name,
      lesson_categories:
        render_many(
          lesson.lesson_categories,
          CourseView,
          "lesson_category.json",
          as: :lesson_category
        ),
      syllabus: render("syllabus.json", syllabus: lesson.syllabus)
    }
  end

  def render("syllabus.json", %{syllabus: _syllabus}) do
    %{
      url: "https://google.com"
    }
  end

  def render("lesson_category.json", %{lesson_category: category}) do
    %{
      id: category.id,
      name: category.name,
      objectives: render_many(category.objectives, CourseView, "objective.json", as: :objective)
    }
  end

  def render("objective.json", %{objective: objective}) do
    %{
      id: objective.id,
      name: objective.name
    }
  end
end
