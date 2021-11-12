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
      id: download.id,
      version: download.version,
      name: download.name,
      url: download.url
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
      syllabus: %{
        url: lesson.syllabus_url,
        version: lesson.syllabus_version
      }
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

  def render("participant_course_info.json", %{participant_course_info: course_info}) do
    %{
      message: course_info.message,
      status: course_info.status,
      participantCourse: render_one(course_info.participant, CourseView, "course_participant.json", as: :participant)
    }
  end

  def render("course_participant.json", %{participant: participant}) do
    participant
  end

end
