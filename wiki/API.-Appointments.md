* [List Appointments](#list)

API URL: `https://randon-aviation-staging.herokuapp.com/`

<a name="list"/>

# List Appointments

```
GET /api/appointments // show all appointments

GET /api/appointments?user_id=1 // show appointments of user with id = 1 only

GET /api/appointments?instructor_user_id=2 // show appointments of instructor user with id = 2 only

GET /api/appointments?status=0 // show pending appointments only
GET /api/appointments?status=1 // show paid appointments only

GET /api/appointments?user_id=1&status=1 // show paid appointments of user with id = 1 only
```

Returns list of appointments, not paginated.

Response Example:
```json
{
  "data":[
    {
      "user":{
        "last_name":"Bartoletti",
        "id":514,
        "first_name":"Andy",
        "email":"example+359ecd8d09efe51@gmail.com",
        "billing_rate":7500,
        "balance":0
      },
      "transaction_id":null,
      "status":"pending",
      "start_at":"2020-01-11T18:00:00",
      "note":"The ",
      "instructor_user":{
        "last_name":"Bartoletti",
        "id":20,
        "first_name":"Ariane",
        "email":"example+c350114cb46e7eb@gmail.com",
        "billing_rate":7500,
        "balance":0
      },
      "id":87,
      "end_at":"2020-01-11T20:00:00",
      "aircraft":{
        "tail_number":"01fad130bbc846d",
        "simulator":false,
        "serial_number":"4abc57b0138ce50",
        "rate_per_hour":20000,
        "model":"172SP",
        "make":"Airbus",
        "last_tach_time":1000,
        "last_hobbs_time":1000,
        "inspections":[
          {
            "type":"tach",
            "number_value":null,
            "name":"100hr",
            "date_value":null
          },
          {
            "type":"date",
            "number_value":null,
            "name":"ELT",
            "date_value":null
          },
          {
            "type":"date",
            "number_value":null,
            "name":"Altimeter",
            "date_value":null
          },
          {
            "type":"date",
            "number_value":null,
            "name":"Transponder",
            "date_value":null
          },
          {
            "type":"date",
            "number_value":null,
            "name":"Annual",
            "date_value":null
          }
        ],
        "ifr_certified":true,
        "id":48,
        "equipment":"Garmin 530"
      }
    },
    {
      "user":{
        "last_name":"Altons",
        "id":13,
        "first_name":"Mark",
        "email":"mark.altons@gmail.com",
        "billing_rate":7500,
        "balance":0
      },
      "transaction_id":null,
      "status":"pending",
      "start_at":"2020-01-10T16:30:00",
      "note":"10 pm",
      "instructor_user":{
        "last_name":"Bartoletti",
        "id":20,
        "first_name":"Ariane",
        "email":"example+c350114cb46e7eb@gmail.com",
        "billing_rate":7500,
        "balance":0
      },
      "id":86,
      "end_at":"2020-01-10T17:30:00",
      "aircraft":{
        "tail_number":"01fad130bbc846d",
        "simulator":false,
        "serial_number":"4abc57b0138ce50",
        "rate_per_hour":20000,
        "model":"172SP",
        "make":"Airbus",
        "last_tach_time":1000,
        "last_hobbs_time":1000,
        "inspections":[
          {
            "type":"tach",
            "number_value":null,
            "name":"100hr",
            "date_value":null
          },
          {
            "type":"date",
            "number_value":null,
            "name":"ELT",
            "date_value":null
          },
          {
            "type":"date",
            "number_value":null,
            "name":"Altimeter",
            "date_value":null
          },
          {
            "type":"date",
            "number_value":null,
            "name":"Transponder",
            "date_value":null
          },
          {
            "type":"date",
            "number_value":null,
            "name":"Annual",
            "date_value":null
          }
        ],
        "ifr_certified":true,
        "id":48,
        "equipment":"Garmin 530"
      }
    }
  ]
}
```