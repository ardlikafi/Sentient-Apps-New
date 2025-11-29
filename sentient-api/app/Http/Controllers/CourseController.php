<?php

namespace App\Http\Controllers;

use App\Models\Course;
use Illuminate\Http\Request;

class CourseController extends Controller
{
    // Tambahkan fungsi ini di dalam class CourseController
    public function store(Request $request)
    {
        // 1. Validasi input (Biar server gak error kalau data kosong)
        $request->validate([
            'title' => 'required',
            'category' => 'required',
            'content' => 'required',
            'user_id' => 'required|exists:users,id', // Pastikan user_id valid
        ]);

        // 2. Simpan data ke Database
        $course = \App\Models\Course::create([
            'user_id' => $request->user_id,
            'title' => $request->title,
            'category' => $request->category,
            'price' => $request->price ?? 0, // Default 0 kalau kosong
            'rating' => $request->rating ?? 0,
            'reviewCount' => $request->reviewCount ?? 0,
            'description' => $request->description,
            'content' => $request->content,
            'youtube_url' => $request->youtube_url,
        ]);

        // 3. Balikin respon JSON sukses
        return response()->json([
            'status' => 'success',
            'message' => 'Course created successfully',
            'data' => $course
        ], 201);
    }
}