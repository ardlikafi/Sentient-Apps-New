<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Course extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'title', 'category', 'price', 'rating', 'reviewCount', 'description', 'content', 'youtube_url',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
} 