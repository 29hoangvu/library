<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<footer class="animated-gradient border-t border-slate-800/70 mt-20 relative overflow-hidden">
    <!-- glow background -->
    <div class="footer-glow-1"></div>
    <div class="footer-glow-2"></div>

    <div class="container-enhanced py-10 relative z-10">
        <!-- Logo + tagline -->
        <div class="flex flex-col md:flex-row items-center justify-between gap-6 mb-10">
            <div class="flex items-center gap-4">
                <div
                    class="w-14 h-14 rounded-2xl bg-white/10 border border-white/20 flex items-center justify-center shadow-lg shadow-slate-900/60">
                    <i class="fas fa-book-reader text-2xl text-amber-300"></i>
                </div>
                <div>
                    <h3 class="text-2xl font-bold tracking-tight text-white">
                        Thư viện Số
                    </h3>
                    <p class="text-sm text-slate-200/80">
                        Nơi tri thức không giới hạn
                    </p>
                </div>
            </div>

            <div class="hidden md:flex items-center gap-3 text-xs text-slate-200/70 bg-white/5 px-4 py-2 rounded-full border border-white/10 backdrop-blur">
                <i class="fas fa-bolt text-amber-300"></i>
                <span>Luôn mở 24/7 • Hơn 3.000+ đầu sách</span>
            </div>
        </div>

        <!-- 3 columns -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8">
            <!-- Liên hệ -->
            <div class="footer-card">
                <h4 class="footer-title">
                    <span class="footer-title-icon bg-emerald-500/15 text-emerald-300">
                        <i class="fas fa-headset"></i>
                    </span>
                    <span>Liên hệ</span>
                </h4>
                <div class="space-y-2 text-sm text-slate-100/80">
                    <p><i class="fas fa-phone mr-2 text-emerald-300"></i>+84 123 456 789</p>
                    <p><i class="fas fa-envelope mr-2 text-sky-300"></i>info@thuvienso.com</p>
                    <p><i class="fas fa-map-marker-alt mr-2 text-rose-300"></i>Cần Thơ, Việt Nam</p>
                </div>
            </div>

            <!-- Danh mục -->
            <div class="footer-card">
                <h4 class="footer-title">
                    <span class="footer-title-icon bg-indigo-500/15 text-indigo-300">
                        <i class="fas fa-layer-group"></i>
                    </span>
                    <span>Danh mục</span>
                </h4>
                <div class="space-y-2 text-sm text-slate-100/80">
                    <a href="?category=HARDCOVER"
                       class="footer-link">
                        <i class="fas fa-book mr-2"></i>Sách Bìa Cứng
                    </a>
                    <a href="?category=PAPERBACK"
                       class="footer-link">
                        <i class="fas fa-book-open mr-2"></i>Sách Bìa Mềm
                    </a>
                    <a href="?category=EBOOK"
                       class="footer-link">
                        <i class="fas fa-tablet-alt mr-2"></i>Ebook
                    </a>
                </div>
            </div>

            <!-- Social -->
            <div class="footer-card">
                <h4 class="footer-title">
                    <span class="footer-title-icon bg-amber-500/15 text-amber-300">
                        <i class="fas fa-share-alt"></i>
                    </span>
                    <span>Theo dõi chúng tôi</span>
                </h4>
                <div class="flex flex-wrap gap-3">
                    <a href="#"
                       class="social-pill">
                        <i class="fab fa-facebook-f"></i>
                    </a>
                    <a href="#"
                       class="social-pill">
                        <i class="fab fa-twitter"></i>
                    </a>
                    <a href="#"
                       class="social-pill">
                        <i class="fab fa-instagram"></i>
                    </a>
                    <a href="#"
                       class="social-pill">
                        <i class="fab fa-youtube"></i>
                    </a>
                </div>
            </div>
        </div>

        <!-- Bottom line -->
        <div class="border-t border-slate-700/60 pt-6 mt-4 flex flex-col md:flex-row justify-between items-center gap-4 text-sm text-slate-300/80">
            <p class="text-center md:text-left">
                © 2024 Thư viện Số. Tất cả các quyền được bảo lưu.
            </p>
            <div class="flex flex-wrap justify-center md:justify-end gap-5">
                <a href="#" class="footer-bottom-link">Điều khoản sử dụng</a>
                <a href="#" class="footer-bottom-link">Chính sách bảo mật</a>
                <a href="#" class="footer-bottom-link">Hỗ trợ</a>
            </div>
        </div>
    </div>
</footer>
