<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Http;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/daftar-kursus', function () {
    $response = Http::get('http://192.168.1.5:8000/api/public-courses');
    $courses = $response->json()['courses'];
    return view('daftar-kursus', compact('courses'));
});
