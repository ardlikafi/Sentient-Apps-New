<?php

namespace App\Http\Controllers;

use App\Models\Course;
use Illuminate\Http\Request;

class CourseController extends Controller
{
    public function index()
    {
        return Course::all();
    }

    public function publicIndex()
    {
        return response()->json(
            \App\Models\Course::select([
                'id', 'title', 'category', 'price', 'rating', 'reviewCount', 'description', 'content', 'youtube_url'
            ])->get()
        );
    }
} 