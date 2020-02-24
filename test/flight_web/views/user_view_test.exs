defmodule FlightWeb.API.UserViewTest do
  use FlightWeb.ConnCase, async: true

  import Phoenix.View
  alias FlightWeb.API.UserView
  alias Flight.Accounts

  test "show.json" do
    user =
      user_fixture()
      |> FlightWeb.API.UserView.show_preload()

    assert render(UserView, "show.json", user: user) == %{
             data: render(UserView, "user.json", user: user)
           }
  end

  # test "user.json" do
  #   user =
  #     user_fixture(%{
  #       first_name: "Tim",
  #       last_name: "Johnson",
  #       email: "foo@bar.com"
  #     })
  #
  #   assert render(UserView, "user.json", user: user) == %{
  #            id: user.id,
  #            first_name: "Tim",
  #            last_name: "Johnson",
  #            email: "foo@bar.com",
  #            balance: 0
  #          }
  # end

  test "form_items.json" do
    student = student_fixture()

    items =
      student
      |> Accounts.editable_fields()
      |> Enum.map(&FlightWeb.UserForm.item(student, &1))

    assert render(UserView, "form_items.json", form_items: items) == %{
            data:
              [
                %FlightWeb.Form.Item{
                  key: :address_1,
                  name: "Address",
                  options: [],
                  order: 20,
                  type: :string,
                  value: student.address_1
                },
                %FlightWeb.Form.Item{
                  key: :certificate_number,
                  name: "Certificate #",
                  options: [],
                  order: 45,
                  type: :string,
                  value: student.certificate_number
                },
                %FlightWeb.Form.Item{
                  key: :city,
                  name: "City",
                  options: [],
                  order: 25,
                  type: :string,
                  value: student.city
                },
                %FlightWeb.Form.Item{
                  key: :email,
                  name: "Email",
                  options: [],
                  order: 10,
                  type: :string,
                  value: student.email
                },
                %FlightWeb.Form.Item{
                  key: :first_name,
                  name: "First Name",
                  options: [],
                  order: 1,
                  type: :string,
                  value: student.first_name
                },
                %FlightWeb.Form.Item{
                  key: :flight_training_number,
                  name: "FTN",
                  options: [],
                  order: 40,
                  type: :string,
                  value: student.flight_training_number
                },
                %FlightWeb.Form.Item{
                  key: :inserted_at,
                  name: "Registration date",
                  options: [],
                  order: 70,
                  type: :date,
                  value: student.inserted_at
                },
                %FlightWeb.Form.Item{
                  key: :last_name,
                  name: "Last Name",
                  options: [],
                  order: 5,
                  type: :string,
                  value: student.last_name
                },
                %FlightWeb.Form.Item{
                  key: :medical_expires_at,
                  name: "Medical Expiration",
                  options: [],
                  order: 60,
                  type: :date,
                  value: student.medical_expires_at
                },
                %FlightWeb.Form.Item{
                  key: :medical_rating,
                  name: "Medical Approval",
                  options: [
                    %FlightWeb.Form.Option{name: "None", value: "0"},
                    %FlightWeb.Form.Option{name: "1st Class", value: "1"},
                    %FlightWeb.Form.Option{name: "2nd Class", value: "2"},
                    %FlightWeb.Form.Option{name: "3rd Class", value: "3"}
                  ],
                  order: 55,
                  type: :enumeration,
                  value: %FlightWeb.Form.Option{name: "None", value: "0"}
                },
                %FlightWeb.Form.Item{
                  key: :phone_number,
                  name: "Phone #",
                  options: [],
                  order: 15,
                  type: :string,
                  value: student.phone_number
                },
                %FlightWeb.Form.Item{
                  key: :state,
                  name: "State",
                  options: [],
                  order: 30,
                  type: :string,
                  value: student.state
                },
                %FlightWeb.Form.Item{
                  key: :zipcode,
                  name: "Zipcode",
                  options: [],
                  order: 35,
                  type: :string,
                  value: student.zipcode
                }
              ]
           }
  end
end
