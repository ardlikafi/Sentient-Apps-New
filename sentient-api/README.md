<p align="center"><a href="https://laravel.com" target="_blank"><img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400" alt="Laravel Logo"></a></p>

<p align="center">
<a href="https://github.com/laravel/framework/actions"><img src="https://github.com/laravel/framework/workflows/tests/badge.svg" alt="Build Status"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/dt/laravel/framework" alt="Total Downloads"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/v/laravel/framework" alt="Latest Stable Version"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/l/laravel/framework" alt="License"></a>
</p>

## About Laravel

Laravel is a web application framework with expressive, elegant syntax. We believe development must be an enjoyable and creative experience to be truly fulfilling. Laravel takes the pain out of development by easing common tasks used in many web projects, such as:

- [Simple, fast routing engine](https://laravel.com/docs/routing).
- [Powerful dependency injection container](https://laravel.com/docs/container).
- Multiple back-ends for [session](https://laravel.com/docs/session) and [cache](https://laravel.com/docs/cache) storage.
- Expressive, intuitive [database ORM](https://laravel.com/docs/eloquent).
- Database agnostic [schema migrations](https://laravel.com/docs/migrations).
- [Robust background job processing](https://laravel.com/docs/queues).
- [Real-time event broadcasting](https://laravel.com/docs/broadcasting).

Laravel is accessible, powerful, and provides tools required for large, robust applications.

## Learning Laravel

Laravel has the most extensive and thorough [documentation](https://laravel.com/docs) and video tutorial library of all modern web application frameworks, making it a breeze to get started with the framework.

You may also try the [Laravel Bootcamp](https://bootcamp.laravel.com), where you will be guided through building a modern Laravel application from scratch.

If you don't feel like reading, [Laracasts](https://laracasts.com) can help. Laracasts contains thousands of video tutorials on a range of topics including Laravel, modern PHP, unit testing, and JavaScript. Boost your skills by digging into our comprehensive video library.

## Laravel Sponsors

We would like to extend our thanks to the following sponsors for funding Laravel development. If you are interested in becoming a sponsor, please visit the [Laravel Partners program](https://partners.laravel.com).

### Premium Partners

- **[Vehikl](https://vehikl.com)**
- **[Tighten Co.](https://tighten.co)**
- **[Kirschbaum Development Group](https://kirschbaumdevelopment.com)**
- **[64 Robots](https://64robots.com)**
- **[Curotec](https://www.curotec.com/services/technologies/laravel)**
- **[DevSquad](https://devsquad.com/hire-laravel-developers)**
- **[Redberry](https://redberry.international/laravel-development)**
- **[Active Logic](https://activelogic.com)**

## Contributing

Thank you for considering contributing to the Laravel framework! The contribution guide can be found in the [Laravel documentation](https://laravel.com/docs/contributions).

## Code of Conduct

In order to ensure that the Laravel community is welcoming to all, please review and abide by the [Code of Conduct](https://laravel.com/docs/contributions#code-of-conduct).

## Security Vulnerabilities

If you discover a security vulnerability within Laravel, please send an e-mail to Taylor Otwell via [taylor@laravel.com](mailto:taylor@laravel.com). All security vulnerabilities will be promptly addressed.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).

## Course API Documentation

### Public Endpoints

#### Get All Courses
```
GET /api/courses
```
- **Description:** Retrieve a list of all available courses.
- **Authentication:** Not required (public)
- **Response Example:**
```json
{
  "success": true,
  "courses": [
    {
      "id": 1,
      "title": "Mastering Chess Fundamentals",
      "content": "Learn the complete basics of chess...",
      "youtube_url": "https://www.youtube.com/watch?v=NAIQyoPcjNM",
      "user_id": 2,
      "created_at": "2024-06-13T10:00:00Z",
      "updated_at": "2024-06-13T10:00:00Z"
    }
  ]
}
```

#### Get Course Detail
```
GET /api/courses/{id}
```
- **Description:** Retrieve detail of a specific course by ID.
- **Authentication:** Not required (public)
- **Response Example:**
```json
{
  "success": true,
  "course": {
    "id": 1,
    "title": "Mastering Chess Fundamentals",
    "content": "Learn the complete basics of chess...",
    "youtube_url": "https://www.youtube.com/watch?v=NAIQyoPcjNM",
    "user_id": 2,
    "created_at": "2024-06-13T10:00:00Z",
    "updated_at": "2024-06-13T10:00:00Z"
  }
}
```

### Protected Endpoints (Require JWT Auth)

#### Enroll in a Course
```
POST /api/courses/{id}/enroll
Authorization: Bearer {jwt_token}
```
- **Description:** Enroll the authenticated user in a course.
- **Body:** _none_
- **Response Example:**
```json
{
  "success": true,
  "message": "Successfully enrolled in course",
  "data": {
    "course": {
      "id": 1,
      "title": "Mastering Chess Fundamentals"
    },
    "enrollment": {
      "status": "in_progress",
      "progress": 0
    }
  }
}
```

#### Get Course Progress
```
GET /api/courses/{id}/progress
Authorization: Bearer {jwt_token}
```
- **Description:** Get the authenticated user's progress in a course.
- **Response Example:**
```json
{
  "success": true,
  "data": {
    "course": {
      "id": 1,
      "title": "Mastering Chess Fundamentals"
    },
    "enrollment": {
      "status": "in_progress",
      "progress": 33.33
    }
  }
}
```

#### Update Lesson Progress
```
POST /api/courses/{id}/progress
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "lesson_id": 1,
  "status": "completed"
}
```
- **Description:** Update the progress of a lesson in a course.
- **Response Example:**
```json
{
  "success": true,
  "message": "Progress updated successfully",
  "data": {
    "course": {
      "id": 1,
      "title": "Mastering Chess Fundamentals"
    },
    "enrollment": {
      "status": "in_progress",
      "progress": 33.33
    }
  }
}
```

### Error Responses
All endpoints may return the following error responses:
```json
{
  "success": false,
  "message": "Error message"
}
```

### Testing with Postman
- Import the Postman collection from `postman/Sentient_API.postman_collection.json`.
- Set the `base_url` variable to your API server (e.g., `http://localhost:8000`).
- Use the provided endpoints to test course APIs.

### Notes
- Public endpoints can be accessed by anyone.
- Protected endpoints require JWT authentication (login to get token).
- For more details, see `API_DOCUMENTATION.md` or contact the development team.
