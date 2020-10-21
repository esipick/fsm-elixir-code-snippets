* [Get Maintenance Details](#maintenance_details)
* [Set CheckList Status](#status)
* [Add CheckList Parts](#parts)

<a name="maintenance_details"/>

# Get Maintenance Details

```
GET /api/maintenance/:id/details?aircraft_id=3
```

Example Success Response(JSON):

```json
{
"result": {
"tach_time_remaining": 610,
"tach_hours": 800,
"status": "pending",
"name": "800Hrs Inspection",
"maintenance_id": "fd651355-f6f4-4839-9c1b-179a7316e726",
"due_date": null,
"days_remaining": null,
"days": null,
"curr_tach_time": 2390,
"checklists": [
  {
"status": "completed",
"name": "chute",
"maintenance_checklist_id": "702e3859-2ba1-4880-a80d-cfee02ae727c",
"line_items": [
  "breaks",
  "Engine Oild"
],
"aircraft_maintenance_id": "528c99af-3fa4-4742-8b42-5a50e6ed7f04"
},
  {
"status": "completed",
"name": "chute 1",
"maintenance_checklist_id": "1c226cfc-07f0-4764-a45a-732d6534b6a8",
"line_items": [],
"aircraft_maintenance_id": "528c99af-3fa4-4742-8b42-5a50e6ed7f04"
}
],
"aircraft_id": 1
}
}
```

Example Error Response(JSON):

```json
{
"human_errors": [
  "Maintenance not found for aircraft id: 3"
],
}
```


<a name="status"/>

# Set CheckList Status as pending or completed

```
POST /api/checklists/status
```

Example body Params(JSON):

```json
{
  "maintenance_checklist_id": "d8f7e4dd-63aa-4845-8e5e-4ddb5932b5ab",
  "aircraft_maintenance_id": "528c99af-3fa4-4742-8b42-5a50e6ed7f04",
  "status": "completed",
  "notes" : "completed 1."
}
```

Example Success Response(JSON):

```json
{
    "result": true
}
```

Example Error Response(JSON):

```json
{
    "human_errors": [
        "maintenance_checklist_id: Maintenance Checklist not found."
    ]
}
```

<a name="parts"/>

# Add CheckList Parts

```
POST /api/checklists/line_items
```

Example body Params(JSON):

```json
{
  "maintenance_checklist_id": "d8f7e4dd-63aa-4845-8e5e-4ddb5932b5ab",
  "aircraft_maintenance_id": "528c99af-3fa4-4742-8b42-5a50e6ed7f04",
  "items": [{
  	"part_name": "breaks",
  	"part_number" : "2234",
    "serial_number": "255225"
  }]
}
```

Example Success Response(JSON):

```json
{
    "result": true
}
```

Example Error Response(JSON):

```json
{
    "human_errors": [
        "maintenance_checklist_id: Maintenance Checklist not found."
    ]
}
```

