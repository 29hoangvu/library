<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="Servlet.DBConnection, Data.Users" %>

<%
    request.setAttribute("pageTitle", "Quản lý sách - Admin");
%>
<%@ include file="../includes/header.jsp" %>
<style>
@keyframes slideIn {
    from {
        opacity: 0;
        transform: translateY(-20px) scale(0.95);
    }
    to {
        opacity: 1;
        transform: translateY(0) scale(1);
    }
}

#excelResultPopup.show {
    display: flex;
    animation: slideIn 0.25s ease-out;
}

</style>
<!-- Content của trang admin -->
<main class="transition-all duration-300 pt-32" id="mainContent">
    <section class="bg-gradient-to-br from-blue-50 to-indigo-50 py-10 px-4 sm:px-6">
        <div class="max-w-5xl mx-auto">
            <!-- Header section -->
            <div class="mb-8 text-center">
                <h1 class="text-3xl font-bold text-gray-900 mb-2">Quản lý Thư viện</h1>
                <p class="text-gray-600 max-w-2xl mx-auto">Thêm sách mới vào hệ thống thư viện với thông tin chi tiết và đầy đủ</p>
            </div>
            
            <!-- Main form card -->
            <div class="bg-white rounded-2xl shadow-xl overflow-hidden">
                <div class="bg-gradient-to-r from-blue-600 to-indigo-700 px-8 py-6">
                    <h2 class="text-2xl font-bold text-white">Thêm sách mới</h2>
                    <p class="text-blue-100 mt-1">Điền thông tin sách hoặc sử dụng tính năng đọc từ ảnh</p>
                </div>
                
                <div class="p-8">
                    <!-- Smart input section -->
                    <div class="bg-gradient-to-r from-purple-50 to-indigo-50 rounded-xl p-6 mb-8 border border-purple-100">
                        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
                            <div>
                                <h3 class="text-lg font-semibold text-gray-800">Nhập thông minh</h3>
                                <p class="text-gray-600 text-sm mt-1">Sử dụng AI để quét thông tin từ ảnh bìa sách</p>
                            </div>
                            <div class="flex items-center gap-3">
                                
                                <button id="openImgModal" type="button"
                                        class="px-5 py-2.5 rounded-lg bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white font-medium shadow-md transition-all duration-300 flex items-center gap-2">
                                    <i class="fa-solid fa-camera"></i>
                                    Đọc từ ảnh (Gemini)
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- POPUP CHỌN ẢNH BÌA (KÉO-THẢ/CHỌN FILE) -->
                    <div id="imgModal" class="fixed inset-0 z-[9999] hidden">
                        <div class="absolute inset-0 bg-black/70 backdrop-blur-sm transition-opacity duration-300"></div>

                        <div class="absolute inset-0 flex items-center justify-center p-4">
                            <div class="w-full max-w-3xl bg-white rounded-2xl shadow-2xl overflow-hidden transform transition-all duration-300 scale-95 opacity-0">
                                <div class="flex items-center justify-between px-6 py-5 border-b bg-gradient-to-r from-purple-600 to-indigo-700">
                                    <h3 class="text-xl font-bold text-white">Chọn ảnh bìa để đọc thông tin</h3>
                                    <button id="closeImgModal" class="p-2 rounded-full hover:bg-purple-500 transition-colors" type="button" aria-label="Đóng">
                                        <i class="fa-solid fa-xmark text-white text-lg"></i>
                                    </button>
                                </div>

                                <div class="px-6 py-6 grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <!-- Dropzone Bìa sau -->
                                    <label for="imgBack"
                                           class="dropzone back-zone block w-full border-2 border-dashed border-purple-300 rounded-xl p-6
                                                  text-center cursor-pointer hover:border-purple-500 transition-all duration-300 bg-purple-50 hover:bg-purple-100">
                                        <div class="flex flex-col items-center gap-3">
                                            <div class="w-16 h-16 rounded-full bg-gradient-to-r from-purple-500 to-indigo-500 flex items-center justify-center">
                                                <i class="fa-solid fa-barcode text-2xl text-white"></i>
                                            </div>
                                            <div class="text-base font-medium text-gray-800">
                                                Bìa sau (có mã vạch/ISBN)
                                            </div>
                                            <div class="text-sm text-gray-600">Kéo thả ảnh hoặc <span class="font-semibold text-purple-600">chọn file</span></div>
                                            <div id="imgBackPreview" class="mt-3 text-xs text-gray-700"></div>
                                        </div>
                                        <input id="imgBack" type="file" accept="image/*" class="hidden">
                                    </label>

                                    <!-- Dropzone Bìa trước -->
                                    <label for="imgFront"
                                           class="dropzone front-zone block w-full border-2 border-dashed border-blue-300 rounded-xl p-6
                                                  text-center cursor-pointer hover:border-blue-500 transition-all duration-300 bg-blue-50 hover:bg-blue-100">
                                        <div class="flex flex-col items-center gap-3">
                                            <div class="w-16 h-16 rounded-full bg-gradient-to-r from-blue-500 to-cyan-500 flex items-center justify-center">
                                                <i class="fa-solid fa-image text-2xl text-white"></i>
                                            </div>
                                            <div class="text-base font-medium text-gray-800">
                                                Bìa trước (tiêu đề/tác giả)
                                            </div>
                                            <div class="text-sm text-gray-600">Kéo thả ảnh hoặc <span class="font-semibold text-blue-600">chọn file</span></div>
                                            <div id="imgFrontPreview" class="mt-3 text-xs text-gray-700"></div>
                                        </div>
                                        <input id="imgFront" type="file" accept="image/*" class="hidden">
                                    </label>
                                </div>

                                <div class="px-6 py-5 border-t bg-gray-50 flex items-center justify-between gap-3">
                                    <p class="text-sm text-gray-600">Có thể chọn 1 hoặc 2 ảnh. Hệ thống sẽ ưu tiên đọc từ bìa sau trước.</p>
                                    <div class="flex items-center gap-3">
                                        <button type="button" id="cancelImgModal"
                                                class="px-5 py-2.5 rounded-lg border border-gray-300 hover:bg-gray-100 text-gray-700 font-medium transition-colors">Hủy</button>
                                        <button type="button" id="readNow"
                                                class="px-5 py-2.5 rounded-lg bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white font-medium shadow-md transition-all duration-300
                                                       inline-flex items-center gap-2">
                                            <i class="fa-solid fa-wand-magic-sparkles"></i> Đọc ngay
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <script>
                        document.addEventListener("DOMContentLoaded", () => {
                            // ====== API ENDPPOINTS ======
                            const API_EXTRACT_GEMINI = "http://localhost:8000/extract-gemini";
                            const API_ENRICH         = "http://localhost:8000/enrich";

                            // ====== Helpers: lấy form fields (lúc này DOM đã sẵn sàng) ======
                            const F = {
                                isbn: document.querySelector('input[name="isbn"]'),
                                title: document.querySelector('input[name="title"]'),
                                authorName: document.querySelector('input[name="authorName"]'),
                                authorId: document.getElementById('authorId'),
                                isNewAuthor: document.getElementById('isNewAuthor'),
                                publisher: document.querySelector('input[name="publisher"]'),
                                publicationYear: document.querySelector('input[name="publicationYear"]'),
                                numberOfPages: document.querySelector('input[name="numberOfPages"]'),
                                format: document.querySelector('select[name="format"]'),
                                language: document.querySelector('input[name="language"]'),
                                genreInput: document.getElementById('genreInput'),
                                genreWrap: document.getElementById('selectedGenres'),
                                genreIds: document.getElementById('genreIds'),
                                newGenres: document.getElementById('newGenres'),
                                overwrite: document.getElementById('overwrite'),
                                ebookBlock: document.getElementById('ebookFileBlock'),
                                qtyBlock:   document.getElementById('qtyBlock'),
                                qtyInput:   document.getElementById('quantity')
                            };

                            function applyFormatUI() {
                                const isE = (F.format?.value || "").toUpperCase() === "EBOOK";
                                if (F.ebookBlock) F.ebookBlock.classList.toggle("hidden", !isE);
                                if (F.qtyBlock)   F.qtyBlock.classList.toggle("hidden", isE);
                                if (F.qtyInput) {
                                    if (isE) {
                                        F.qtyInput.value = "1";
                                        F.qtyInput.setAttribute("readonly", "readonly");
                                        F.qtyInput.removeAttribute("required");
                                    } else {
                                        F.qtyInput.removeAttribute("readonly");
                                        F.qtyInput.setAttribute("required", "required");
                                        if (!F.qtyInput.value) F.qtyInput.value = "1";
                                    }
                                }
                            }
                            F.format?.addEventListener("change", applyFormatUI);
                            applyFormatUI();

                            // ====== Clear toàn bộ input trước khi đọc ======
                            function clearBookForm() {
                                [F.isbn, F.title, F.authorName, F.publisher, F.publicationYear,
                                F.numberOfPages, F.language].forEach(el => { if (el) el.value = ""; });
                                if (F.authorId) F.authorId.value = "";
                                if (F.isNewAuthor) F.isNewAuthor.value = "false";
                                if (F.format) F.format.value = "";
                                applyFormatUI();
                                if (F.qtyInput) { F.qtyInput.value = ""; F.qtyInput.removeAttribute("readonly"); }
                                if (F.genreWrap) F.genreWrap.innerHTML = "";
                                if (F.genreIds)  F.genreIds.value = "";
                                if (F.newGenres) F.newGenres.value = "";
                            }

                            // ====== Chuẩn hoá dữ liệu trả về từ API ======
                            function normalizeExtract(raw) {
                                if (!raw || typeof raw !== 'object') return {};
                                // cố gắng gom về các key chuẩn
                                const first = (v) => Array.isArray(v) ? v.find(Boolean) : v;

                                const author =
                                    raw.authorName ||
                                    raw.author_name ||
                                    first(raw.authors) ||
                                    raw.author ||
                                    "";

                                const publisher =
                                    raw.publisher ||
                                    raw.publisher_name ||
                                    raw.publishers ||
                                    "";

                                const year =
                                    raw.publicationYear ||
                                    raw.publication_year ||
                                    raw.year ||
                                    raw.publish_year ||
                                    "";

                                const pages =
                                    raw.numberOfPages ||
                                    raw.pages ||
                                    raw.page_count ||
                                    "";

                                const fmt =
                                    raw.format ||
                                    raw.book_format ||
                                    "";

                                const lang =
                                    raw.language ||
                                    raw.lang ||
                                    "";

                                const genres =
                                    raw.genres ||
                                    raw.categories ||
                                    [];

                                return {
                                    isbn: (raw.isbn || raw.ISBN || "").toString().trim(),
                                    title: raw.title || raw.book_title || "",
                                    authorName: author || "",
                                    publisher: publisher || "",
                                    publicationYear: year || "",
                                    numberOfPages: pages || "",
                                    format: fmt || "",
                                    language: lang || "",
                                    genres: Array.isArray(genres) ? genres : []
                                };
                            }

                            // ====== điền form ======
                            function fillForm(v, overwrite=false) {
                                if (!v) return;
                                const set = (el, val) => {
                                    if (!el || val == null || val === "") return;
                                    if (overwrite || !el.value) el.value = String(val);
                                };
                                set(F.isbn, v.isbn);
                                set(F.title, v.title);
                                set(F.authorName, v.authorName);
                                if (v.authorName && F.isNewAuthor) { F.isNewAuthor.value = "true"; if (F.authorId) F.authorId.value = ""; }
                                set(F.publisher, v.publisher);
                                set(F.publicationYear, v.publicationYear);
                                set(F.numberOfPages, v.numberOfPages);
                                set(F.language, v.language);

                                const fmt = (v.format || "").toUpperCase();
                                if (["HARDCOVER","PAPERBACK","EBOOK"].includes(fmt)) {
                                    if (F.format && (overwrite || !F.format.value)) {
                                        F.format.value = fmt;
                                        applyFormatUI();
                                    }
                                }

                                // genres → đẩy vào hidden newGenres (để server xử lý tạo mới)
                                if (Array.isArray(v.genres) && v.genres.length) {
                                    const existingNew = new Set((F.newGenres?.value || "").split(",").map(s=>s.trim()).filter(Boolean));
                                    v.genres.slice(0, 5).forEach(g => existingNew.add(g));
                                    if (F.newGenres) F.newGenres.value = Array.from(existingNew).join(",");
                                }
                            }

                            // ====== gọi Gemini với file ======
                            async function callGeminiWithFile(file) {
                                const fd = new FormData();
                                fd.append("file", file, file.name);
                                const r = await fetch(API_EXTRACT_GEMINI, { method: "POST", body: fd });
                                const data = await r.json().catch(() => ({}));
                                console.log("[extract-gemini] raw:", data); // <-- log để debug
                                if (!r.ok) throw new Error(data?.detail || `HTTP ${r.status}`);
                                return normalizeExtract(data);
                            }

                            // ====== ENRICH ======
                            async function enrichFromCurrent(overwrite) {
                                const isbn  = (F.isbn?.value || "").trim();
                                const title = (F.title?.value || "").trim();
                                const author= (F.authorName?.value || "").trim();
                                if (!(isbn || title)) return;

                                const params = new URLSearchParams();
                                if (isbn)  params.set("isbn", isbn);
                                if (title) params.set("title", title);
                                if (author)params.set("authorName", author);

                                const r2 = await fetch(API_ENRICH, {
                                    method: "POST",
                                    headers: {"Content-Type":"application/x-www-form-urlencoded"},
                                    body: params
                                });
                                const metaRaw = await r2.json().catch(() => ({}));
                                console.log("[enrich] raw:", metaRaw); // <-- log để debug
                                if (r2.ok) {
                                    fillForm(normalizeExtract(metaRaw), overwrite);
                                }
                            }

                            // ====== Popup logic ======
                            const modal     = document.getElementById("imgModal");
                            const openBtn   = document.getElementById("openImgModal");
                            const closeBtn  = document.getElementById("closeImgModal");
                            const cancelBtn = document.getElementById("cancelImgModal");
                            const readBtn   = document.getElementById("readNow");

                            const backInput  = document.getElementById("imgBack");
                            const frontInput = document.getElementById("imgFront");
                            const backPrev   = document.getElementById("imgBackPreview");
                            const frontPrev  = document.getElementById("imgFrontPreview");

                            function openModal() {
                                backInput.value = "";
                                frontInput.value = "";
                                backPrev.innerHTML = "";
                                frontPrev.innerHTML = "";
                                modal.classList.remove("hidden");
                                document.body.classList.add("overflow-hidden");
                                
                                // Animation
                                setTimeout(() => {
                                    const modalContent = modal.querySelector('.transform');
                                    if (modalContent) {
                                        modalContent.classList.remove('scale-95', 'opacity-0');
                                        modalContent.classList.add('scale-100', 'opacity-100');
                                    }
                                }, 50);
                            }
                            
                            function closeModal() {
                                const modalContent = modal.querySelector('.transform');
                                if (modalContent) {
                                    modalContent.classList.remove('scale-100', 'opacity-100');
                                    modalContent.classList.add('scale-95', 'opacity-0');
                                }
                                
                                setTimeout(() => {
                                    modal.classList.add("hidden");
                                    document.body.classList.remove("overflow-hidden");
                                }, 300);
                            }

                            openBtn?.addEventListener("click", openModal);
                            closeBtn?.addEventListener("click", closeModal);
                            cancelBtn?.addEventListener("click", closeModal);
                            modal?.addEventListener("click", e => {
                                if (e.target === modal.firstElementChild) closeModal();
                            });
                            document.addEventListener("keydown", e => {
                                if (!modal.classList.contains("hidden") && e.key === "Escape") closeModal();
                            });

                            // ====== drag & drop cho 2 dropzone ======
                            function wireDropZone(zoneEl, inputEl, previewEl) {
                                function showPreview(file) {
                                    if (!file) { previewEl.innerHTML = ""; return; }
                                    previewEl.innerHTML = `
                                        <div class="inline-flex items-center gap-2 px-3 py-2 rounded-lg border bg-white text-gray-700 shadow-sm">
                                            <i class="fa-solid fa-file-image text-lg text-purple-500"></i>
                                            <span class="truncate max-w-[200px]">${file.name}</span>
                                        </div>`;
                                }
                                inputEl.addEventListener("change", function() {
                                    showPreview(this.files && this.files.length ? this.files[0] : null);
                                });
                                ["dragenter","dragover"].forEach(evt =>
                                    zoneEl.addEventListener(evt, e => {
                                        e.preventDefault(); e.stopPropagation();
                                        zoneEl.classList.add("ring-2","ring-purple-500", "scale-[1.02]");
                                    })
                                );
                                ["dragleave","drop"].forEach(evt =>
                                    zoneEl.addEventListener(evt, e => {
                                        e.preventDefault(); e.stopPropagation();
                                        zoneEl.classList.remove("ring-2","ring-purple-500", "scale-[1.02]");
                                    })
                                );
                                zoneEl.addEventListener("drop", e => {
                                    const files = e.dataTransfer.files;
                                    if (files && files.length) {
                                        inputEl.files = files;
                                        showPreview(files[0]);
                                    }
                                });
                            }
                            wireDropZone(document.querySelector(".back-zone"),  backInput,  backPrev);
                            wireDropZone(document.querySelector(".front-zone"), frontInput, frontPrev);

                            // ====== Đọc ngay: clear form -> đọc ảnh (ưu tiên bìa sau) -> enrich -> đóng popup ======
                            readBtn?.addEventListener("click", async () => {
                                const back  = backInput.files?.[0] || null;
                                const front = frontInput.files?.[0] || null;
                                if (!back && !front) {
                                    alert("Chọn ít nhất 1 ảnh (bìa sau hoặc bìa trước).");
                                    return;
                                }

                                const overwrite = document.getElementById("overwrite")?.checked;

                                readBtn.disabled = true;
                                const old = readBtn.innerHTML;
                                readBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang đọc…';

                                try {
                                    clearBookForm(); // 1) XÓA SẠCH FORM trước khi đọc

                                    // 2) Thứ tự thử: bìa sau trước, rồi bìa trước
                                    const tryOrder = [back, front].filter(Boolean);
                                    for (const file of tryOrder) {
                                        const res = await callGeminiWithFile(file);
                                        fillForm(res, overwrite);
                                        if (res?.isbn && String(res.isbn).trim().length >= 10) break; // ISBN đã có thì dừng
                                    }

                                    // 3) ENRICH
                                    await enrichFromCurrent(overwrite);

                                    // 4) Đóng popup & toast
                                    closeModal();
                                    if (typeof showToast === "function") showToast("Đã điền thông tin từ ảnh.", "success");
                                } catch (e) {
                                    console.error(e);
                                    alert("Không xử lý được ảnh. Kiểm tra ảnh rõ nét hoặc thử lại sau.");
                                } finally {
                                    readBtn.disabled = false;
                                    readBtn.innerHTML = old;
                                }
                            });
                        });
                    </script>

                    <!-- Main form -->
                    <form id="bookForm" action="${pageContext.request.contextPath}/api/admin/books" method="post" enctype="multipart/form-data" class="space-y-8">
                        <!-- Book basic info section -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">ISBN <span class="text-red-500">*</span></label>
                                <input type="text" name="isbn"
                                       class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300" required>
                            </div>
                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Tên sách <span class="text-red-500">*</span></label>
                                <input type="text" name="title"
                                       class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300" required>
                            </div>
                        </div>

                        <!-- Genre and Publisher section -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Thể loại</label>

                                <!-- Ô nhập có datalist -->
                                <input type="text" id="genreInput" list="genreList" placeholder="Nhập hoặc chọn thể loại rồi nhấn Enter"
                                       class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300">
                                <datalist id="genreList">
                                    <%
                                        Connection con2 = DBConnection.getConnection();
                                        try (Statement st2 = con2.createStatement(); ResultSet rs2 = st2.executeQuery("SELECT id, name FROM genre ORDER BY name")) {
                                            while (rs2.next()) {
                                    %>
                                    <option value="<%= rs2.getString("name")%>" data-id="<%= rs2.getInt("id")%>"></option>
                                    <%
                                            }
                                        }
                                    %>
                                </datalist>

                                <!-- Nơi ghim chip đã chọn -->
                                <div id="selectedGenres" class="flex flex-wrap gap-2 mt-3"></div>

                                <!-- Hai hidden để gửi về server -->
                                <input type="hidden" name="genreIds" id="genreIds">      <!-- ví dụ: 3,5,9 -->
                                <input type="hidden" name="newGenres" id="newGenres">    <!-- ví dụ: Khoa học dữ liệu,AI -->
                            </div>

                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Nhà xuất bản</label>
                                <input type="text" name="publisher"
                                       class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300">
                            </div>
                        </div>

                        <!-- Publication details section -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Năm xuất bản <span class="text-red-500">*</span></label>
                                <input type="number" name="publicationYear" min="1000" max="9999"
                                       class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300" required>
                            </div>
                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Ngôn ngữ</label>
                                <input type="text" name="language"
                                       class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300">
                            </div>
                        </div>

                        <!-- Book format section -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Số trang</label>
                                <input type="number" name="numberOfPages" min="1"
                                       class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300">
                            </div>
                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Định dạng</label>
                                <select name="format"
                                        class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300">
                                    <option value="HARDCOVER">Bìa cứng</option>
                                    <option value="PAPERBACK">Bìa mềm</option>
                                    <option value="EBOOK">Ebook</option>
                                </select>
                            </div>
                        </div>

                        <!-- Author and quantity section -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Tác giả <span class="text-red-500">*</span></label>
                                <input type="text" name="authorName" id="authorName" list="authorList"
                                       placeholder="Nhập hoặc chọn tác giả"
                                       class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300" required>
                                <datalist id="authorList">
                                    <%
                                        Connection con = DBConnection.getConnection();
                                        Statement stmt = con.createStatement();
                                        ResultSet rs = stmt.executeQuery("SELECT id, name FROM Author");
                                        while (rs.next()) {
                                    %>
                                    <option value="<%= rs.getString("name")%>" data-id="<%= rs.getInt("id")%>"></option>
                                    <% }%>
                                </datalist>
                                <input type="hidden" name="authorId" id="authorId">
                                <input type="hidden" name="isNewAuthor" id="isNewAuthor" value="false">
                            </div>
                            <div id="qtyBlock" class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Số lượng <span class="text-red-500">*</span></label>
                                <input type="number" name="quantity" id="quantity" min="1"
                                       class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300" required>
                            </div>
                        </div>

                        <!-- Price and date section -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Giá sách <span class="text-red-500">*</span></label>
                                <input type="number" name="price" step="0.01" min="0"
                                       class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300" required>
                            </div>
                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Ngày nhập <span class="text-red-500">*</span></label>
                                <input type="date" name="dateOfPurchase"
                                       class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300" required>
                            </div>
                        </div>

                        <!-- File uploads section -->
                        <div class="space-y-6">
                            <div class="space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Hình ảnh bìa</label>
                                <input type="file" name="coverImage" accept="image/*"
                                       class="block w-full text-sm text-gray-500 file:mr-4 file:py-3 file:px-4
                                       file:rounded-lg file:border-0 file:shadow-sm
                                       file:text-sm file:font-semibold
                                       file:bg-gradient-to-r file:from-blue-50 file:to-indigo-50 file:text-blue-700
                                       hover:file:from-blue-100 hover:file:to-indigo-100 transition-all duration-300" />
                            </div>
                            
                            <!-- Chỉ hiện khi chọn EBOOK -->
                            <div id="ebookFileBlock" class="hidden space-y-2">
                                <label class="block text-sm font-semibold text-gray-700">Tệp ebook (PDF/EPUB)</label>
                                <input type="file" name="ebookFile" accept=".pdf,.epub,application/pdf,application/epub+zip"
                                       class="block w-full text-sm text-gray-500
                                              file:mr-4 file:py-3 file:px-4 file:rounded-lg file:border-0 file:shadow-sm
                                              file:text-sm file:font-semibold file:bg-gradient-to-r file:from-purple-50 file:to-indigo-50 file:text-purple-700
                                              hover:file:from-purple-100 hover:file:to-indigo-100 transition-all duration-300" />
                                <p class="text-xs text-gray-500 mt-1">Hỗ trợ: PDF hoặc EPUB. Dung lượng &lt;= 5MB.</p>
                            </div>
                        </div>

                        <!-- Submit button -->
                        <div class="pt-6 flex justify-center">
                            <button type="submit"
                                    class="bg-gradient-to-r from-blue-600 to-indigo-700 hover:from-blue-700 hover:to-indigo-800 text-white font-bold py-3 px-8 rounded-lg shadow-md transition-all duration-300 transform hover:scale-105">
                                Thêm sách vào thư viện
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </section>
    
    <!-- Floating Import Button (góc phải) -->
    <button id="openExcelModal"
            class="fixed bottom-6 right-6 z-40 rounded-full shadow-xl
                   bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-600 hover:to-green-700 text-white
                   w-16 h-16 flex items-center justify-center transition-all duration-300 transform hover:scale-110"
            title="Nhập sách từ Excel" type="button" aria-haspopup="dialog" aria-controls="excelModal">
        <i class="fa-solid fa-file-excel text-2xl"></i>
    </button>

    <!-- Modal Excel Import -->
    <div id="excelModal" class="fixed inset-0 z-50 hidden">
        <div class="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity duration-300"></div>

        <!-- Modal card -->
        <div class="absolute inset-0 flex items-center justify-center p-4">
            <div class="w-full max-w-xl bg-white rounded-2xl shadow-2xl overflow-hidden transform transition-all duration-300 scale-95 opacity-0">
                <!-- Header -->
                <div class="flex items-center justify-between px-6 py-5 border-b bg-gradient-to-r from-emerald-600 to-green-700">
                    <h3 class="text-xl font-bold text-white">Nhập sách hàng loạt từ Excel</h3>
                    <button id="closeExcelModal" class="p-2 rounded-full hover:bg-emerald-500 transition-colors" type="button" aria-label="Đóng">
                        <i class="fa-solid fa-xmark text-white text-lg"></i>
                    </button>
                </div>

                <!-- Body -->
                <div class="px-6 py-6">
                    <form method="post" enctype="multipart/form-data" class="space-y-5" id="excelImportForm">
                        <!-- Drag & drop zone -->
                        <label for="excelFile"
                               class="block w-full border-2 border-dashed border-emerald-300 rounded-xl p-8
                                      text-center cursor-pointer hover:border-emerald-500 transition-all duration-300 bg-emerald-50 hover:bg-emerald-100">
                            <div class="flex flex-col items-center gap-3">
                                <div class="w-16 h-16 rounded-full bg-gradient-to-r from-emerald-500 to-green-500 flex items-center justify-center">
                                    <i class="fa-solid fa-cloud-arrow-up text-2xl text-white"></i>
                                </div>
                                <div class="text-base font-medium text-gray-800">
                                    Kéo thả file vào đây hoặc <span class="font-semibold text-emerald-700 underline">chọn file</span>
                                </div>
                                <div class="text-sm text-gray-600">Chấp nhận: .xlsx, .xls</div>

                                <!-- nơi hiển thị icon + tên file -->
                                <div id="filePreview" class="mt-3"></div>
                            </div>
                            <input id="excelFile" name="excelFile" type="file" accept=".xlsx,.xls" class="hidden" required>
                        </form>
                        
                        <div class="flex items-center justify-between text-sm text-gray-600">
                            <span class="max-w-xs">Cột bắt buộc: ISBN, Title, AuthorName, PublicationYear, Format, Quantity.</span>
                            <a href="${pageContext.request.contextPath}/templates/book_import_template.xlsx"
                               class="text-emerald-700 hover:underline font-medium">Tải file mẫu</a>
                        </div>
                    </form>
                </div>

                <!-- Footer -->
                <div class="px-6 py-5 border-t bg-gray-50 flex items-center justify-end gap-3">
                    <button type="button" id="cancelExcelModal"
                            class="px-5 py-2.5 rounded-lg border border-gray-300 hover:bg-gray-100 text-gray-700 font-medium transition-colors">Hủy</button>
                    <button form="excelImportForm" type="submit"
                            class="px-5 py-2.5 rounded-lg bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-700 hover:to-green-700 text-white font-medium shadow-md transition-all duration-300
                                   inline-flex items-center gap-2">
                        <i class="fa-solid fa-file-import"></i> Nhập từ Excel
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Toast container (TOP RIGHT) -->
    <div id="toastContainer"
         class="fixed top-6 right-6 z-[2147483647]
                flex flex-col gap-3 pointer-events-none">
    </div>


    <script>
    function showToast(message, type = "info", duration = 3500) {
        const container = document.getElementById("toastContainer");
        if (!container) return;

        const icons = {
            success: "fa-circle-check",
            error: "fa-circle-xmark",
            warning: "fa-triangle-exclamation",
            info: "fa-circle-info"
        };

        const colors = {
            success: "from-emerald-500 to-green-600",
            error: "from-red-500 to-rose-600",
            warning: "from-amber-400 to-yellow-500 text-black",
            info: "from-blue-500 to-indigo-600"
        };

        const toast = document.createElement("div");
        toast.className = `
            pointer-events-auto
            w-[340px]
            rounded-xl shadow-2xl
            bg-gradient-to-r ${colors[type] || colors.info}
            text-white
            px-5 py-4
            flex items-start gap-3
            transform transition-all duration-300 ease-out
            opacity-0 translate-x-6
        `;

        toast.innerHTML = `
            <i class="fa-solid ${icons[type] || icons.info} text-xl mt-0.5"></i>
            <div class="flex-1 text-sm leading-relaxed">${message}</div>
            <button class="ml-2 text-white/70 hover:text-white transition">
                <i class="fa-solid fa-xmark"></i>
            </button>
        `;

        container.appendChild(toast);

        // animate in
        requestAnimationFrame(() => {
            toast.classList.remove("opacity-0", "translate-x-6");
            toast.classList.add("opacity-100", "translate-x-0");
        });

        const close = () => {
            toast.classList.add("opacity-0", "translate-x-6");
            setTimeout(() => toast.remove(), 250);
        };

        toast.querySelector("button").onclick = close;
        setTimeout(close, duration);
    }
    </script>

    <!-- Popup Confirm -->
    <div id="confirmPopup" class="fixed inset-0 z-[9998] hidden items-center justify-center bg-black/40 backdrop-blur-sm">
        <div class="bg-white rounded-xl shadow-2xl p-6 max-w-sm w-full transform transition-all duration-300 scale-95 opacity-0">
            <h3 class="text-lg font-bold text-gray-900 mb-4">Xác nhận</h3>
            <p id="confirmMessage" class="text-gray-700 mb-6"></p>
            <div class="flex justify-end gap-3">
                <button id="confirmCancel" class="px-5 py-2.5 bg-gray-200 rounded-lg hover:bg-gray-300 text-gray-700 font-medium transition-colors">Hủy</button>
                <button id="confirmOk" class="px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-700 text-white rounded-lg hover:from-blue-700 hover:to-indigo-800 font-medium transition-all duration-300">Đồng ý</button>
            </div>
        </div>
    </div>

    <script>
    function showConfirm(message) {
        return new Promise(resolve => {
            const popup = document.getElementById("confirmPopup");
            const msgEl = document.getElementById("confirmMessage");
            const okBtn = document.getElementById("confirmOk");
            const cancelBtn = document.getElementById("confirmCancel");
            const popupContent = popup.querySelector('.transform');

            msgEl.textContent = message;
            popup.classList.remove("hidden");
            popup.classList.add("flex");
            
            // Animation
            setTimeout(() => {
                popupContent.classList.remove("scale-95", "opacity-0");
                popupContent.classList.add("scale-100", "opacity-100");
            }, 50);

            function close(result) {
                popupContent.classList.remove("scale-100", "opacity-100");
                popupContent.classList.add("scale-95", "opacity-0");
                
                setTimeout(() => {
                    popup.classList.add("hidden");
                    popup.classList.remove("flex");
                    okBtn.removeEventListener("click", okHandler);
                    cancelBtn.removeEventListener("click", cancelHandler);
                    resolve(result);
                }, 300);
            }

            function okHandler() { close(true); }
            function cancelHandler() { close(false); }

            okBtn.addEventListener("click", okHandler);
            cancelBtn.addEventListener("click", cancelHandler);
        });
    }
    function showExcelLogPopup(logs = []) {
        const popup = document.getElementById("excelLogPopup");
        const content = document.getElementById("excelLogContent");
        const closeBtn = document.getElementById("closeExcelLogPopup");
        const popupBox = popup.querySelector(".transform");

        content.innerHTML = "";

        if (!logs.length) {
            content.innerHTML = "<div class='text-gray-500'>Không có log.</div>";
        } else {
            logs.forEach(line => {
                const div = document.createElement("div");
                div.textContent = line;
                content.appendChild(div);
            });
        }

        popup.classList.remove("hidden");
        popup.classList.add("flex");

        setTimeout(() => {
            popupBox.classList.remove("scale-95", "opacity-0");
            popupBox.classList.add("scale-100", "opacity-100");
        }, 30);

        function close() {
            popupBox.classList.remove("scale-100", "opacity-100");
            popupBox.classList.add("scale-95", "opacity-0");
            setTimeout(() => {
                popup.classList.add("hidden");
                popup.classList.remove("flex");
            }, 250);
        }

        closeBtn.onclick = close;
        popup.onclick = e => {
            if (e.target === popup) close();
        };
    }
    function showExcelResultPopup(stats, logs = []) {
        const popup = document.getElementById("excelResultPopup");
        const box   = popup.querySelector(".transform"); 
        const list  = document.getElementById("excelLogList");

        document.getElementById("statImported").textContent = stats.imported ?? 0;
        document.getElementById("statSkipped").textContent  = stats.skipped ?? 0;
        document.getElementById("statErrors").textContent   = stats.errors ?? 0;

        list.innerHTML = "";

        logs.forEach(line => {
            const li = document.createElement("li");
            li.className = `
                p-3 rounded-lg border
                ${line.includes("LỖI")
                    ? "bg-red-50 border-red-200 text-red-700"
                    : line.includes("bỏ qua")
                    ? "bg-yellow-50 border-yellow-200 text-yellow-700"
                    : "bg-green-50 border-green-200 text-green-700"}
            `;
            li.textContent = line;
            list.appendChild(li);
        });

        // SHOW popup
        popup.classList.remove("hidden");
        popup.classList.add("flex");

        requestAnimationFrame(() => {
            box.classList.remove("scale-95", "opacity-0");
            box.classList.add("scale-100", "opacity-100");
        });

        function closeAndReload() {
            box.classList.remove("scale-100", "opacity-100");
            box.classList.add("scale-95", "opacity-0");
            setTimeout(() => location.reload(), 200);
        }

        document.getElementById("closeExcelResult").onclick = closeAndReload;
        document.getElementById("confirmReload").onclick   = closeAndReload;
    }
    </script>
              
</main>

<script>
document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('bookForm');
    if (!form) return;

    form.action = '<%=request.getContextPath()%>/api/admin/books';

    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const fd = new FormData(form);
        const confirm = await showConfirm("Xác nhận thêm sách mới?");
        if (!confirm) return showToast("Đã hủy thao tác.", "warning");

        try {
            const r = await fetch(form.action, {
                method: 'POST',
                body: fd
            });
            const data = await r.json().catch(() => ({}));

            if (r.ok) {
                showToast(data.message || 'Thêm sách thành công!', "success");
                form.reset();
            } else {
                showToast(data.message || `Lỗi: ${r.status}`, "error");
            }
        } catch (err) {
            console.error(err);
            showToast('Không thể kết nối máy chủ.', "error");
        }
    });
});

</script>

<script>
document.addEventListener("DOMContentLoaded", () => {
    // ========== QUẢN LÝ THỂ LOẠI (chips + datalist) ==========
    const input = document.getElementById("genreInput");
    const list = document.getElementById("genreList");
    const wrap = document.getElementById("selectedGenres");
    const idsEl = document.getElementById("genreIds");
    const newsEl = document.getElementById("newGenres");

    // Map nameLower -> {id, name}
    const nameMap = new Map();
    Array.from(list.options).forEach(opt => {
        const name = (opt.value || "").trim();
        const id = opt.getAttribute("data-id");
        if (name) nameMap.set(name.toLowerCase(), { id, name });
    });

    const selectedKnown = new Map();
    const newNames = new Set();

    function render() {
        wrap.innerHTML = "";
        selectedKnown.forEach((name, id) => {
            const chip = document.createElement("span");
            chip.className =
                "px-3 py-1.5 rounded-full bg-gradient-to-r from-blue-100 to-indigo-100 text-blue-700 text-sm flex items-center gap-2 font-medium shadow-sm";
            chip.innerHTML = `${name}<button type="button" class="remove text-blue-900 hover:text-blue-700 transition-colors" data-type="id" data-val="${id}">×</button>`;
            wrap.appendChild(chip);
        });
        newNames.forEach(name => {
            const chip = document.createElement("span");
            chip.className =
                "px-3 py-1.5 rounded-full bg-gradient-to-r from-emerald-100 to-green-100 text-emerald-700 text-sm flex items-center gap-2 font-medium shadow-sm";
            chip.innerHTML = `${name}<button type="button" class="remove text-emerald-900 hover:text-emerald-700 transition-colors" data-type="new" data-val="${name}">×</button>`;
            wrap.appendChild(chip);
        });
        idsEl.value = Array.from(selectedKnown.keys()).join(",");
        newsEl.value = Array.from(newNames).join(",");
    }

    function addFromInput() {
        const val = input.value.trim();
        if (!val) return;
        const found = nameMap.get(val.toLowerCase());
        if (found && found.id) selectedKnown.set(String(found.id), found.name);
        else newNames.add(val);
        input.value = "";
        render();
    }

    input.addEventListener("keydown", e => {
        if (e.key === "Enter" || e.key === ",") {
            e.preventDefault();
            addFromInput();
        }
    });
    input.addEventListener("change", addFromInput);

    wrap.addEventListener("click", e => {
        if (!e.target.classList.contains("remove")) return;
        const { type, val } = e.target.dataset;
        if (type === "id") selectedKnown.delete(String(val));
        else newNames.delete(val);
        render();
    });
    render();
});
</script>

<script>    
(function () {
    // ========== MODAL NHẬP SÁCH EXCEL ==========
    const contextPath = '<%= request.getContextPath() %>';
    const modal = document.getElementById("excelModal");
    const openBtn = document.getElementById("openExcelModal");
    const closeBtn = document.getElementById("closeExcelModal");
    const cancelBtn = document.getElementById("cancelExcelModal");
    const modalContent = modal.querySelector('.transform');
    const excelForm = document.getElementById("excelImportForm");
    const fileInput = document.getElementById("excelFile");
    const filePreview = document.getElementById("filePreview");
    const submitBtn = modal ? modal.querySelector('button[form="excelImportForm"]') : null;
    if (!excelForm) return;

    excelForm.addEventListener("submit", async (e) => {
      e.preventDefault();

      if (!fileInput.files || fileInput.files.length === 0) {
        showToast("Vui lòng chọn file Excel!", "warning");
        return;
      }

      const file = fileInput.files[0];
      const validExts = ['.xlsx', '.xls'];
      if (!validExts.some(ext => file.name.toLowerCase().endsWith(ext))) {
        showToast("Chỉ chấp nhận file .xlsx hoặc .xls", "error");
        return;
      }

      const originalText = submitBtn ? submitBtn.innerHTML : null;
      if (submitBtn) { submitBtn.disabled = true; submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang xử lý...'; }

      try {
        const formData = new FormData();
        formData.append("excelFile", file);

        const response = await fetch(contextPath + '/api/admin/upload-excel', {
          method: 'POST',
          body: formData
        });

        // bảo vệ nếu server trả về text/html hoặc lỗi không phải JSON
        let data = {};
        try { data = await response.json(); } catch (err) { data = {}; }

        if (response.ok && data.success) {
          const stats = data.stats || {imported:0, skipped:0, errors:0, total:0};
          // đóng modal
          close();
          // hiển thị toasts tương tự như trước
          showToast(`📊 Nhập Excel hoàn tất — ✅ ${stats.imported} / ⚠️ ${stats.skipped} / ❌ ${stats.errors}`, "success", 6000);
          // show detailed logs to console
          if (Array.isArray(data.logs) && data.logs.length) {
                showExcelResultPopup(stats, data.logs || []);
            }
        } else {
          const msg = data.message || `Lỗi server (${response.status})`;
          showToast(msg, "error", 8000);
          if (data.logs && data.logs.length) {
            console.group("Lỗi nhập Excel");
            data.logs.forEach(l => console.error(l));
            console.groupEnd();
          }
        }
      } catch (err) {
        console.error(err);
        showToast("Không thể kết nối server!", "error");
      } finally {
        if (submitBtn) { submitBtn.disabled = false; submitBtn.innerHTML = originalText; }
      }
    });

    function open() {
        modal.classList.remove("hidden");
        document.body.classList.add("overflow-hidden");
        
        // Animation
        setTimeout(() => {
            modalContent.classList.remove('scale-95', 'opacity-0');
            modalContent.classList.add('scale-100', 'opacity-100');
        }, 50);
    }
    
    function close() {
        modalContent.classList.remove('scale-100', 'opacity-100');
        modalContent.classList.add('scale-95', 'opacity-0');
        
        setTimeout(() => {
            modal.classList.add("hidden");
            document.body.classList.remove("overflow-hidden");
        }, 300);
    }

    openBtn.addEventListener("click", open);
    closeBtn.addEventListener("click", close);
    cancelBtn.addEventListener("click", close);
    modal.addEventListener("click", e => {
        if (e.target === modal.firstElementChild) close();
    });
    document.addEventListener("keydown", e => {
        if (!modal.classList.contains("hidden") && e.key === "Escape") close();
    });

    // Drag & drop upload Excel
    const dropZone = document.querySelector('label[for="excelFile"]');
    function showFileInfo(file) {
        if (!file) {
            filePreview.innerHTML = "";
            return;
        }
        filePreview.innerHTML = `
            <div class="inline-flex items-center gap-2 px-3 py-2 rounded-lg border bg-white text-emerald-700 text-sm shadow-sm">
                <i class="fa-solid fa-file-excel text-lg"></i>
                <span>${file.name}</span>
            </div>`;
    }

    fileInput.addEventListener("change", function () {
        showFileInfo(this.files && this.files.length ? this.files[0] : null);
    });

    ["dragenter", "dragover"].forEach(evt =>
        dropZone.addEventListener(evt, e => {
            e.preventDefault();
            dropZone.classList.add("ring-2", "ring-emerald-500", "scale-[1.02]");
        })
    );
    ["dragleave", "drop"].forEach(evt =>
        dropZone.addEventListener(evt, e => {
            e.preventDefault();
            dropZone.classList.remove("ring-2", "ring-emerald-500", "scale-[1.02]");
        })
    );
    dropZone.addEventListener("drop", e => {
        const files = e.dataTransfer.files;
        if (files && files.length) {
            fileInput.files = files;
            showFileInfo(files[0]);
        }
    });
})();
</script>

<script>
document.addEventListener("DOMContentLoaded", () => {
    // ========== XỬ LÝ TÁC GIẢ ==========
    const authorInput = document.getElementById("authorName");
    const authorList = document.getElementById("authorList");
    const authorIdEl = document.getElementById("authorId");
    const isNewAuthorEl = document.getElementById("isNewAuthor");

    const authorMap = new Map();
    Array.from(authorList.options).forEach(opt => {
        const name = (opt.value || "").trim();
        const id = opt.getAttribute("data-id");
        if (name && id) authorMap.set(name.toLowerCase(), id);
    });

    function resolveAuthor() {
        const name = (authorInput.value || "").trim();
        const id = authorMap.get(name.toLowerCase());
        if (id) {
            authorIdEl.value = id;
            isNewAuthorEl.value = "false";
        } else {
            authorIdEl.value = "";
            if (name.length > 0) isNewAuthorEl.value = "true";
        }
    }

    authorInput.addEventListener("input", () => (authorIdEl.value = ""));
    authorInput.addEventListener("change", resolveAuthor);
    authorInput.addEventListener("blur", resolveAuthor);

    const formElm = document.getElementById("bookForm");
    formElm?.addEventListener("submit", e => {
        resolveAuthor();
        const name = (authorInput.value || "").trim();
        if (!authorIdEl.value && name.length === 0) {
            e.preventDefault();
            showToast("Vui lòng nhập hoặc chọn tác giả.", "warning");
        }
    });
});
</script>

</div>
<div id="excelResultPopup"
     class="fixed inset-0 z-[99999] hidden items-center justify-center
            bg-black/40 backdrop-blur-sm">

    <div class="bg-white w-full max-w-lg rounded-2xl shadow-2xl
                transform transition-all duration-300 scale-95 opacity-0">

        <!-- Header -->
        <div class="flex items-center justify-between px-6 py-5
                    bg-gradient-to-r from-emerald-600 to-green-700 text-white rounded-t-2xl">
            <h3 class="text-lg font-bold flex items-center gap-2">
                <i class="fa-solid fa-file-excel"></i>
                Kết quả nhập Excel
            </h3>
            <button id="closeExcelResult"
                    class="p-2 rounded-full hover:bg-white/20 transition">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <!-- Stats -->
        <div class="px-6 py-4 grid grid-cols-3 gap-3 text-center">
            <div class="rounded-xl bg-green-50 p-3">
                <div class="text-2xl font-bold text-green-600" id="statImported">0</div>
                <div class="text-xs text-gray-600">Thành công</div>
            </div>
            <div class="rounded-xl bg-yellow-50 p-3">
                <div class="text-2xl font-bold text-yellow-600" id="statSkipped">0</div>
                <div class="text-xs text-gray-600">Bỏ qua</div>
            </div>
            <div class="rounded-xl bg-red-50 p-3">
                <div class="text-2xl font-bold text-red-600" id="statErrors">0</div>
                <div class="text-xs text-gray-600">Lỗi</div>
            </div>
        </div>

        <!-- Logs -->
        <div class="px-6 pb-4 max-h-[300px] overflow-y-auto">
            <h4 class="font-semibold text-gray-800 mb-2">Chi tiết nhập Excel</h4>
            <ul id="excelLogList" class="space-y-2 text-sm"></ul>
        </div>

        <!-- Footer -->
        <div class="px-6 py-4 border-t bg-gray-50 flex justify-end gap-3 rounded-b-2xl">
            <button id="confirmReload"
                    class="px-6 py-2.5 rounded-lg
                           bg-gradient-to-r from-emerald-600 to-green-600
                           hover:from-emerald-700 hover:to-green-700
                           text-white font-medium shadow transition">
                Đóng & tải lại
            </button>
        </div>
    </div>
</div>
