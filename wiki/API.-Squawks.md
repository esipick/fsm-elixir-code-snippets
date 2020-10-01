* [Create Squawk](#create)  

API URL: `https://randon-aviation-staging.herokuapp.com/`

<a name="create"/>

# Create Squawk Issue

```
POST /api/maintenance/squawks (https://randon-aviation-staging.herokuapp.com/api/maintenance/squawks)

Body (JSON):
{
  description: "Squawk issue description.",
  severity: "ground", // one of ["ground", "fix_soon", "no_fix_required"],  
  reported_by_id: 1, // {user_id}
  aircraft_id: 1, // {aircraft_id}
  notify_roles: ["admin"], // one or more of ["admin", "dispatcher", "mechanic"]
  attachments: ... // List of files to be uploaded
}
```

### Request Example:

```json
{
  {
    "description": "Squawk issue description.",
    "severity": "ground", // one of ["ground", "fix_soon", "no_fix_required"],  
    "reported_by_id": 1, // {user_id}
    "aircraft_id": 1, // {aircraft_id}
    "notify_roles": ["admin"], // one or more of ["admin", "dispatcher", "mechanic"]
    "attachments": ... // List of files to be uploaded
  }
}
```

### Response Example:

```json
{
  "result": "success"
}
```

### Error Response Example:

```json
{
    "human_error": "Aircraft with id: 8 doesn't exists."
}
```

### Error Response Example:

```json
{
    "human_errors": ["Role: is invalid]"
}
```
