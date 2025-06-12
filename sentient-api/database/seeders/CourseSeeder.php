<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Course;

class CourseSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        Course::truncate();
        Course::insert([
            [
                'title' => 'Mastering Chess Fundamentals',
                'category' => 'Beginner',
                'price' => 100000,
                'rating' => 4.5,
                'reviewCount' => 50,
                'description' => 'Learn the complete basics of chess with this comprehensive guide. Perfect for beginners who want to start their chess journey.',
                'content' => 'Fundamental chess concepts, rules, and strategies.',
                'youtube_url' => 'https://www.youtube.com/watch?v=NAIQyoPcjNM',
                'user_id' => null,
            ],
            [
                'title' => 'Tactical Patterns & Strategy',
                'category' => 'Intermediate',
                'price' => 0,
                'rating' => 4.8,
                'reviewCount' => 75,
                'description' => 'Master essential tactical patterns and strategic concepts to improve your game.',
                'content' => 'Tactical patterns, forks, pins, skewers, and more.',
                'youtube_url' => 'https://www.youtube.com/watch?v=6h5Z0Uc-CnQ',
                'user_id' => null,
            ],
            [
                'title' => 'Opening Repertoire for All Levels',
                'category' => 'Expert',
                'price' => 400000,
                'rating' => 4.2,
                'reviewCount' => 30,
                'description' => 'Build a strong opening repertoire with proven strategies for all levels.',
                'content' => 'Openings for white and black, traps, and counters.',
                'youtube_url' => 'https://www.youtube.com/watch?v=6h5Z0Uc-CnQ',
                'user_id' => null,
            ],
            [
                'title' => 'Free Basic Chess Rules',
                'category' => 'Beginner',
                'price' => 0,
                'rating' => 4.0,
                'reviewCount' => 120,
                'description' => 'Start your chess journey with this free course covering all the basic rules and concepts.',
                'content' => 'Basic rules, piece movement, and checkmate.',
                'youtube_url' => 'https://www.youtube.com/watch?v=Reza8udb47Y',
                'user_id' => null,
            ],
            [
                'title' => 'Advanced Endgame Techniques',
                'category' => 'Expert',
                'price' => 350000,
                'rating' => 4.9,
                'reviewCount' => 90,
                'description' => 'Master the art of endgame play with advanced techniques and strategies.',
                'content' => 'Endgame theory, king and pawn endings, and more.',
                'youtube_url' => 'https://www.youtube.com/watch?v=MA8Scue28Ks',
                'user_id' => null,
            ],
        ]);
    }
}
