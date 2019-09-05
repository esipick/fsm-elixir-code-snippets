Faker.start()

makes = ["Boeing", "Airbus", "Eurocopter", "Embraer", "Fournier", "Hurel-Dubois", "Junkers", "Martin-Baker"]
models = Enum.map(0..10, fn(_i) -> Faker.Company.buzzword end)

Enum.each(0..99, fn(_i) ->
  school = Flight.Repo.one(Flight.Accounts.School)
  school_context = %Plug.Conn{assigns: %{current_user: %{school_id: school.id}}}

  aircraft_data = %{
    make: Enum.random(makes),
    model: Enum.random(models),
    tail_number: Flight.Random.hex(15),
    serial_number: Flight.Random.hex(15),
    ifr_certified: Enum.random(1..10) > 5,
    equipment: Faker.Lorem.word,
    simulator: Enum.random(1..10) > 5,
    rate_per_hour: Enum.random(100..200),
    block_rate_per_hour: Enum.random(200..300),
  }

  Flight.Scheduling.admin_create_aircraft(aircraft_data, school_context)
end)
