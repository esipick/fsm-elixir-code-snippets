* [Get Aircrafts](#index)
* [Create Aircraft](#create)

<a name="index"/>

# Get List of Aircrafts

```
GET /api/aircrafts
```

Example response (JSON):
```json
{
  "data": [
    {
      "tail_number": "01fad130bbc846d",
      "simulator": false,
      "serial_number": "4abc57b0138ce50",
      "rate_per_hour": 20000,
      "model": "172SP",
      "make": "Airbus",
      "last_tach_time": 1000,
      "last_hobbs_time": 1000,
      "inspections": [
        {
          "type": "date",
          "number_value": null,
          "name": "Annual",
          "date_value": null
        }
      ],
      "ifr_certified": true,
      "id": 48,
      "equipment": "Garmin 530"
    }
  ]
}
```

<a name="create"/>

# Create an Aircraft and Assing Maintenances

```
POST /api/aircrafts
```

Example Request Body (JSON):
```json
{
  "data": [
    {
      "ifr_certified": true,
      "last_tach_time": 0,
      "last_hobbs_time": 0,
      "model": "2020",
      "make": "Air America",
      "serial_number": "85215855222-AF",
      "equipment": "parachute",
      "tail_number": "5253",
      "rate_per_hour": 15000,
      "block_rate_per_hour": 12500,
      "maintenance_ids": ["a51353fa-140c-4c85-87d3-bda8787c5feb", "dc06bb66-6494-48a8-bec3-31c6118fc2d2"] // maintenance_ids shall be an empty array if there is no maintenance for assignment
	  }
  ]
}
```

Example Response (JSON):
```json
{
  "result": "success"
}
```

Example Error (JSON):
```json
{
"human_errors": [
  "Maintenance a51353fa-140c-4c85-87d3-bda8787c5fec not found."
],
}
```