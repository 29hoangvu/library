<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Đăng nhập</title>

    <!-- Tailwind CSS -->
        <script src="https://cdn.tailwindcss.com"></script>

        <!-- Font Awesome -->
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

        <!-- Google Fonts -->
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

        <!-- Favicon -->
        <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />

    <style>
        body {
            font-family: 'Inter', sans-serif;
        }
    </style>
</head>
<body class="bg-gradient-to-br from-indigo-100 to-blue-200 min-h-screen flex items-center justify-center p-4">
    
    <div class="bg-white shadow-lg rounded-xl w-full max-w-2xl p-8 h-[450px] overflow-y-auto">
        <!-- Header with grid layout -->
        <div class="grid grid-cols-3 items-center mb-6">
            <div class="flex justify-start">
                <a href="../index.jsp" class="text-gray-500 hover:text-gray-700 transition ml-2">
                    <i class="fa fa-arrow-left text-lg"></i>
                </a>
            </div>

            <h2 class="text-3xl font-semibold text-gray-800 text-center">Đăng nhập</h2>

            <div></div> <!-- Giữ để căn giữa -->
        </div>


        <!-- Form -->
        <form action="../LoginServlet" method="post" class="space-y-5">
            <div class="mt-10">
                <label for="username" class="block text-sm font-medium text-gray-700 mb-1">Tên đăng nhập</label>
                <input autofocus type="text" id="username" name="username" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 transition">
            </div>

            <div>
                <label for="password" class="block text-sm font-medium text-gray-700 mb-1">Mật khẩu</label>
                <input type="password" id="password" name="password" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 transition">
            </div>

            <button type="submit"
                class="w-full py-2 bg-indigo-600 text-white font-medium rounded-md hover:bg-indigo-700 transition">
                Đăng nhập
            </button>
        </form>

        <!-- Footer -->
        <p class="mt-8 text-sm text-center text-gray-600">
            Chưa có tài khoản?
            <a href="register.jsp" class="text-indigo-600 hover:underline font-medium">Đăng ký ngay</a>
        </p>
    </div>
    
</body>
</html>
