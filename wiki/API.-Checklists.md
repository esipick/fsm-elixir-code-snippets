* [Get All Checklists](#index)
* [Create List of Checklists](#create)
* [Delete Checklist](#delete)

<a name="index"/>

# Get List of Checklists

```
GET /api/checklists
```

Example URL Params:
```
  page {0...} :: integer
  per_page {0...} :: integer
  sort_field {"name"} :: string
  sort_order {"asc", "desc"} :: string
```

Example response (JSON):
```json
{
  "result": [
      {
      "updated_at": "2020-07-31T11:55:14",
      "school_id": 1,
      "name": "chute",
      "id": "517736e9-0781-4f90-8cb2-5e50ce38037e",
      "description": "something very cool",
      "created_at": "2020-07-31T11:55:14"
    },
    {
      "updated_at": "2020-07-31T11:55:14",
      "school_id": 1,
      "name": "chute 1",
      "id": "867b50c6-a5f3-42e3-b847-c82ecc92e260",
      "description": "something very cool 1",
      "created_at": "2020-07-31T11:55:14"
    }
  ]
}
```

<a name="create"/>

# create List of Checklists

```
POST /api/checklists
```

Example Request (JSON):
```json
[{
  "name": "chute", 
  "description": "something very cool" 
},
{
  "name": "chute 1", 
  "description": "something very cool 1" 
}]
```
Example Response (JSON):
```json
{
  "result": [
    {
      "updated_at": "2020-07-31T13:09:26",
      "school_id": 1,
      "name": "chute 1",
      "id": "8465168b-59c5-47d5-8de9-5c6c12ee8627",
      "description": "something very cool 1",
      "created_at": "2020-07-31T13:09:26"
      },
        {
      "updated_at": "2020-07-31T13:09:26",
      "school_id": 1,
      "name": "chute",
      "id": "ab57e596-ebf1-490e-9203-afd184f3c1d7",
      "description": "something very cool",
      "created_at": "2020-07-31T13:09:26"       
    }
  ]
}
```

<a name="delete"/>

# Delete Checklist

```
DELETE /api/checklists
```

Example URL Params:
```json
  {
    "id": "edac28ec-fdc1-473e-90eb-51d3d9ae5d72"
  }
```

Example Response Error (JSON):
```json
{
"human_errors": [
  "Checklist with id: edac28ec-fdc1-473e-90eb-51d3d9ae5d72 not found."
],
}
```

Example Response (JSON):
```json
{
"result": "success"
}
```