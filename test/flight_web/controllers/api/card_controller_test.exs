defmodule FlightWeb.API.UserControllerTest do
  use FlightWeb.ConnCase

  test "401 if student creating card for other student", %{conn: conn} do
    student = student_fixture()
    other_student = student_fixture()

    conn
    |> auth(other_student)
    |> post("/api/users/#{student.id}/cards", %{stripe_token: "tok_visa"})
    |> response(401)
  end

  test "401 if student updating card for other student", %{conn: conn} do
    student = student_fixture()
    other_student = student_fixture()

    conn
    |> auth(other_student)
    |> put("/api/users/#{student.id}/cards/card_123", %{exp_month: 1, exp_year: 2030})
    |> response(401)
  end

  test "401 if student deletes card for other student", %{conn: conn} do
    student = student_fixture()
    other_student = student_fixture()

    conn
    |> auth(other_student)
    |> delete("/api/users/#{student.id}/cards/card_123")
    |> response(401)
  end
end
