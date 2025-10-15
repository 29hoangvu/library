<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>404 - Không tìm thấy trang</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="icon" href="./images/reading-book.png" type="image/x-icon" />
    <style>
        @keyframes float {
            0%, 100% { transform: translateY(0px) rotate(0deg); }
            50% { transform: translateY(-20px) rotate(2deg); }
        }
        
        @keyframes pulse-glow {
            0%, 100% { 
                box-shadow: 0 0 20px rgba(59, 130, 246, 0.3);
                transform: scale(1);
            }
            50% { 
                box-shadow: 0 0 40px rgba(59, 130, 246, 0.6);
                transform: scale(1.02);
            }
        }
        
        @keyframes slideInUp {
            from {
                opacity: 0;
                transform: translateY(50px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        @keyframes fadeInDown {
            from {
                opacity: 0;
                transform: translateY(-30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        @keyframes bounce-slow {
            0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
            40% { transform: translateY(-10px); }
            60% { transform: translateY(-5px); }
        }
        
        @keyframes gradient-shift {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        
        @keyframes sparkle {
            0% { opacity: 0; transform: scale(0) rotate(0deg); }
            50% { opacity: 1; transform: scale(1) rotate(180deg); }
            100% { opacity: 0; transform: scale(0) rotate(360deg); }
        }
        
        .gradient-bg {
            background: 
                linear-gradient(135deg, rgba(102, 126, 234, 0.7), rgba(118, 75, 162, 0.7), rgba(240, 147, 251, 0.7), rgba(245, 87, 108, 0.7)),
                url('https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2026&q=80');
            background-size: 400% 400%, cover;
            background-position: center;
            background-attachment: fixed;
            animation: gradient-shift 8s ease infinite;
        }
        
        @media (max-width: 768px) {
            .gradient-bg {
                background-attachment: scroll;
            }
        }
        
        .floating { animation: float 6s ease-in-out infinite; }
        .pulse-glow { animation: pulse-glow 2s ease-in-out infinite; }
        .slide-up { animation: slideInUp 0.8s ease-out; }
        .fade-down { animation: fadeInDown 0.6s ease-out; }
        .bounce-slow { animation: bounce-slow 2s infinite; }
        
        .sparkle {
            position: absolute;
            width: 4px;
            height: 4px;
            background: white;
            border-radius: 50%;
            animation: sparkle 2s infinite;
        }
        
        .sparkle:nth-child(1) { top: 20%; left: 20%; animation-delay: 0s; }
        .sparkle:nth-child(2) { top: 30%; right: 25%; animation-delay: 0.5s; }
        .sparkle:nth-child(3) { bottom: 40%; left: 30%; animation-delay: 1s; }
        .sparkle:nth-child(4) { top: 60%; right: 15%; animation-delay: 1.5s; }
        .sparkle:nth-child(5) { bottom: 20%; right: 40%; animation-delay: 2s; }
        
        .glass-effect {
            background: rgba(255, 255, 255, 0.08);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.15);
            box-shadow: 0 25px 45px rgba(0, 0, 0, 0.1);
        }
        
        .hover-lift {
            transition: all 0.3s ease;
        }
        
        .hover-lift:hover {
            transform: translateY(-5px) scale(1.05);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
        }
        
        .text-shadow {
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        
        .delay-100 { animation-delay: 0.1s; }
        .delay-200 { animation-delay: 0.2s; }
        .delay-300 { animation-delay: 0.3s; }
    </style>
</head>
<body class="gradient-bg min-h-screen flex items-center justify-center px-4 relative overflow-hidden">
    
    <!-- Overlay for better readability -->
    <div class="absolute inset-0 bg-black/20"></div>
    
    <!-- Animated particles background -->
    <div class="absolute inset-0 overflow-hidden pointer-events-none">
        <div class="absolute w-full h-full">
            <div class="absolute top-10 left-10 w-2 h-2 bg-white/40 rounded-full floating" style="animation-duration: 8s; animation-delay: 0s;"></div>
            <div class="absolute top-20 right-16 w-1 h-1 bg-white/60 rounded-full floating" style="animation-duration: 6s; animation-delay: 1s;"></div>
            <div class="absolute top-32 left-1/3 w-3 h-3 bg-white/30 rounded-full floating" style="animation-duration: 10s; animation-delay: 2s;"></div>
            <div class="absolute bottom-20 right-20 w-2 h-2 bg-white/50 rounded-full floating" style="animation-duration: 7s; animation-delay: 3s;"></div>
            <div class="absolute bottom-32 left-16 w-1 h-1 bg-white/70 rounded-full floating" style="animation-duration: 9s; animation-delay: 4s;"></div>
            <div class="absolute top-1/2 right-10 w-2 h-2 bg-white/40 rounded-full floating" style="animation-duration: 8s; animation-delay: 5s;"></div>
        </div>
    </div>
    
    <!-- Sparkle Effects -->
    <div class="sparkle"></div>
    <div class="sparkle"></div>
    <div class="sparkle"></div>
    <div class="sparkle"></div>
    <div class="sparkle"></div>
    
    <!-- Main Content -->
    <div class="max-w-2xl mx-auto text-center relative z-10">
        
        <!-- Glass Container -->
        <div class="glass-effect rounded-3xl p-12 slide-up hover-lift">
            
            <!-- 404 Number with Animation -->
            <div class="floating mb-8">
                <h1 class="text-8xl md:text-9xl font-black text-white text-shadow mb-4 select-none">
                    4<span class="inline-block bounce-slow delay-100">0</span>4
                </h1>
            </div>
            
            <!-- Title -->
            <h2 class="text-3xl md:text-4xl font-bold text-white mb-4 fade-down delay-100">
                Ôi không! Trang không tồn tại 🚀
            </h2>
            
            <!-- Description -->
            <p class="text-lg text-white/95 mb-8 leading-relaxed fade-down delay-200 max-w-md mx-auto font-medium">
                Có vẻ như bạn đã lạc vào không gian vũ trụ. Đừng lo lắng, chúng tôi sẽ đưa bạn về nhà an toàn! ✨
            </p>
            
            <!-- Buttons -->
            <div class="space-y-4 md:space-y-0 md:space-x-4 md:flex md:justify-center items-center fade-down delay-300">
                <a href="<%= request.getContextPath() %>/index.jsp"
                   class="inline-block bg-white/20 hover:bg-white/30 text-white px-8 py-4 rounded-full font-semibold 
                          transition-all duration-300 transform hover:scale-105 pulse-glow border border-white/30
                          backdrop-filter backdrop-blur-sm">
                    🏠 Về trang chủ
                </a>
                
                <button onclick="history.back()" 
                        class="inline-block bg-transparent hover:bg-white/10 text-white px-8 py-4 rounded-full 
                               font-semibold border-2 border-white/50 hover:border-white transition-all duration-300
                               transform hover:scale-105">
                    ← Quay lại
                </button>
            </div>
            
            <!-- Fun Elements -->
            <div class="mt-12 flex justify-center space-x-8 text-4xl">
                <span class="floating" style="animation-delay: 0s;">🌟</span>
                <span class="floating" style="animation-delay: 1s;">🚀</span>
                <span class="floating" style="animation-delay: 2s;">🌙</span>
            </div>
            
        </div>
        
        <!-- Additional Info -->
        <div class="mt-8 fade-down delay-300">
            <p class="text-white/70 text-sm">
                Mã lỗi: 404 | Thời gian: <span id="current-time"></span>
            </p>
        </div>
        
    </div>
    
    <!-- Floating Elements Background -->
    <div class="absolute inset-0 pointer-events-none overflow-hidden">
        <div class="absolute top-1/4 left-1/4 w-2 h-2 bg-white/30 rounded-full floating" style="animation-delay: 0s;"></div>
        <div class="absolute top-1/3 right-1/4 w-1 h-1 bg-white/40 rounded-full floating" style="animation-delay: 1s;"></div>
        <div class="absolute bottom-1/4 left-1/3 w-3 h-3 bg-white/20 rounded-full floating" style="animation-delay: 2s;"></div>
        <div class="absolute top-1/2 right-1/3 w-1 h-1 bg-white/50 rounded-full floating" style="animation-delay: 3s;"></div>
        <div class="absolute bottom-1/3 right-1/5 w-2 h-2 bg-white/30 rounded-full floating" style="animation-delay: 4s;"></div>
    </div>
    
    <script>
        // Update current time
        function updateTime() {
            const now = new Date();
            document.getElementById('current-time').textContent = now.toLocaleTimeString('vi-VN');
        }
        
        updateTime();
        setInterval(updateTime, 1000);
        
        // Add subtle mouse parallax effect
        document.addEventListener('mousemove', (e) => {
            const { clientX, clientY } = e;
            const centerX = window.innerWidth / 2;
            const centerY = window.innerHeight / 2;
            
            const deltaX = (clientX - centerX) / centerX;
            const deltaY = (clientY - centerY) / centerY;
            
            const floatingElements = document.querySelectorAll('.floating');
            floatingElements.forEach((el, index) => {
                const speed = (index + 1) * 0.5;
                el.style.transform = `translateX(${deltaX * speed}px) translateY(${deltaY * speed}px)`;
            });
        });
        
        // Add click animation to buttons
        document.querySelectorAll('a, button').forEach(el => {
            el.addEventListener('click', function(e) {
                const ripple = document.createElement('div');
                ripple.classList.add('absolute', 'bg-white/30', 'rounded-full', 'transform', 'scale-0');
                ripple.style.width = ripple.style.height = '100px';
                ripple.style.left = (e.clientX - el.offsetLeft - 50) + 'px';
                ripple.style.top = (e.clientY - el.offsetTop - 50) + 'px';
                
                el.style.position = 'relative';
                el.style.overflow = 'hidden';
                el.appendChild(ripple);
                
                setTimeout(() => {
                    ripple.classList.add('scale-100');
                    ripple.style.opacity = '0';
                    ripple.style.transition = 'all 0.6s ease-out';
                }, 10);
                
                setTimeout(() => ripple.remove(), 600);
            });
        });
    </script>
</body>
</html>