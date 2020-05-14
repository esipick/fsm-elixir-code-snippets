* [Get Additional Items](#extra_options)

<a name="extra_options"/>

# Get List of Additional Line Items with default rate

```
GET /api/invoices/line_items/extra_options
```

Example response (JSON, `default_rate` is in cents):
```json
{
  "data":[
    {"default_rate": 100, "description": "Fuel Charge", "taxable": false, "deductible": false},
    {"default_rate": 100, "description": "Fuel Reimbursement", "taxable": false, "deductible": true},
    {"default_rate": 100, "description": "Equipment Rental", "taxable": true, "deductible": false}
  ]
}
```
