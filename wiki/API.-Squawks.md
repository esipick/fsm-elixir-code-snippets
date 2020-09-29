* [Create Invoice](#create)  

API URL: `https://randon-aviation-staging.herokuapp.com/`

<a name="create"/>

# Create Squawk Issue

```
POST /api/invoices (https://randon-aviation-staging.herokuapp.com/api/maintenance/squawks)

Body (JSON):
{
  description: "Squawk issue description.",
  severity: "ground", // one of ["ground", "fix_soon", "no_fix_required"],  
  reported_by_id: 1, // {user_id}
  aircraft_id: 1, // {aircraft_id}
  notify_roles: "admin", // one of ["admin", "dispatcher", "mechanic"]
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
    "notify_roles": "admin", // one of ["admin", "dispatcher", "mechanic"]
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

---

<a name="update"/>

# Update Invoice

```
PUT /api/invoices/:id

Body (JSON): // same as in create request
{
  invoice: ...,
  pay_off: true/false // `true` will trigger payment procedure
}
```

Invoice and line items structure is almost same as in the Create request, but in the Update request both invoice and all line items must have ID. Example is below.

Request Example:
```json
{
  "pay_off":false,
  "invoice":{
    "line_items":[
      {
        "rate":5000,
        "quantity":1,
        "id":2,
        "description":"Fuel Reimbursement",
        "amount":5000,
        "type": "other",
        "instructor_user_id": null,
        "aircraft_id": null,
        "taxable": false
      },
      {
        "rate":5000,
        "quantity":1.5,
        "id":1,
        "description":"Instructor Hours",
        "amount":7500,
        "type": "instructor",
        "instructor_user_id": 20004,
        "aircraft_id": null,
        "taxable": false
      }
    ],
    "id":7,
    "user_id":345,
    "date":"2019-10-20T00:00:00.000Z",
    "tax_rate":10,
    "total":12500,
    "total_tax":1250,
    "total_amount_due":13750,
    "payment_option":"balance",
    "status": "pending"
  }
}
```

---

<a name="list"/>

# List invoices

```
GET /api/invoices?page=:number
```

Optional params:

|Parameter|Type|Example|Description|
|---|---|---|---|
|user_id|number|781|id of student|
|search|string|"niko"|search string, Search by student name or aircraft tail number|
|start_date|date|05-30-2020|return invoices with invoice date >= start_date|
|end_date|date|05-30-2020|return invoices with invoice date <= end_date|
|status|number|0|invoice status: 0 - pending, 1 - paid|

List of invoices, paginated by 50 per page

Pagination info will be available in the response headers:
```bash
link: <http://localhost:4000/api/invoices?page=1>; rel="first", <http://localhost:4000/api/invoices?page=1>; rel="last"
total: 5
per-page: 50
total-pages: 1
page-number: 1
```

Response Example:
```json
{
  "data":[
    {
      "user_id":345,
      "user":{
        "last_name":"Leffler",
        "id":345,
        "first_name":"Verner",
        "balance":5156
      },
      "total_tax":33,
      "total_amount_due":133,
      "total":100,
      "tax_rate":33,
      "payment_option":"balance",
      "status": "paid",
      "appointment_id": null,
      "line_items":[
        {
          "rate":100,
          "quantity":1.0,
          "description":"rent",
          "amount":100,
          "type":"other",
          "aircraft_id":null,
          "instructor_user_id":null,
          "taxable": true
        }
      ],
      "id":8,
      "date":"2019-10-21"
    },
    {
      "user_id":345,
      "user":{
        "last_name":"Leffler",
        "id":345,
        "first_name":"Verner",
        "balance":5156
      },
      "total_tax":33,
      "total_amount_due":133,
      "total":100,
      "tax_rate":33,
      "payment_option":"cash",
      "appointment_id": null,
      "line_items":[
        {
          "rate":100,
          "quantity":1.0,
          "description":"rent",
          "amount":100,
          "type":"other",
          "aircraft_id":null,
          "instructor_user_id":null
        }
      ],
      "id":9,
      "date":"2019-10-21"
    }
  ]
}
```

---

<a name="get_one"/>

# Get one invoice by ID

```
GET /api/invoices/:id
```

Response example:
```json
{
  "user_id":345,
  "user":{
    "last_name":"Leffler",
    "id":345,
    "first_name":"Verner",
    "balance":5422
  },
  "total_tax":1250,
  "total_amount_due":13750,
  "total":12500,
  "tax_rate":10,
  "payment_option":"balance",
  "status": "paid",
  "line_items":[
    {
      "rate":5000,
      "quantity":1,
      "description":"Fuel Reimbursement",
      "amount":5000,
      "type":"other",
      "aircraft_id":null,
      "instructor_user_id":null,
      "taxable": false
    },
    {
      "rate":5000,
      "quantity":1.5,
      "description":"Instructor Hours",
      "amount":7500,
      "type":"instructor",
      "aircraft_id":null,
      "appointment_id": null,
      "instructor_user_id":20004,
      "taxable": false,
      "instructor_user": {
          "balance": 0,
          "billing_rate": 100,
          "first_name": "some first name",
          "id": 20004,
          "last_name": "some last name"
        },
    }
  ],
  "id":7,
  "date":"2019-10-20"
}
```

<a name="from_appointment"/>

# Create Invoice From Appointment

```
POST /api/invoices/from_appointment/:appointment_id
```

Given that there is an existing appointment with the following parameters:
- ID: 1000
- Duration: 2 hours
- Insturctor User
  - ID: 20007
  - Billing rate: 100
- Aircraft:
  - ID: 3030
  - Rate: 130

In this case it is possible to just make a POST request to `/api/invoices/from_appointment/1000`. Server will generate and return invoice object that will be ready for editing. It is possible to set `payment_option`, `hobbs_time`, `tach_time` and `pay_off` parameters

Example request:
```json
{
  "payment_option": "cc",
  "hobbs_time": 2.2,
  "tach_time": 5.5,
  "pay_off": true
}
```

Example response:
```json
{
  "data":{
    "user_id":20006,
    "user":{
      "last_name":"some last name",
      "id":20006,
      "first_name":"some first name",
      "billing_rate":100,
      "balance":0
    },
    "total_tax":46,
    "total_amount_due":506,
    "total":460,
    "tax_rate":10.0,
    "payment_option":"balance",
    "status": "pending",
    "line_items":[
      {
        "type":"aircraft",
        "rate":130,
        "quantity":2.0,
        "instructor_user_id":null,
        "instructor_user":null,
        "id":3030,
        "description":"Flight Hours",
        "amount":260,
        "aircraft_id":3919,
        "aircraft":{
          "tail_number":"730a1a5c753f595",
          "serial_number":"49e9b3ac719e732",
          "rate_per_hour":130,
          "block_rate_per_hour": 100,
          "model":"Thing",
          "make":"Sesna",
          "last_tach_time":400,
          "last_hobbs_time":400,
          "id":3919
        },
        "taxable": true
      },
      {
        "type":"instructor",
        "rate":100,
        "quantity":2.0,
        "instructor_user_id":20007,
        "instructor_user":{
          "last_name":"some last name",
          "id":20007,
          "first_name":"some first name",
          "billing_rate":100,
          "balance":0
        },
        "id":3031,
        "description":"Instructor Hours",
        "amount":200,
        "aircraft_id":null,
        "aircraft":null,
        "taxable": false
      }
    ],
    "id":1017,
    "date":"2018-03-03",
    "appointment_id":1000,
    "appointment":{
      "user":{
        "last_name":"some last name",
        "id":20006,
        "first_name":"some first name",
        "billing_rate":100,
        "balance":0
      },
      "transaction_id":null,
      "start_at":"2018-03-03T05:00:00",
      "note":null,
      "instructor_user":{
        "last_name":"some last name",
        "id":20007,
        "first_name":"some first name",
        "billing_rate":100,
        "balance":0
      },
      "id":1000,
      "end_at":"2018-03-03T07:00:00",
      "aircraft":{
        "tail_number":"730a1a5c753f595",
        "simulator":true,
        "serial_number":"49e9b3ac719e732",
        "rate_per_hour":130,
        "model":"Thing",
        "make":"Sesna",
        "last_tach_time":400,
        "last_hobbs_time":400,
        "inspections":[

        ],
        "ifr_certified":true,
        "id":3919,
        "equipment":"5cfc74dd6089fae",
        "block_rate_per_hour": 100
      }
    }
  }
}
```

---

<a name="delete"/>

# Delete pending invoice

```
DELETE /api/invoices/:id
```

Please note that _only pending invoices can be deleted_. If invoice is already paid then request to delete will return `401 unauthorized` error.

This endpoint returns empty response with HTTP 204 code on success.

---

<a name="payment_options">

# Payment Options

```
GET /api/invoices/payment_options
```

Example response:
```
{
  "data": [
    ["balance", 0],
    ["cc", 1],
    ["cash", 2],
    ["cheque", 3],
    ["venmo", 4]
  ]
}
```

---

<a name="calculate">

# Calculate Invoice

```
POST /api/invoices/calculate
```

Receives invoice attributes and returns same attributes but with added `amount` to every line item and `total`, `total_tax`, `total_amount_due` to the invoice body

Example request:
```json
{
  "invoice":{
    "ignore_last_time": false,
    "line_items":[
      {
        "type":"aircraft",
        "tach_start":11,
        "tach_end":25,
        "rate":28500,
        "quantity":1,
        "instructor_user_id":null,
        "instructor_user":null,
        "hobbs_tach_used":true,
        "hobbs_start":7,
        "hobbs_end":26,
        "description":"Flight Hours",
        "amount":28500,
        "aircraft_id":221,
        "taxable": true
      },
      {
        "type":"other",
        "tach_start":null,
        "tach_end":null,
        "rate":5200,
        "quantity":1,
        "instructor_user_id":null,
        "instructor_user":null,
        "hobbs_tach_used":null,
        "hobbs_start":null,
        "hobbs_end":null,
        "description":"Fuel",
        "amount":5200,
        "aircraft_id":null,
        "aircraft":null,
        "taxable": false
      }
    ],
    "user_id":777,
    "appointment_id":null
  }
}
```

Example response:
```json
{
  "user_id":777,
  "total_tax":3370,
  "total_amount_due":37070,
  "total":33700,
  "tax_rate":10,
  "school_id":4,
  "line_items":[
    {
      "type":"aircraft",
      "tach_start":11,
      "tach_end":25,
      "rate":28500,
      "quantity":1,
      "instructor_user_id":null,
      "instructor_user":null,
      "hobbs_tach_used":true,
      "hobbs_start":7,
      "hobbs_end":26,
      "description":"Flight Hours",
      "amount":28500,
      "aircraft_id":221
    },
    {
      "type":"other",
      "tach_start":null,
      "tach_end":null,
      "rate":5200,
      "quantity":1,
      "instructor_user_id":null,
      "instructor_user":null,
      "hobbs_tach_used":null,
      "hobbs_start":null,
      "hobbs_end":null,
      "description":"Fuel",
      "amount":5200,
      "aircraft_id":null,
      "aircraft":null
    }
  ],
  "appointment_id":null
}
```
