defmodule FlightWeb.API.ControllerTest do
  use FlightWeb.ConnCase, async: false

  alias FlightWeb.API.UnavailabilityView
  alias Flight.Scheduling.{Unavailability}

  describe "GET /api/unavailabilities" do
    test "returns unavailabilities", %{conn: conn} do
      unavailability1 =
        unavailability_fixture(%{
          start_at: ~N[2038-03-03 10:00:00],
          end_at: ~N[2038-03-03 11:00:00]
        })

      from = NaiveDateTime.to_iso8601(~N[2038-03-03 09:00:00])
      to = NaiveDateTime.to_iso8601(~N[2038-03-03 12:00:00])

      json =
        conn
        |> auth(user_fixture())
        |> get("/api/unavailabilities", %{
          from: from,
          to: to
        })
        |> json_response(200)

      unavailability =
        Flight.Scheduling.get_unavailabilities(%{"from" => from, "to" => to}, unavailability1)
        |> List.first()
        |> FlightWeb.API.UnavailabilityView.preload()

      assert json ==
               render_json(UnavailabilityView, "index.json", unavailabilities: [unavailability])
    end
  end

  describe "GET /api/unavailabilities/:id" do
    @tag :wip
    test "renders unavailability", %{conn: conn} do
      unavailability =
        unavailability_fixture(%{
          start_at: ~N[2038-03-03 10:00:00],
          end_at: ~N[2038-03-03 11:00:00]
        })
        |> FlightWeb.API.UnavailabilityView.preload()
        |> Flight.Scheduling.apply_timezone(default_school_fixture().timezone)

      json =
        conn
        |> auth(user_fixture())
        |> get("/api/unavailabilities/#{unavailability.id}")
        |> json_response(200)

      assert json == render_json(UnavailabilityView, "show.json", unavailability: unavailability)
    end
  end

  describe "PUT /api/unavailabilities/:id" do
    @default_date ~N[2038-03-03 10:00:00]
    @default_attrs %{
      start_at: Timex.shift(@default_date, hours: 2),
      end_at: Timex.shift(@default_date, hours: 4)
    }

    test "student updates unavailability", %{conn: conn} do
      instructor = user_fixture() |> assign_role("instructor")

      school = default_school_fixture()

      unavailability = unavailability_fixture(@default_attrs, instructor)

      params = %{
        data: %{
          start_at: Timex.shift(@default_date, hours: 3),
          note: "Heyo Timeo"
        }
      }

      json =
        conn
        |> auth(instructor)
        |> put("/api/unavailabilities/#{unavailability.id}", params)
        |> json_response(200)

      assert unavailability =
               Flight.Repo.get_by(
                 Unavailability,
                 id: unavailability.id,
                 start_at:
                   Timex.shift(@default_date, hours: 3)
                   |> Flight.Walltime.utc_to_walltime(school.timezone),
                 note: "Heyo Timeo"
               )
               |> FlightWeb.API.UnavailabilityView.preload()

      unavailability =
        unavailability.id
        |> Flight.Scheduling.get_unavailability(school)
        |> FlightWeb.API.UnavailabilityView.preload()

      assert json == render_json(UnavailabilityView, "show.json", unavailability: unavailability)
    end

    @tag :integration
    test "show error if unavailability already removed", %{conn: conn} do
      instructor = user_fixture() |> assign_role("instructor")
      unavailability = unavailability_fixture(@default_attrs, instructor)

      Flight.Repo.delete!(unavailability)

      params = %{
        data: %{note: "Heyo Timeo"}
      }

      json =
        conn
        |> auth(instructor)
        |> put("/api/unavailabilities/#{unavailability.id}", params)
        |> json_response(401)

      assert json == %{
               "human_errors" => [
                 "Unavailability already removed please recreate it"
               ]
             }
    end
  end

  describe "POST /api/unavailabilities" do
    @default_date ~N[2038-03-03 10:00:00]
    @default_attrs %{
      start_at: Timex.shift(@default_date, hours: 2),
      end_at: Timex.shift(@default_date, hours: 4)
    }

    test "instructor creates unavailability for themselves", %{conn: conn} do
      instructor = user_fixture() |> assign_role("instructor")

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            instructor_user_id: instructor.id,
            belongs: "Instructor"
          })
      }

      json =
        conn
        |> auth(instructor)
        |> post("/api/unavailabilities", params)
        |> json_response(200)

      assert unavailability =
               Flight.Repo.get_by(
                 Unavailability,
                 instructor_user_id: instructor.id,
                 belongs: "Instructor"
               )
               |> Flight.Scheduling.apply_timezone(default_school_fixture().timezone)

      unavailability = FlightWeb.API.UnavailabilityView.preload(unavailability)

      assert json == render_json(UnavailabilityView, "show.json", unavailability: unavailability)
    end

    @tag :wip
    test "instructor creates unavailability for aircraft", %{conn: conn} do
      instructor = user_fixture() |> assign_role("instructor")
      aircraft = aircraft_fixture()

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            aircraft_id: aircraft.id,
            belongs: "Aircraft"
          })
      }

      json =
        conn
        |> auth(instructor)
        |> post("/api/unavailabilities", params)
        |> json_response(200)

      assert unavailability =
               Flight.Repo.get_by(
                 Unavailability,
                 aircraft_id: aircraft.id,
                 belongs: "Aircraft"
               )
               |> Flight.Scheduling.apply_timezone(default_school_fixture().timezone)

      unavailability = FlightWeb.API.UnavailabilityView.preload(unavailability)

      assert json == render_json(UnavailabilityView, "show.json", unavailability: unavailability)
    end

    test "can't create unavailability without instructor", %{conn: conn} do
      instructor = instructor_fixture()

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{belongs: "Instructor"})
      }

      conn
      |> auth(instructor)
      |> post("/api/unavailabilities", params)
      |> json_response(400)
    end

    test "can't create unavailability without aircraft", %{conn: conn} do
      instructor = instructor_fixture()

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{belongs: "Aircraft"})
      }

      conn
      |> auth(instructor)
      |> post("/api/unavailabilities", params)
      |> json_response(400)
    end

    test "student can't create unavailabililty for aircraft", %{conn: conn} do
      student = student_fixture()
      aircraft = aircraft_fixture()

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            aircraft_id: aircraft.id
          })
      }

      conn
      |> auth(student)
      |> post("/api/unavailabilities", params)
      |> json_response(400)
    end

    @tag :wip
    test "instructor can't create unavailability for another instructor", %{conn: conn} do
      instructor = instructor_fixture()
      instructor2 = instructor_fixture()

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            instructor_user_id: instructor2.id
          })
      }

      conn
      |> auth(instructor)
      |> post("/api/unavailabilities", params)
      |> json_response(400)
    end
  end

  describe "DELETE /api/unavailabilities/:id" do
    test "instructor deletes own unavailability", %{conn: conn} do
      unavailability = unavailability_fixture(%{}, instructor_fixture(), nil)

      conn
      |> auth(unavailability.instructor_user)
      |> delete("/api/unavailabilities/#{unavailability.id}")
      |> response(204)

      refute Flight.Repo.get(Unavailability, unavailability.id)
    end

    test "instructor deletes aircraft unavailability", %{conn: conn} do
      unavailability = unavailability_fixture(%{}, nil, aircraft_fixture())

      conn
      |> auth(instructor_fixture())
      |> delete("/api/unavailabilities/#{unavailability.id}")
      |> response(204)

      refute Flight.Repo.get(Unavailability, unavailability.id)
    end

    test "instructor can't delete other instructor unavailability", %{conn: conn} do
      unavailability = unavailability_fixture(%{}, instructor_fixture(), nil)
      instructor = instructor_fixture()

      conn
      |> auth(instructor)
      |> delete("/api/unavailabilities/#{unavailability.id}")
      |> response(400)
    end

    @tag :integration
    test "show error if unavailability already removed", %{conn: conn} do
      instructor = user_fixture() |> assign_role("instructor")
      unavailability = unavailability_fixture(@default_attrs, instructor)

      Flight.Repo.delete!(unavailability)

      params = %{
        data: %{note: "Heyo Timeo"}
      }

      json =
        conn
        |> auth(instructor)
        |> delete("/api/unavailabilities/#{unavailability.id}")
        |> json_response(401)

      assert json == %{
               "human_errors" => [
                 "Unavailability already removed please recreate it"
               ]
             }
    end
  end
end
