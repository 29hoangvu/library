// ===== FIX: Ẩn loader không chờ tất cả ảnh lazy =====
(function pageLoading() {
    const loader = document.getElementById('page-loader');
    const app = document.getElementById('app-content');
    if (!loader || !app)
        return;

    let finished = false;
    function hide() {
        if (finished)
            return;
        finished = true;
        loader.style.opacity = '0';
        loader.style.transition = 'opacity .25s ease';
        setTimeout(() => {
            loader.style.display = 'none';
        }, 260);
        app.classList.add('loaded'); // lớp này nằm trong loading.css bạn đã link
    }

    // 1) Ẩn khi toàn trang load xong (CSS/JS/ảnh trên-fold)
    window.addEventListener('load', hide, {once: true});

    // 2) Dù sao cũng ẩn sau 2000ms để không kẹt vì ảnh lazy
    setTimeout(hide, 2000);
})();
