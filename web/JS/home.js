// Gộp chọn/nhập tác giả trong cùng 1 ô
document.addEventListener('DOMContentLoaded', () => {
    const authorInput = document.getElementById('authorName');
    const authorList = document.getElementById('authorList');
    const authorIdInput = document.getElementById('authorId');
    const isNewAuthorInput = document.getElementById('isNewAuthor');

    if (authorInput && authorList && authorIdInput && isNewAuthorInput) {
        authorInput.addEventListener('input', () => {
            const inputVal = authorInput.value.trim();
            let found = false;
            for (const opt of authorList.options) {
                if (opt.value === inputVal) {
                    authorIdInput.value = opt.dataset.id;
                    isNewAuthorInput.value = "false";
                    found = true;
                    break;
                }
            }
            if (!found && inputVal !== "") {
                authorIdInput.value = "";
                isNewAuthorInput.value = "true";
            }
        });
    }
});

// Toggle menu người dùng
function toggleUserMenu() {
    const dropup = document.getElementById("userDropup");
    const arrow = document.getElementById("arrowIcon");

    if (dropup) {
        dropup.classList.toggle("visible"); // Thay thế visibility bằng class
        arrow.classList.toggle("rotated"); // Thêm class xoay icon
    }
}

// Cuộn sách mượt bằng con lăn chuột
document.addEventListener("DOMContentLoaded", function () {
    const booksContainer = document.querySelector(".books-container");

    if (booksContainer) {
        let isScrolling; 

        booksContainer.addEventListener("wheel", (e) => {
            e.preventDefault(); // Ngăn chặn cuộn dọc
            const scrollAmount = e.deltaY * 2; // Điều chỉnh tốc độ cuộn
            booksContainer.scrollLeft += scrollAmount;

            // Tạo hiệu ứng mượt mà bằng cách dừng cuộn từ từ
            window.clearTimeout(isScrolling);
            isScrolling = setTimeout(() => {
                booksContainer.style.scrollBehavior = "smooth";
            }, 50);
        });
    }
});

// Toggle dropdown menu
function toggleDropdown() {
    const dropdown = document.getElementById("userDropdown");
    if (dropdown) {
        dropdown.classList.toggle("show");
    }
}

// Đóng dropdown khi click ra ngoài
window.addEventListener("click", function (event) {
    if (!event.target.closest(".avatar, .dropdown-content")) {
        document.querySelectorAll(".dropdown-content.show").forEach(dropdown => {
            dropdown.classList.remove("show");
        });
    }
});

document.querySelector('.books-container').scrollTo({
    left: 100, // Điều chỉnh vị trí cuộn
    behavior: 'smooth'
});

function toggleView(categoryId, button) {
        let container = document.getElementById(categoryId);
        let isGridView = container.classList.contains("grid-view");

        if (isGridView) {
            container.classList.remove("grid-view");
            button.innerText = "Xem thêm";
        } else {
            container.classList.add("grid-view");
            button.innerText = "Thu gọn";
        }
    }
