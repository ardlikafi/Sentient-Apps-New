<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Tymon\JWTAuth\Facades\JWTAuth;
use Illuminate\Support\Facades\Auth; // Masih perlu jika menggunakan helper auth()

class AuthController extends Controller
{
    // ... (konstruktor jika ada) ...

    // Register (kode ini terlihat sudah benar berdasarkan log 201)
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'username' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::create([
            'username' => $request->username,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        // Pastikan model User mengimplementasikan Tymon\JWTAuth\Contracts\JWTSubject
        $token = JWTAuth::fromUser($user); // Gunakan JWTAuth facade untuk user baru

        return response()->json([
            'status' => 'success',
            'message' => 'User registered',
            'user' => $user,
            'token' => $token
        ], 201);
    }

    // Login - KODE YANG DIPERBAIKI
    public function login(Request $request)
    {
        $credentials = $request->only('email', 'password');

        // Coba autentikasi menggunakan guard 'api' (JWT).
        // JWTAuth::attempt() akan mencoba autentikasi user dan mengembalikan token
        // jika berhasil, atau false jika gagal.
        if (!$token = JWTAuth::attempt($credentials)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid credentials'
            ], 401); // 401 Unauthorized untuk kredensial salah
        }

        // Autentikasi berhasil. Ambil user yang sedang terautentikasi
        // menggunakan helper auth() dengan menentukan guard 'api'.
        $user = auth('api')->user();

        return response()->json([
            'status' => 'success',
            'message' => 'Login successful',
            'user' => $user,
            'token' => $token
        ]); // Default status 200 OK
    }

    // Profile (Protected) - KODE YANG DIPERBAIKI
    public function profile()
    {
        // Ambil user yang sedang terautentikasi menggunakan helper auth()
        // Middleware 'auth:api' harus terpasang pada route ini.
        // Helper auth('api')->user() akan mengembalikan user dari guard 'api'
        // jika sudah terautentikasi, atau null jika tidak.
        $user = auth('api')->user();

        // Jika tidak ada user (middleware gagal atau token invalid/expired)
        if (!$user) {
             return response()->json(['status' => 'error', 'message' => 'Unauthenticated.'], 401);
        }

        return response()->json([
            'status' => 'success',
            'user' => $user
        ]);
    }

    // Tambahkan method lain jika perlu, misal logout
    public function logout()
    {
        auth('api')->logout(); // Logout dari guard 'api'

        return response()->json(['message' => 'Successfully logged out']);
    }

     // Tambahkan method lain jika perlu, misal refresh token
    public function refresh()
    {
        // Refresh token dan ambil user
        $token = auth('api')->refresh();
        $user = auth('api')->user();

        return response()->json([
            'status' => 'success',
            'user' => $user,
            'token' => $token
        ]);
    }
}