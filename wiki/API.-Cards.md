* [Add new card and set it as user default payment source](#create)
* [Update card expiration date](#update)
* [Delete card](#delete)

---

<a name="create"/>

### Add new card and set it as user default payment source

```
POST /api/users/:user_id/cards
```

Example request (JSON):
```json
{"stripe_token": "tok_visa"}
```

Response:
```json
{"result":"success"}
```

---

<a name="update"/>

### Update card expiration date

```
PUT /api/users/:user_id/cards/card_1Gl0ydA9eFdB5LRwI1uUruyJ
```

Example request (JSON):
```json
{"exp_month": 9, "exp_year": 2025}
```

Response:
```json
{"result":"success"}
```
---

<a name="delete"/>

### Delete card

```
DELETE /api/users/:user_id/cards/card_1Gl0ydA9eFdB5LRwI1uUruyJ
```

Example request (JSON):
```json
{}
```

Response:
```json
{"result":"success"}
```
