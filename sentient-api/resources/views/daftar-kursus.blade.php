<!DOCTYPE html>
<html>
<head>
    <title>Daftar Kursus</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f7f7f7; }
        h1 { text-align: center; margin-top: 30px; }
        .grid { display: flex; flex-wrap: wrap; gap: 24px; justify-content: center; margin: 40px 0; }
        .card { border: 1px solid #ccc; border-radius: 10px; width: 320px; padding: 18px; background: #fff; box-shadow: 0 2px 8px #0001; display: flex; flex-direction: column; align-items: center; }
        .card img { width: 100%; height: 180px; object-fit: cover; border-radius: 8px; }
        .title { font-weight: bold; font-size: 22px; margin: 12px 0 8px 0; text-align: center; }
        .desc { color: #555; font-size: 15px; margin-bottom: 10px; text-align: center; }
        .price { font-weight: bold; color: #0a7; font-size: 16px; margin-bottom: 6px; }
    </style>
</head>
<body>
    <h1>Daftar Kursus</h1>
    <div class="grid">
        @foreach($courses as $course)
            <div class="card">
                <img src="{{ $course['image_url'] }}" alt="{{ $course['title'] }}">
                <div class="title">{{ $course['title'] }}</div>
                <div class="desc">{{ $course['description'] }}</div>
                <div class="price">Harga: Rp{{ number_format($course['price'],0,',','.') }}</div>
            </div>
        @endforeach
    </div>
</body>
</html> 