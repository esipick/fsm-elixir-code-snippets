defmodule FlightWeb.Course.CourseController do
  use FlightWeb, :controller
  alias Flight.Auth.Authorization
  alias Flight.Billing.{Invoice, InvoiceCustomLineItem}
  alias Flight.Repo
  require Logger

  def index(%{assigns: %{current_user: current_user}} = conn, _) do
    isAdmin =  Authorization.is_admin?(current_user)
    adminLoginUrl =  case  isAdmin do
      true->
        Flight.General.get_lms_admin_login_url(current_user)
      false->
        nil
    end
    Logger.info fn -> "adminLoginUrl: #{inspect adminLoginUrl}" end

    loginUrl = Flight.General.get_student_login_url(current_user)
    courses = Flight.General.get_lms_courses(current_user, isAdmin)

    Logger.info fn -> "loginUrl: #{inspect loginUrl}" end
    Logger.info fn -> "courses: #{inspect courses}" end


    render(conn, "index.html",
      courses: courses,
      login_url: loginUrl,
      admin_login_url: adminLoginUrl,
      is_admin: isAdmin
    )
  end

  def participants(conn, _) do
    course_participants = [
      [
        %{
          id: 1,
          name: "Charlie Brown",
          progress: 37,
          date: "Nov. 14 3:45pm"
        },
        %{
          id: 2,
          name: "Jim Halpert",
          progress: 22,
          date: "Nov. 14 4:45pm"
        },
        %{
          id: 3,
          name: "Jim Halpert",
          progress: 70,
          date: "Nov. 14 4:05pm"
        }
      ],
      [
        %{
          id: 4,
          name: "Jim Halpert",
          progress: 0,
          date: "Dec. 14 1:00pm"
        },
        %{
          id: 5,
          name: "Jim Halpert",
          progress: 50,
          date: "Nov. 14 4:45pm"
        }
      ]
    ]
  
    render(
     conn,
    "participants.html",
     participants: course_participants
    )
  end

  def participant_info(conn, _) do
    render(
      conn,
      "participant_info.html"
    )
  end

  def selection(conn, _) do

    selections = [
      %{
        id: 1,
        name: "Pre-Flight Lesson",
        completion: "9/10",
        activities: [
          %{
            id: 1,
            title: "Direction",
            body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            satisfied: false
          },
          %{
            id: 2,
            title: "Management",
            body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            satisfied: true
          },
          %{
            id: 3,
            title: "Decision Making",
            body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            satisfied: false
          },
          %{
            id: 4,
            title: "Hand Reponsibilities",
            body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            satisfied: true
          },
          %{
            id: 5,
            title: "Airplane Stability",
            body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            satisfied: false
          }
        ]
      },
      %{
        id: 2,
        name: "Flight Review",
        completion: "0/40",
        activities: [
          %{
            id: 1,
            title: "Normal Take Off And Landing",
            body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            satisfied: false
          }
        ]
      }
    ]

    render(
      conn,
      "selection.html",
      selections: selections
    )
  end

end
