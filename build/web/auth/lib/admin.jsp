<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="Servlet.DBConnection, Data.Users" %>

<%
    request.setAttribute("pageTitle", "Quản lý sách - Admin");
%>
<%@ include file="../includes/header.jsp" %>

<!-- Content của trang admin -->
<main class="transition-all duration-300 pt-32" id="mainContent">
    <section class="bg-gray-100 py-10 px-6">
        <div class="max-w-4xl mx-auto bg-white p-8 rounded-lg shadow-md">
            <h2 class="text-2xl font-bold mb-6 text-center text-gray-800">Thêm sách mới</h2>
            
            <form action="${pageContext.request.contextPath}/AdminServlet" method="post" enctype="multipart/form-data" class="space-y-6">
                <div class="flex items-center gap-3 mb-3">
                    <!-- ảnh bìa trước -->
                    <div class="flex flex-col">
                      <label class="text-xs text-gray-600">Bìa trước</label>
                      <input id="coverFront" type="file" accept="image/*" class="block text-sm text-gray-500" />
                    </div>
                    <!-- ảnh bìa sau -->
                    <div class="flex flex-col">
                      <label class="text-xs text-gray-600">Bìa sau</label>
                      <input id="coverBack" type="file" accept="image/*" class="block text-sm text-gray-500" />
                    </div>

                    <button id="runOcr" type="button"
                            class="px-4 py-2 rounded-lg bg-purple-600 hover:bg-purple-700 text-white">
                      Đọc từ ảnh (OCR/Barcode)
                    </button>

<!--                    <button id="enrichBtn" type="button"
                            class="px-4 py-2 rounded-lg bg-amber-600 hover:bg-amber-700 text-white">
                      Tự điền từ Internet
                    </button>-->

                    <label class="inline-flex items-center gap-2 text-sm text-gray-600">
                      <input id="overwrite" type="checkbox" class="accent-blue-600">
                      Ghi đè ô đã nhập
                    </label>
                </div>


                <script>
                document.addEventListener("DOMContentLoaded", () => {
                    const API_EXTRACT_SINGLE = "http://localhost:8000/extract";
                    const API_EXTRACT_DUAL   = "http://localhost:8000/extract-dual";
                    const API_ENRICH         = "http://localhost:8000/enrich";

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
                            F.qtyInput.removeAttribute("required"); // vì đã ẩn
                          } else {
                            F.qtyInput.removeAttribute("readonly");
                            F.qtyInput.setAttribute("required", "required");
                            if (!F.qtyInput.value) F.qtyInput.value = "1";
                          }
                        }
                      }

                      // gọi khi người dùng đổi định dạng
                      F.format?.addEventListener("change", applyFormatUI);
                      
                    function addGenreChip(name) {
                      if (!F.genreInput) return;
                      F.genreInput.value = name;
                      F.genreInput.dispatchEvent(new Event("change"));
                    }

                    function fillForm(v, overwrite=false) {
                      if (!v) return;
                      const set = (el, val) => { if (!el || val == null || val === "") return; if (overwrite || !el.value) el.value = String(val); };
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
                          // CẬP NHẬT UI theo format
                          const isE = (F.format?.value || "").toUpperCase() === "EBOOK";
                          if (F.ebookBlock) F.ebookBlock.classList.toggle("hidden", !isE);
                          if (F.qtyBlock)   F.qtyBlock.classList.toggle("hidden", isE);
                          if (F.qtyInput) {
                            if (isE) { F.qtyInput.value = "1"; F.qtyInput.setAttribute("readonly", "readonly"); F.qtyInput.removeAttribute("required"); }
                            else { F.qtyInput.removeAttribute("readonly"); F.qtyInput.setAttribute("required","required"); if (!F.qtyInput.value) F.qtyInput.value = "1"; }
                          }
                        }
                      }
                      if (Array.isArray(v.genres)) v.genres.slice(0,5).forEach(g => {
                        if (F.genreInput) { F.genreInput.value = g; F.genreInput.dispatchEvent(new Event("change")); }
                      });

                      // (tuỳ chọn) hiển thị thông tin so khớp/độ tin cậy
                      if (v.explain) console.info("Match explain:", v.explain);
                    }

                    document.getElementById("runOcr")?.addEventListener("click", async () => {
                      const front = document.getElementById("coverFront")?.files?.[0];
                      const back  = document.getElementById("coverBack")?.files?.[0];
                      if (!front && !back) return alert("Chọn ít nhất 1 ảnh (bìa trước hoặc bìa sau).");

                      const btn = document.getElementById("runOcr");
                      btn.disabled = true;
                      const old = btn.textContent;
                      btn.textContent = "Đang đọc ảnh…";

                      try {
                        const fd = new FormData();
                        if (front) fd.append("front", front, front.name);
                        if (back)  fd.append("back",  back,  back.name);

                        // Nếu có cả 2 ảnh → dùng API 2 ảnh, nếu không thì vẫn dùng API 1 ảnh cũ
                        const url = (front && back) ? API_EXTRACT_DUAL : API_EXTRACT_SINGLE;
                        const r = await fetch(url, { method: "POST", body: fd });
                        const data = await r.json();
                        if (!r.ok) throw new Error(data?.detail || "Lỗi khi đọc ảnh");

                        fillForm(data, document.getElementById("overwrite")?.checked);

                        // enrich bổ sung (nếu có ISBN thì cực chuẩn, còn không thì dùng title/author)
                        const isbn  = F.isbn?.value?.trim();
                        const title = F.title?.value?.trim();
                        const author= F.authorName?.value?.trim();
                        if (isbn || title) {
                          const params = new URLSearchParams();
                          if (isbn)  params.set("isbn", isbn);
                          if (title) params.set("title", title);
                          if (author)params.set("authorName", author);

                          const r2 = await fetch(API_ENRICH, {
                            method: "POST",
                            headers: {"Content-Type":"application/x-www-form-urlencoded"},
                            body: params
                          });
                          if (r2.ok) {
                            const meta = await r2.json();
                            fillForm(meta, document.getElementById("overwrite")?.checked);
                          }
                        }
                      } catch (e) {
                        console.error(e);
                        alert("Không xử lý được ảnh. Thử ảnh rõ hơn nhé.");
                      } finally {
                        btn.disabled = false;
                        btn.textContent = old;
                      }
                    });
                  });
                
                </script>



                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label class="block mb-1 text-sm font-medium text-gray-700">ISBN</label>
                        <input type="text" name="isbn"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" required>
                    </div>
                    <div>
                        <label class="block mb-1 text-sm font-medium text-gray-700">Tên sách</label>
                        <input type="text" name="title"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" required>
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label class="block mb-1 text-sm font-medium text-gray-700">Thể loại</label>

                        <!-- Ô nhập có datalist -->
                        <input type="text" id="genreInput" list="genreList" placeholder="Nhập hoặc chọn thể loại rồi nhấn Enter"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
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

                    <div>
                        <label class="block mb-1 text-sm font-medium text-gray-700">Nhà xuất bản</label>
                        <input type="text" name="publisher"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label class="block mb-1 text-sm font-medium text-gray-700">Năm xuất bản</label>
                        <input type="number" name="publicationYear" min="1000" max="9999"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" required>
                    </div>
                    <div>
                        <label class="block mb-1 text-sm font-medium text-gray-700">Ngôn ngữ</label>
                        <input type="text" name="language"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label class="block mb-1 text-sm font-medium text-gray-700">Số trang</label>
                        <input type="number" name="numberOfPages" min="1"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    <div>
                        <label class="block mb-1 text-sm font-medium text-gray-700">Định dạng</label>
                        <select name="format"
                                class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
                            <option value="HARDCOVER">Bìa cứng</option>
                            <option value="PAPERBACK">Bìa mềm</option>
                            <option value="EBOOK">Ebook</option>
                        </select>
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label class="block mb-1 text-sm font-medium text-gray-700">Tác giả</label>
                        <input type="text" name="authorName" id="authorName" list="authorList"
                               placeholder="Nhập hoặc chọn tác giả"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" required>
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
                    <div id="qtyBlock">
                        <label class="block mb-1 text-sm font-medium text-gray-700">Số lượng</label>
                        <input type="number" name="quantity" id="quantity" min="1"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" required>
                    </div>

                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label class="block mb-1 text-sm font-medium text-gray-700">Giá sách</label>
                        <input type="number" name="price" step="0.01" min="0"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" required>
                    </div>
                    <div>
                        <label class="block mb-1 text-sm font-medium text-gray-700">Ngày nhập</label>
                        <input type="date" name="dateOfPurchase"
                               class="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" required>
                    </div>
                </div>

                <div>
                    <label class="block mb-1 text-sm font-medium text-gray-700">Hình ảnh</label>
                    <input type="file" name="coverImage" accept="image/*"
                           class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4
                           file:rounded file:border-0
                           file:text-sm file:font-semibold
                           file:bg-blue-50 file:text-blue-700
                           hover:file:bg-blue-100" />
                </div>
                <!-- Chỉ hiện khi chọn EBOOK -->
                <div id="ebookFileBlock" class="hidden">
                  <label class="block mb-1 text-sm font-medium text-gray-700">Tệp ebook (PDF/EPUB)</label>
                  <input type="file" name="ebookFile" accept=".pdf,.epub,application/pdf,application/epub+zip"
                         class="block w-full text-sm text-gray-500
                                file:mr-4 file:py-2 file:px-4 file:rounded file:border-0
                                file:text-sm file:font-semibold file:bg-purple-50 file:text-purple-700
                                hover:file:bg-purple-100" />
                  <p class="text-xs text-gray-500 mt-1">Hỗ trợ: PDF hoặc EPUB. Dung lượng &lt;= 5MB.</p>
                </div>
        
                <div class="text-center pt-4">
                    <button type="submit"
                            class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-6 rounded-lg transition duration-200">
                        Thêm sách
                    </button>
                </div>
                <hr class="my-6">
            </form>
        </div>
    </section>
    <!-- Floating Import Button (góc phải) -->
    <button id="openExcelModal"
            class="fixed bottom-6 right-6 z-40 rounded-full shadow-xl
                   bg-emerald-600 hover:bg-emerald-700 text-white
                   w-14 h-14 flex items-center justify-center"
            title="Nhập sách từ Excel" type="button" aria-haspopup="dialog" aria-controls="excelModal">
      <i class="fa-solid fa-file-excel text-xl"></i>
    </button>

    <!-- Modal backdrop -->
    <div id="excelModal" class="fixed inset-0 z-50 hidden">
      <div class="absolute inset-0 bg-black/50"></div>

      <!-- Modal card -->
      <div class="absolute inset-0 flex items-center justify-center p-4">
        <div class="w-full max-w-xl bg-white rounded-2xl shadow-2xl overflow-hidden">
          <!-- Header -->
          <div class="flex items-center justify-between px-5 py-4 border-b">
            <h3 class="text-lg font-semibold">Nhập sách hàng loạt từ Excel</h3>
            <button id="closeExcelModal" class="p-2 rounded hover:bg-gray-100" type="button" aria-label="Đóng">
              <i class="fa-solid fa-xmark text-gray-600"></i>
            </button>
          </div>

          <!-- Body -->
          <div class="px-5 py-4">
            <form action="${pageContext.request.contextPath}/AdminUploadExcelServlet"
                  method="post" enctype="multipart/form-data" class="space-y-4" id="excelImportForm">
              <!-- Drag & drop zone -->
                <label for="excelFile"
                       class="block w-full border-2 border-dashed border-emerald-300 rounded-xl p-6
                              text-center cursor-pointer hover:border-emerald-500">
                  <div class="flex flex-col items-center gap-2">
                    <i class="fa-solid fa-cloud-arrow-up text-3xl text-emerald-600"></i>
                    <div class="text-sm text-gray-700">
                      Kéo thả file vào đây hoặc <span class="font-semibold text-emerald-700 underline">chọn file</span>
                    </div>
                    <div class="text-xs text-gray-500">Chấp nhận: .xlsx, .xls</div>

                    <!-- nơi hiển thị icon + tên file -->
                    <div id="filePreview" class="mt-3"></div>
                  </div>
                  <input id="excelFile" name="excelFile" type="file" accept=".xlsx,.xls" class="hidden" required>
                </label>
              
              <div class="flex items-center justify-between text-xs text-gray-500">
                <span>Cột bắt buộc: ISBN, Title, AuthorName, PublicationYear, Format, Quantity.</span>
                <a href="${pageContext.request.contextPath}/templates/book_import_template.xlsx"
                   class="text-emerald-700 hover:underline">Tải file mẫu</a>
              </div>
            </form>
          </div>

          <!-- Footer -->
          <div class="px-5 py-4 border-t flex items-center justify-end gap-3">
            <button type="button" id="cancelExcelModal"
                    class="px-4 py-2 rounded-lg border hover:bg-gray-50">Hủy</button>
            <button form="excelImportForm" type="submit"
                    class="px-4 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white
                           inline-flex items-center gap-2">
              <i class="fa-solid fa-file-import"></i> Nhập từ Excel
            </button>
          </div>
        </div>
      </div>
    </div>
                    
</main>
<script>
    document.addEventListener("DOMContentLoaded", () => {
        const input = document.getElementById("genreInput");
        const list = document.getElementById("genreList");
        const wrap = document.getElementById("selectedGenres");
        const idsEl = document.getElementById("genreIds");
        const newsEl = document.getElementById("newGenres");

        // 1) Build map từ datalist: nameLower -> {id, name}
        const nameMap = new Map();
        Array.from(list.options).forEach(opt => {
            const name = (opt.value || "").trim();
            const id = opt.getAttribute("data-id");
            if (name)
                nameMap.set(name.toLowerCase(), {id, name});
        });

        // 2) Lưu lựa chọn: id->name (có sẵn), và Set tên mới
        const selectedKnown = new Map(); // Map<string(id) , string(name)>
        const newNames = new Set();      // Set<string>

        function render() {
            wrap.innerHTML = "";

            // chip cho thể loại có sẵn
            selectedKnown.forEach((name, id) => {
                const chip = document.createElement("span");
                chip.className = "px-3 py-1 rounded-full bg-blue-100 text-blue-700 text-sm flex items-center gap-2 whitespace-nowrap";

                const label = document.createElement("span");
                label.textContent = name;

                const btn = document.createElement("button");
                btn.type = "button";
                btn.className = "remove";
                btn.setAttribute("data-type", "id");
                btn.setAttribute("data-val", id);
                btn.textContent = "×";

                chip.appendChild(label);
                chip.appendChild(btn);
                wrap.appendChild(chip);
            });

            // chip cho thể loại mới
            newNames.forEach(name => {
                const chip = document.createElement("span");
                chip.className = "px-3 py-1 rounded-full bg-emerald-100 text-emerald-700 text-sm flex items-center gap-2 whitespace-nowrap";

                const label = document.createElement("span");
                label.textContent = name;

                const btn = document.createElement("button");
                btn.type = "button";
                btn.className = "remove";
                btn.setAttribute("data-type", "new");
                btn.setAttribute("data-val", name);
                btn.textContent = "×";

                chip.appendChild(label);
                chip.appendChild(btn);
                wrap.appendChild(chip);
            });

            idsEl.value = Array.from(selectedKnown.keys()).join(",");
            newsEl.value = Array.from(newNames).join(",");
        }


        function addFromInput() {
            const val = input.value.trim();
            if (!val)
                return;

            const found = nameMap.get(val.toLowerCase());
            if (found && found.id) {
                // có trong datalist
                selectedKnown.set(String(found.id), found.name);
            } else {
                // tên mới
                newNames.add(val);
            }
            input.value = "";
            render();
        }

        // Nhấn Enter / dấu phẩy để thêm
        input.addEventListener("keydown", e => {
            if (e.key === "Enter" || e.key === ",") {
                e.preventDefault();
                addFromInput();
            }
        });

        // Chọn từ dropdown datalist bằng chuột
        input.addEventListener("change", addFromInput);

        // Xóa chip
        document.getElementById("selectedGenres").addEventListener("click", e => {
            if (!e.target.classList.contains("remove"))
                return;
            const type = e.target.dataset.type;
            const val = e.target.dataset.val;
            if (type === "id")
                selectedKnown.delete(String(val));
            else
                newNames.delete(val);
            render();
        });

        // render ban đầu (nếu cần)
        render();
    });
    (function () {
        const modal = document.getElementById('excelModal');
        const openBtn = document.getElementById('openExcelModal');
        const closeBtn = document.getElementById('closeExcelModal');
        const cancelBtn = document.getElementById('cancelExcelModal');

        function open()  { modal.classList.remove('hidden'); document.body.classList.add('overflow-hidden'); }
        function close() { modal.classList.add('hidden');    document.body.classList.remove('overflow-hidden'); }

        openBtn.addEventListener('click', open);
        closeBtn.addEventListener('click', close);
        cancelBtn.addEventListener('click', close);
        modal.addEventListener('click', (e) => {
          // click ra ngoài card thì đóng
          if (e.target === modal.firstElementChild) close();
        });
        document.addEventListener('keydown', (e) => {
          if (!modal.classList.contains('hidden') && e.key === 'Escape') close();
        });

        // drag & drop cho vùng upload
        const dropZone   = document.querySelector('label[for="excelFile"]');
        const fileInput  = document.getElementById('excelFile');
        const filePreview= document.getElementById('filePreview');

        function showFileInfo(file) {
          if (!file) { filePreview.innerHTML = ""; return; }
          filePreview.innerHTML =
            '<div class="inline-flex items-center gap-2 px-3 py-2 rounded-lg border bg-emerald-50 text-emerald-700 text-sm">' +
              '<i class="fa-solid fa-file-excel text-lg"></i>' +
              '<span>' + file.name + '</span>' +
            '</div>';
        }

        fileInput.addEventListener('change', function () {
          showFileInfo(this.files && this.files.length ? this.files[0] : null);
        });

        // drag & drop
        ['dragenter','dragover'].forEach(evt => {
          dropZone.addEventListener(evt, e => {
            e.preventDefault(); e.stopPropagation();
            dropZone.classList.add('ring-2','ring-emerald-500');
          });
        });
        ['dragleave','drop'].forEach(evt => {
          dropZone.addEventListener(evt, e => {
            e.preventDefault(); e.stopPropagation();
            dropZone.classList.remove('ring-2','ring-emerald-500');
          });
        });
        dropZone.addEventListener('drop', e => {
          const files = e.dataTransfer.files;
          if (files && files.length) {
            fileInput.files = files;
            showFileInfo(files[0]);
          }
        });
        ['dragenter','dragover'].forEach(evt =>
          dropZone.addEventListener(evt, (e)=>{ e.preventDefault(); e.stopPropagation(); dropZone.classList.add('ring-2','ring-emerald-500'); })
        );
        ['dragleave','drop'].forEach(evt =>
          dropZone.addEventListener(evt, (e)=>{ e.preventDefault(); e.stopPropagation(); dropZone.classList.remove('ring-2','ring-emerald-500'); })
        );
        dropZone.addEventListener('drop', (e)=>{
          const files = e.dataTransfer.files;
          if (files && files.length) fileInput.files = files;
        });
    })();
    
    document.addEventListener("DOMContentLoaded", () => {
  const authorInput   = document.getElementById("authorName");
  const authorList    = document.getElementById("authorList");
  const authorIdEl    = document.getElementById("authorId");
  const isNewAuthorEl = document.getElementById("isNewAuthor");

  // build map: nameLower -> id
  const authorMap = new Map();
  Array.from(authorList.options).forEach(opt => {
    const name = (opt.value || "").trim();
    const id   = opt.getAttribute("data-id");
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
      // nếu user gõ cái gì đó -> coi như tác giả mới
      if (name.length > 0) isNewAuthorEl.value = "true";
    }
  }

  // reset khi đang gõ, rồi quyết định khi blur/change
  authorInput.addEventListener("input", () => { authorIdEl.value = ""; /* tạm reset */ });
  authorInput.addEventListener("change", resolveAuthor);
  authorInput.addEventListener("blur", resolveAuthor);

  // chốt lại lần cuối trước khi submit
  const form = document.querySelector('form[action$="/AdminServlet"]');
  form?.addEventListener("submit", (e) => {
    resolveAuthor();
    const name = (authorInput.value || "").trim();
    if (!authorIdEl.value && name.length === 0) {
      e.preventDefault();
      alert("Vui lòng nhập hoặc chọn tác giả.");
    }
  });
});
</script>

</div>
