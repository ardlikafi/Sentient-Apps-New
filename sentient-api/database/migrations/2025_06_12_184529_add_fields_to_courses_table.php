<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('courses', function (Blueprint $table) {
            if (!Schema::hasColumn('courses', 'category')) $table->string('category')->nullable();
            if (!Schema::hasColumn('courses', 'price')) $table->integer('price')->default(0);
            if (!Schema::hasColumn('courses', 'rating')) $table->float('rating')->default(0);
            if (!Schema::hasColumn('courses', 'reviewCount')) $table->integer('reviewCount')->default(0);
            if (!Schema::hasColumn('courses', 'description')) $table->text('description')->nullable();
            if (!Schema::hasColumn('courses', 'content')) $table->text('content')->nullable();
            if (!Schema::hasColumn('courses', 'youtube_url')) $table->string('youtube_url')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('courses', function (Blueprint $table) {
            if (Schema::hasColumn('courses', 'category')) $table->dropColumn('category');
            if (Schema::hasColumn('courses', 'price')) $table->dropColumn('price');
            if (Schema::hasColumn('courses', 'rating')) $table->dropColumn('rating');
            if (Schema::hasColumn('courses', 'reviewCount')) $table->dropColumn('reviewCount');
            if (Schema::hasColumn('courses', 'description')) $table->dropColumn('description');
            if (Schema::hasColumn('courses', 'content')) $table->dropColumn('content');
            if (Schema::hasColumn('courses', 'youtube_url')) $table->dropColumn('youtube_url');
        });
    }
};
