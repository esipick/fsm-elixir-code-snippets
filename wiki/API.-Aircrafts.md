* [Get Aircrafts](#index)

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