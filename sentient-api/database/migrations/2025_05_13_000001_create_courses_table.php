<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('courses', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->nullable();
            $table->string('title');
            $table->string('category')->nullable();
            $table->integer('price')->default(0);
            $table->float('rating')->default(0);
            $table->integer('reviewCount')->default(0);
            $table->text('description')->nullable();
            $table->text('content')->nullable();
            $table->string('youtube_url')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down()
    {
        Schema::dropIfExists('courses');
    }
}; 