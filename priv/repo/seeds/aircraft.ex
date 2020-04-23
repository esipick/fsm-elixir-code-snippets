defmodule Seeds.Aircraft do
  def seed(amount \\ 99, school \\ Flight.Repo.one(Flight.Accounts.School)) do
    makes = [
      "Cessna",
      "Airbus",
      "Eurocopter",
      "Embraer",
      "Fournier",
      "Hurel-Dubois",
      "Junkers",
      "Martin-Baker"
    ]

    models = [
      "Baron 55",
      "172SP",
      "PA28-181",
      "R2-D2",
      "C-3PO",
      "R5D4",
      "R4P17",
      "Saesee Tiin",
      "Tarfful",
      "San Hill",
      "Jocasta"
    ]

    tail_no = [
      "N1697J",
      "N2544K",
      "N337JG",
      "N2819D",
      "N264Q",
      "N834DS",
      "N52TA",
      "N9087A",
      "N225AZ",
      "N7164C",
      "N396TA",
      "N40670",
      "N8750E",
      "N4382U",
      "N49931",
      "N5347H",
      "N735U",
      "N5633R",
      "N482DT"
    ]

    serials = [
      "28-24103",
      "TC442",
      "17265410",
      "172S9396",
      "28-8490071",
      "40.O34",
      "18265702",
      "TC-987",
      "05140017",
      "28-7615045",
      "120324",
      "17253253",
      "CH209941214"
    ]

    equipments = ["Garmin 530", "Garmin 430", "Bendix King GPS"]

    rates = [10000, 17000, 20000, 999_900, 15000]

    Enum.each(1..amount, fn _i ->
      school_context = %Plug.Conn{assigns: %{current_user: %{school_id: school.id}}}
      rate = Enum.random(rates)

      aircraft_data = %{
        make: Enum.random(makes),
        model: Enum.random(models),
        tail_number: Enum.random(tail_no),
        serial_number: Enum.random(serials),
        ifr_certified: Enum.random(1..10) > 5,
        equipment: Enum.random(equipments),
        simulator: Enum.random(1..10) > 5,
        rate_per_hour: rate,
        block_rate_per_hour: rate
      }

      Flight.Scheduling.admin_create_aircraft(aircraft_data, school_context)
    end)
  end
end
