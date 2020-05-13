* [View Student Documents](#index)
* [Create Document](#create)
* [Update Document](#update)
* [Delete Document](#delete)

<a name="index"/>

# View Student Documents

```
GET /api/users/:student_id/documents
```

Example response (JSON):
```json
{
  "total_pages":1,
  "total_entries":1,
  "page_size":10,
  "page_number":1,
  "documents":[
    {
      "id":19,
      "file_url":"https://avatars-randon-aviation-staging.s3.amazonaws.com/uploads/prod/user/781/documents/19/sample.pdf?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAJOL6R4FAJJ4EQYOA%2F20200513%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20200513T191133Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=ae9be3a5314c16377e279ffe314a506536199ebbd9470e7b0952f618ea948335",
      "file_name":"sample.pdf",
      "expires_at":"2020-05-14",
      "expired":"gt"
    }
  ]
}
```

---

<a name="create"/>

# Create Student Document

Available to Admins and Dispatchers only

```
POST /api/users/:student_id/documents
```

Example request (JSON):
```json
TBD
```

Example response (JSON):
```json
{
  "id":19,
  "file_url":"https://avatars-randon-aviation-staging.s3.amazonaws.com/uploads/prod/user/781/documents/19/sample.pdf?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAJOL6R4FAJJ4EQYOA%2F20200513%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20200513T191952Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=c56a732e73c312b29638987fd52b7aa88b44f25cc1a59977b6498b3f868afd7e",
  "file_name":"sample.pdf",
  "expires_at":"2030-05-03",
  "expired":"gt"
}
```

---

<a name="update"/>

# Update Student Document

Available to Admins and Dispatchers only

```
PUT /api/users/:student_id/documents/:document_id
```

Example request (JSON):
```json
{
  "document": {
    "expires_at": "2030-05-03"
  }
}
```

Example response (JSON):
```json
{
  "id":19,
  "file_url":"https://avatars-randon-aviation-staging.s3.amazonaws.com/uploads/prod/user/781/documents/19/sample.pdf?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAJOL6R4FAJJ4EQYOA%2F20200513%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20200513T191952Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=c56a732e73c312b29638987fd52b7aa88b44f25cc1a59977b6498b3f868afd7e",
  "file_name":"sample.pdf",
  "expires_at":"2030-05-03",
  "expired":"gt"
}
```

---

<a name="delete"/>

# Delete Student Document

Available to Admins and Dispatchers only

```
DELETE /api/users/:student_id/documents/:document_id
```

Example response:
HTTP 204 No content
