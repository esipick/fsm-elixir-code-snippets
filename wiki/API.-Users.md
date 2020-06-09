* [Create User](#create)
* [Assign aircrafts and instructors](#add_aircrafts)
* [Change User password](#change_password)
* [Get Users](#index)
* [Upload avatar example](#upload_avatar)
* [Update user card](#update_card)

<a name="create"/>

# Create User

```
POST /api/users (https://randon-aviation-staging.herokuapp.com/)

Body (JSON):
{
  data: {
    email: "user@example.com",
    first_name: "John",
    last_name: "Doe",
    phone_number: "801-555-5555",
    avatar: "Base64 image"
  },
  role_id: 1,
  aircrafts: [1,2,3], // aircraft ids
  stripe_token: "" // optional
}
```

---

<a name="add_aircrafts" />

# Assign aircrafts and instructors

You can assign one or more aircrafts to user using `aircrafts` field in both `POST create` and `PUT update` requests. Also, one or more instructors can be assigned using `instructors` field. Main instructor can be assigned via `main_instructor_id` field.

Example:
```
POST /api/users (https://randon-aviation-staging.herokuapp.com/)

Body (JSON):
{
  data: {
    email: "user@example.com",
    first_name: "John",
    last_name: "Doe",
    phone_number: "801-555-5555",
    avatar: "Base64 image"
  },
  role_id: 1,
  aircrafts: [1,2,3], // aircraft ids
  instructors: [1,2,3], // instructor ids
  main_instructor_id: 1,
  stripe_token: "" // optional
}
```

Response will be like:

```
data: {
  aircrafts: [
    { id: 1, tail_number: "xxx", ... },
    { id: 2, tail_number: "yyy", ... },
    { id: 3, tail_number: "zzz", ... }
  ],
  instructors: [
    { id: 1, first_name: "xxx", ... },
    { id: 2, first_name: "yyy", ... },
    { id: 3, first_name: "zzz", ... }
  ],
  main_instructor: {
    id: 1,
    first_name: "xxx",
    ...
  }
}
```

---

<a name="change_password"/>

# Change User password

```
PATCH/PUT /api/users/:user_id/change_password
```

Body (JSON):
```json
{
  "data": {
    "password": "current password",
    "new_password": "new password"
  }
}
```

Example response (JSON):
```json
{
  "data": {
    "zipcode": null,
    "stripe_account_id": null,
    "state": null,
    "school_id": 91774,
    "avatar":{
      "thumb":"https://avatars-randon-aviation-staging.s3.amazonaws.com/uploads/prod/user/avatars/thumb/eae7859d-734f-4be5-b274-32752f372a36.png?v=63750017399",
      "original":"https://avatars-randon-aviation-staging.s3.amazonaws.com/uploads/prod/user/avatars/original/eae7859d-734f-4be5-b274-32752f372a36.jpeg?v=63750017399"
    },
    "roles": [
      "student"
    ],
    "phone_number": "801-555-5555",
    "permissions": [
      "appointment_student:modify:personal",
      "appointment_user:modify:personal",
      "invoice:view:personal",
      "objective_score:view:personal",
      "push_token:modify:personal",
      "transaction:view:personal",
      "transaction_approve:modify:personal",
      "transaction_creator:modify:personal",
      "transaction_user:view:personal",
      "users:modify:personal",
      "users:view:personal",
      "web_dashboard:access:all"
    ],
    "medical_rating": 0,
    "medical_expires_at": null,
    "last_name": "some last name",
    "id": 170421,
    "flyer_certificates": [],
    "flight_training_number": null,
    "first_name": "some first name",
    "email": "user-2x1d6urzwhoq-mxllpe2@email.com",
    "city": null,
    "certificate_number": null,
    "balance": 0,
    "awards": null,
    "address_1": null
  }
}
```

---

<a name="index"/>

# Get List of Users

```
GET /api/users&role=role

role is one of `admin`, `dispatcher`, `instructor`, `student`, `renter`
```

Example response (JSON):
```json
{
  "data": [
    {
      "last_name": "Bartoletti",
      "id": 20,
      "first_name": "Ariane",
      "billing_rate": 7500,
      "balance": 0
    },
    { ... }
  ]
}
```

---

<a name="index"/>

# Get User

```
GET /api/users/:user_id

Role is one of `admin`, `dispatcher`, `instructor`, `student`, `renter`
```

Example response (JSON):
```json
{
  "data": {
    "zipcode": null,
    "stripe_account_id": null,
    "state": null,
    "show_student_flight_hours": true,
    "show_student_accounts_summary": true,
    "school_id": 1,
    "roles": [
      "student"
    ],
    "phone_number": "892-757-5960",
    "permissions": [
      "appointment_student:modify:personal",
      "appointment_user:modify:personal",
      "documents:view:personal",
      "invoice:modify:personal",
      "invoice:view:personal",
      "objective_score:view:personal",
      "push_token:modify:personal",
      "school:view:personal",
      "transaction:view:personal",
      "transaction_approve:modify:personal",
      "transaction_creator:modify:personal",
      "transaction_user:view:personal",
      "users:modify:personal",
      "users:view:personal",
      "web_dashboard:access:all"
    ],
    "medical_rating": 0,
    "medical_expires_at": null,
    "main_instructor_id": null,
    "main_instructor": null,
    "last_name": "Toy",
    "instructors": [],
    "id": 15,
    "flyer_certificates": [],
    "flight_training_number": null,
    "first_name": "Camila",
    "email": "student+714cf6de61d1801@gmail.com",
    "city": null,
    "certificate_number": null,
    "balance": 92379,
    "awards": null,
    "avatar": {
      "thumb": null,
      "original": null
    },
  "aircrafts": [],
  "address_1": null
  }
}
```

---

<a name="upload_avatar" />

# Upload avatar example

You can send base64 image as `avatar` field both to `POST create` and `PUT update` endpoints. Example:
```
curl -X PUT --include 'https://randon-aviation-staging.herokuapp.com/api/users/1' -H 'Authorization: SFMyNTY.g3QAAAACZAAEZGF0YXQAAAACZAAFdG9rZW5tAAAACmV1ZlBOSW1ZQ2hkAAR1c2VyYQFkAAZzaWduZWRuBgAfZaSFcAE.-hiFfNd3JfJEBylIa6rMKq7xylZsD__rOHCdmHPyex4' -H 'Content-Type: application/json' -d '{"data":{"avatar":"/9j/4AAQSkZJRgABAQAASABIAAD/4QBARXhpZgAATU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAABkKADAAQAAAABAAABkAAAAAD/7QA4UGhvdG9zaG9wIDMuMAA4QklNBAQAAAAAAAA4QklNBCUAAAAAABDUHYzZjwCyBOmACZjs+EJ+/8AAEQgBkAGQAwERAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/bAEMAAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAf/bAEMBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAf/dAAQAMv/aAAwDAQACEQMRAD8A/vDjtmkJYZ9eB0HP+Rg/Uc/L4KW99NL7d9uj6+t+i0vH2aujqX7u3nd/0+t/LVllYZGHlHP6evGO/wCn5ZJUS1dnfpta+j9ez9fL4Tkm/db7Wf3PfTqSSSiZ2iSMfKBwO5xzwSucHnr+XO6aMPf5Yx6vVLutE9+vW6T+XuefVxX2W7pN27Lazd7W8rLpbTQ/N79vzxZa6X8KNc026kVJL+FoVBYqfkVcEfK5OQw65zzjPNfa5fCzXXS19tO28vvT7LW65awv7yabbeuzWis/LlT69fW9ve/mmaLyI4DHO2GhkcAkEYa4lbgHtkjnP4Lj5vo0moq/d2tt3v1s91q3t0vaP0tHCc1KN9t+lt/L8NX21tciRUl3rINqtwZAeV9wfbrnAGMZxjFdWGqTTSsnrG/R2vZdNLJ6/FfytaXnYvBU1GXktNfn1+XW3ba0kWyuLJzNBcSFc8BjkH6npz05HJ6Fed3tU6kvdsumqv8Apt0/XT4Y/MV8HT0fZr1taS6q2/8Awea9zWtfEEyRlJS8ZDFSwLD7rY3ZwByf7oAPXnHzdqjJq9t1ff8AN/8AAXz2jzfVktk9POP/AMjZ9bXt213j1Fn4okU+Xb3crJjdnc2N3IOflUDAxx+Xoz5J9lbvzK/X5/l+Ccj6quzXkpRt/wCmzUt9fu5d3+kTZHQZYE9xnAI5A/2/xyRW1CjKcpLyv8v/ACZedra7a2vHKrTVFRm2173Vpr8FG3Tvf5NS6Gw1LUVxK08rEfPGpJwXHKqV4yCcZx1zyD0raWBTvZa/4r9d1daaX7dna9pKOMSa28/R28+/y/wt2NT+0biQl7e4maduJoy+4IOccfLtPTGMdwfWuSWWydr3f3v5X6ff6L3XzdVPMIqK1S1utba9F9pb3fZvfmt7ugl9cCNUUPNsjEjksTg4H0I643fgM9a8qplLc5XjJO709fedtk9raLzVtT1aWaQUY+8rW2bjFdP7rvr72qXmtR1pq+8kgyqS5LYLYUjCYOVZQRtBwccHgd6zeU2s7N9G7N7q72e2vTR7vl2l108zj7vvJpva+/ndXWukr2Vu+jJZ/EMsDqq3YcblPlSImByRnGAT0xw49cf3lLKW0tJLu1H5680rqy7cvV+RpiM2jGkldfFu5bK2lraJ9tr/AGtkpUL3xBa3tpcLdWqAFwAyb1/j9h19sDHbHNdWHypRd+V3T0ff5tyXRatarRXuzwcVnXu6yUm799PO/q/N37K6PPLyW2jc/Zj5foXYsQc85yg6ZPrz164r6XDZelCLad7/ADa2ttp/S0+KXy+Kz1XkuaN772dr3uuj30WrV7Wt9oy21xrcFPKE+xwJZF3c5UEEAcAheuCR64zitauEjypSuultPPqlv0ej87k4bNVLXmWra38/OPfvf5oZ4X1e2PjfTZma48qS6YBYncKCba5Kg4QkcfdyAccEnBFfKZjQSTu1u9X0fXsr6f3k3Z6WTPr8uzPl5XdK3bT7tHe3zer+G9jsL611bU/EGoR6dFcO9xqOp+T9ocpEUXU7pny5MKhhGr7csvzAA7+Q3yWLiuRrz07Xvfydno9e97PVH2GDzVJwk5WTTWr21e7V3tbV2t0btY9M0D4CeOfEE0MWnzwJJdD5kN3bn+IKPvXa+vfPseCG8rl5fsvW22vzt/lf8G4+hVzeOjlJdXurdOnTbo/N2PsX4Jf8E+PEXiPVv7S+LF7cWGjKN5sbI21s2qyHLI8TJdXEgVSfNPlDbjg5GKzdXlvp9zae/p1XS7T30scE85V+j1d1fW+2/Jd69UvnrY/RLwv+yR8AvAgsrtNDu9VnsbmNkk1HVp1trPaI9qyxIIVKorAsXcBid3O4Ue0k48z2s2ru+i31um/kr+tmeVWzCU6rnf3eZaa22V03bfR/nfVs9Fbw98CFkm83w34HuZBIVLPqTSM4Cr8qxjUm5GTnCHJYe1YTqyd9rer183/Wg4ZhLTWW+rUtvlZ226Ly0Fl+Hn7Ol2qiXwN4et5J8ET2VtfF1IPmZEyyyLhtuwn5vlYgN/FXM6krvTS+mr69tLr71311NquYVI0pcs3NtpJvW66tR9bbPvpGy5o9R+D/AOz5rFoLS+0C3htNoUG2vZrCUL1HzH58k8Y4Prk/LSdRq7utHv8Araz30dru1teY5I5tioWWsWtkoylpbd69Ot+2ttInjur/APBO79mzxQl9f6TN4hsbm5jcRTRavJforkMV+R4GTALggYbPTjJqlipWs336fds+/Wya83zHQuJcXDTnV0tXya8y2vu/u5vW+h8YfEL/AIJd+LNOhlvfh74ym11xI3k6RqFvpqSCFRjAi+0Wc2ePlb5dwwcHcC29PFqV17tm73XR6vXW610W1+q0kpehh8+rVo805XfzVrO3VN622srLvb3vz0+JnwA+NXwzvbqPxP4D16CKy5/tCC1mWzlxwxjZPtCfcO5gJTjIwDkbu2lyzt71r9v6eq2eq723PUp49zV5P5Nvq9fxb669eW3u+MRXl2t5NbtHJbuIMzQ3BfzPvHPXawPG3jnvxkmvTo4aLlFu9m00vO+nS3fS+2jtrzdjxapw5k0mtO1+t1f+l8kWDM/91c/77jjjoS5HQ+n51eLwvNok3Z7arpfu1o/Tz3scqzdSbSmpLR35vJ2vt30u9fK4y4uL1EGEfGP9o/LjjnrgH3UnrnivPjhpQlezVvJ2ty7292+9um17N6mkcwpTu3KLt15tX5XevmrPRPqmjIa8nkjJkVlIchTyAQAv++M889vftWzhUb2asrb82nXZrTr5+Tu49KxsVDl93XXlUlo36a7LvZ31tczLu8lWSEAMC7AHOeflLc5xyMH14HuBXXTpyTbd0mref/B6bOPqY1MZFaXSd9Nd1quju99reetvdqO895IxA3Ff3PAJ77Rjkcnd09xgngVsqcmmves1bTXR/PvpezvvZWUZcM8bC7bnfXZO34K3Reumt72Gm0uUH3JR6DOP5bfc9s9B3NR9Rm7XjLXVuzd0+2mmlrWvbey5uUz/ALSorTmj+L/Oz/rruVPssy+ZcYlDBjx05zjtnOO+Bx75xQsDPTSfzWi93pvbXut9"}}'
```

In the response there will be avatar object inside user object with two fields with URLs for the thumb and original file, like this:

```
data: {
  ...,
  "avatar":{
    "thumb":"https://avatars-randon-aviation-staging.s3.amazonaws.com/uploads/prod/user/avatars/thumb/eae7859d-734f-4be5-b274-32752f372a36.png?v=63750017399",
    "original":"https://avatars-randon-aviation-staging.s3.amazonaws.com/uploads/prod/user/avatars/original/eae7859d-734f-4be5-b274-32752f372a36.jpeg?v=63750017399"
  },
  ...
}
```

---

<a name="update_card" />

# Update user card

```
PUT /api/users/:user_id/update_card

Body (JSON):
{
  stripe_token: "stripe_token"
}
```
