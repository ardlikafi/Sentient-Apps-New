# Sentient API Documentation

## Overview
This document provides comprehensive documentation for the Sentient API. The API follows REST principles and uses JSON for request and response bodies.

## Base URL
```
http://localhost:8000/api
```

## Authentication

### Current Implementation (Simple Token)
Currently using a simple base64 encoded token in format: `base64(userId|timestamp)`

### Planned JWT Implementation
Will be implemented using `tymon/jwt-auth` package with the following endpoints:

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
    "username": "string",
    "email": "string",
    "password": "string"
}
```

Response:
```json
{
    "success": true,
    "message": "Register berhasil",
    "user": {
        "id": "integer",
        "username": "string",
        "email": "string",
        "created_at": "datetime"
    },
    "profile": {
        "id": "integer",
        "user_id": "integer",
        "username": "string",
        "bio": "string|null",
        "avatar": "string|null"
    },
    "token": "jwt_token_string"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
    "email": "string",
    "password": "string"
}
```

Response: Same as register

#### Get Profile
```http
GET /api/auth/profile
Authorization: Bearer {jwt_token}
```

Response:
```json
{
    "success": true,
    "user": {
        "id": "integer",
        "username": "string",
        "email": "string"
    },
    "profile": {
        "id": "integer",
        "username": "string",
        "bio": "string|null",
        "avatar": "string|null"
    }
}
```

#### Update Avatar
```http
POST /api/auth/profile/avatar
Authorization: Bearer {jwt_token}
Content-Type: multipart/form-data

avatar: file
```

Response:
```json
{
    "success": true,
    "message": "Avatar berhasil diupdate",
    "profile": {
        "id": "integer",
        "username": "string",
        "avatar": "string"
    }
}
```

## Courses

### Get Public Courses
```http
GET /api/courses
```

Response:
```json
{
    "success": true,
    "courses": [
        {
            "id": "integer",
            "title": "string",
            "description": "string|null",
            "price": "decimal",
            "image_url": "string|null"
        }
    ]
}
```

## Planned Endpoints

### Course Progress
```http
POST /api/courses/{courseId}/enroll
Authorization: Bearer {jwt_token}

GET /api/courses/{courseId}/progress
Authorization: Bearer {jwt_token}

POST /api/courses/{courseId}/progress
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
    "lesson_id": "integer",
    "status": "string" // completed, in_progress
}
```

## Error Responses

All endpoints may return the following error responses:

```json
{
    "success": false,
    "message": "Error message"
}
```

Common HTTP Status Codes:
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 422: Validation Error
- 500: Server Error

## Testing

Postman collection will be provided in `postman/Sentient_API.postman_collection.json`

## Versioning
API versioning will be implemented in the future using URL versioning:
```
http://localhost:8000/api/v1/
```

## Support
For API support or questions, please contact the development team.

---

*Note: This documentation is a work in progress and will be updated as new features are implemented.* 