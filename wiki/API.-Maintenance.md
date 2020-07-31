* [Get Maintenance (Fleet View)](#index)
* [Get Aircraft Maintenance](#get)
* [Create Maintenance](#create)
* [Delete Maintenance](#delete)
* [Add Checklist to Maintenance](#add_checklist)
* [Assign Aircrafts to Maintenance](#add_aircrafts)
* [Delete Checklist from Maintenance](#delete_checklist)
* [Remove Maintenance from Aircraft] (#delete_aircrafts)

<a name="index"/>

# Get List of Fleet and their Maintenance

```
GET /api/maintenance
```

Example URL Params:
```
  page {0...} :: integer
  per_page {0...} :: integer
  sort_field {"aircraft_name", "name", "curr_tach_time", "days_remaining", "tach_time_remaining", "due_date"} :: string
  sort_order {"asc", "desc"} :: string
```


Example response (JSON):

```json
{
"result": [
  {
    "tach_time_remaining": null,
    "name": "7th Annual Inspection",
    "maintenance_id": "8d25cc5b-600c-41e9-a7e6-6f6fa01598d6",
    "due_date": "2022-07-28T11:56:54",
    "days_remaining": 726,
    "days": 727,
    "curr_tach_time": 250,
    "aircraft_model": "PA28-181",
    "aircraft_make": "Airbus",
    "aircraft_id": 1
    },
      {
    "tach_time_remaining": null,
    "name": "7th Annual Inspection",
    "maintenance_id": "8d25cc5b-600c-41e9-a7e6-6f6fa01598d6",
    "due_date": "2022-07-28T11:56:54",
    "days_remaining": 726,
    "days": 727,
    "curr_tach_time": 270,
    "aircraft_model": "Tarfful",
    "aircraft_make": "Fournier",
    "aircraft_id": 2
    },
      {
    "tach_time_remaining": null,
    "name": "8th Annual Inspection",
    "maintenance_id": "c6669d47-38d8-4fa0-a9e3-acf6cbeffff4",
    "due_date": "2021-07-29T11:57:05",
    "days_remaining": 362,
    "days": 363,
    "curr_tach_time": 270,
    "aircraft_model": "Tarfful",
    "aircraft_make": "Fournier",
    "aircraft_id": 2
    }
  ]
}
```

<a name="get"/>

# Get List of Aircraft Maintenance

```
GET /api/aircrafts/{:aircraft_id}/maintenance
```
Example URL Params:
```
  sort_field {"name", "curr_tach_time", "days_remaining", "tach_time_remaining", "due_date"} :: string
  sort_order {"asc", "desc"} :: string
  maintenance_name (search)::string
```

Example Response Error (JSON):

```json
{
"human_errors": [
  "Aircraft with id: 50 not found."
],
}
```

Example Response (JSON):
```json
{
"result": [
  {
"tach_time_remaining": 70,
"name": "5th Annual Inspection",
"maintenance_id": "dc06bb66-6494-48a8-bec3-31c6118fc2d2",
"due_date": null,
"days_remaining": null,
"days": null,
"curr_tach_time": 250,
"aircraft_model": "PA28-181",
"aircraft_make": "Airbus",
"aircraft_id": 1
}
],
}
```


<a name="create"/>

# Create Maintenance

```
POST /api/maintenance
```

Example request (JSON):
```json
{
"checklist_ids": ["edac28ec-fdc1-473e-90eb-51d3d9ae5d72"], 
"name": "6th Annual Inspection",
"description": "This inspection is due every 1 year and should be carried out regularly.",
"tach_hours": 100,
"no_of_months": 0,
"aircraft_hours": [{
  		"aircraft_id": 2,
  		"start_tach_hours": 220
	},
    {
  		"aircraft_id": 1,
  		"start_tach_hours": 250
	}],
 "alerts": [{
	"name": "Event Alert",
   	"send_alert_percentage": 20,
   	"description": "We are gonna send this description to users.",
   	"send_to_roles": ["admin"]
 }]
}
```

Example Error response (JSON):
```json
{
"human_errors": [
  "name: Maintenance with the same name already exists."
],
}
```

Example response (JSON):
```json
{
"result": "success"
}
```

<a name="delete"/>

# Delete Maintenance

```
DELETE /api/maintenance/{:id}
```

Example response Error (JSON):
Example Error response (JSON):
```json
{
"human_errors": [
  "name: Maintenance not found."
],
}
```

Example response (JSON):
```json
{
"result": "success"
}
```

<a name="index"/>

# create and add checklist, or add checklist by id to Maintenance

```
POST /api/maintenance/add_checklist
```
Example request (JSON):
```json
{
  "maintenance_id": "8d25cc5b-600c-41e9-a7e6-6f6fa01598d6",
  "checklists": [
    "084dcdfb-b5dc-481c-b4c2-33c14844233b", // checklist id
    {
      "name": "very new checklist 1",
      "description": "its added via api"
    }
  ]
}
```

Example Response Error (JSON):
```json
{
"human_errors": [
  "checklist 1 already exists in checklists."
]
}
```

Example Response (JSON):
```json
{
"result": "success"
}
```

<a name="add_aircrafts"/>

# Assing a list of aircrafts to maintenance

```
POST /api//maintenance/assign_aircrafts
```

Example Request (JSON):
```json
{
  "maintenance_id": "8d25cc5b-600c-41e9-a7e6-6f6fa01598d6",
  "aircrafts": [{
  		"aircraft_id": 2,
  		"start_tach_hours": 220
	  },
    {
  		"aircraft_id": 1,
  		"start_tach_hours": 250
	}]
}
```

<a name="delete_checklist"/>

# Delete List of Checklists from Maintenance

```
DELETE /api/checklists/maintenance
```

Example Request (JSON):
```json
{
  "maintenance_id": "13e10306-cec0-48f1-8e47-a49849f8857b",
  "checklist_ids":["edac28ec-fdc1-473e-90eb-51d3d9ae5d72"]
}
```
Example Response (JSON):
```json
{
"result": "success"
}
```

<a name="delete_aircrafts"/>

# Delete List of Aircrafts from Maintenance

```
DELETE /api/aircrafts/maintenance
```

Example Request (JSON):
```json
{
  "maintenance_id": "13e10306-cec0-48f1-8e47-a49849f8857b",
  "aircraft_ids":["edac28ec-fdc1-473e-90eb-51d3d9ae5d72"]
}
```
Example Response (JSON):
```json
{
"result": "success"
}
```