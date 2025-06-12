<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CourseController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Auth
Route::post('register', [AuthController::class, 'register']);
Route::post('login', [AuthController::class, 'login']);

// Protected routes
Route::middleware('auth:api')->group(function () {
    Route::get('profile', [AuthController::class, 'profile']);
    Route::apiResource('courses', CourseController::class)->except(['index', 'show']);
});

// Public course routes
Route::get('courses', [CourseController::class, 'index']);
Route::get('courses/{course}', [CourseController::class, 'show']);

Route::middleware('auth:api')->get('/profile', [AuthController::class, 'profile']);
// atau jika menggunakan group
Route::middleware('auth:api')->group(function () {
    Route::get('/profile', [AuthController::class, 'profile']);
});
Route::get('/courses', [CourseController::class, 'index']);
Route::get('/public-courses', [CourseController::class, 'publicIndex']);