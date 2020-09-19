* [Get Rooms](#index)

<a name="index"/>

# Get List of Rooms

```
GET /api/rooms
```

Example response (JSON):
```json
{
  "data": [
    {
      "id": 1,
      "capacity": 5, // no. of persons
      "location": "Abc Location",
      "resources": "Projector, Whiteboard",
      "rate_per_hour": 1500,
      "block_rate_per_hour": 1200,
      school_id: 1
    },
    { ... }
  ]
}
```
