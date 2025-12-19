from __future__ import annotations
from typing import Dict, Set, List, Tuple
from collections import Counter

from db import get_conn
from reco import jaccard   # dùng hàm jaccard bạn đã có trong reco.py


# ================== LOAD DỮ LIỆU TỪ DB ==================

def load_user_isbn_map() -> Dict[int, Set[str]]:
    sql = """
    SELECT br.user_id AS uid, bi.book_isbn AS isbn
    FROM borrow br
    JOIN bookitem bi ON br.book_item_id = bi.book_item_id
    WHERE br.status IN ('Borrowed','Returned','Overdue')
    GROUP BY br.user_id, bi.book_isbn
    """
    m: Dict[int, Set[str]] = {}
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            for row in cur.fetchall():
                uid = int(row["uid"])
                isbn = row["isbn"]
                m.setdefault(uid, set()).add(isbn)
    return m


def load_isbn_title_map() -> Dict[str, str]:
    """
    Đọc map isbn -> title từ bảng book.
    Để in ra tên sách cho dễ viết báo cáo.
    """
    isbn_title: Dict[str, str] = {}

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT isbn, title
                FROM book
            """)
            for isbn, title in cur.fetchall():
                isbn_title[str(isbn)] = str(title)
    finally:
        conn.close()

    return isbn_title


# ================== THỐNG KÊ CHO BÁO CÁO ==================

def print_cf_global_stats(user_items: Dict[int, Set[str]]):
    """
    In các thống kê tổng quan cho phần CF trong báo cáo:
      - Tổng số user có lịch sử mượn
      - Tổng số (user, isbn)
      - Số ISBN khác nhau
      - Số user có >= 1 / >= 3 / >= 5 ISBN, v.v.
    """
    total_users = len(user_items)
    total_pairs = sum(len(s) for s in user_items.values())

    all_isbns: Set[str] = set()
    for s in user_items.values():
        all_isbns |= s
    total_isbn = len(all_isbns)

    users_ge_1 = sum(1 for s in user_items.values() if len(s) >= 1)
    users_ge_3 = sum(1 for s in user_items.values() if len(s) >= 3)
    users_ge_5 = sum(1 for s in user_items.values() if len(s) >= 5)

    print("===== THỐNG KÊ TỔNG QUAN CF =====")
    print(f"Tổng số user có lịch sử mượn (trong map): {total_users}")
    print(f"Tổng số (user, isbn) được dùng cho CF:   {total_pairs}")
    print(f"Số ISBN khác nhau xuất hiện trong borrow: {total_isbn}")
    print()
    print(f"Số user có >= 1 ISBN: {users_ge_1}")
    print(f"Số user có >= 3 ISBN: {users_ge_3}")
    print(f"Số user có >= 5 ISBN: {users_ge_5}")
    print("=================================\n")

    # In thêm TOP 5 user mượn nhiều ISBN nhất (cho báo cáo minh họa)
    users_sorted = sorted(
        user_items.items(),
        key=lambda kv: len(kv[1]),
        reverse=True
    )
    print("TOP 5 user mượn nhiều ISBN khác nhau nhất:")
    for rank, (uid, items) in enumerate(users_sorted[:5], 1):
        print(f"{rank}. User {uid} – {len(items)} ISBN")


# ================== HÀM CF ĐƠN GIẢN (CHO TEST & GỢI Ý) ==================

def get_top_neighbors(
    user_items: Dict[int, Set[str]],
    target_user_id: int,
    k: int = 10
) -> List[Tuple[int, float]]:
    """
    Tính Jaccard similarity giữa target_user_id và tất cả user khác,
    trả về danh sách top-k (user_id, similarity).
    """
    SA = user_items.get(target_user_id, set())
    if not SA:
        print(f"❌ User {target_user_id} chưa mượn sách nào.")
        return []

    sims: List[Tuple[int, float]] = []
    for uid, items in user_items.items():
        if uid == target_user_id:
            continue
        s = jaccard(SA, items)
        if s > 0:
            sims.append((uid, s))

    sims.sort(key=lambda x: x[1], reverse=True)
    return sims[:k]


def recommend_for_user(
    user_items: Dict[int, Set[str]],
    target_user_id: int,
    k_neighbors: int = 10,
    top_n: int = 10
) -> List[Tuple[str, float]]:
    """
    Tính gợi ý cho user bằng CF đơn giản:
      - Tính top-k hàng xóm
      - Cộng dồn similarity cho từng ISBN mà hàng xóm mượn nhưng target chưa mượn
      - Trả về list (isbn, score)
    """
    SA = user_items.get(target_user_id, set())
    if not SA:
        print(f"❌ User {target_user_id} chưa mượn sách nào.")
        return []

    neighbors = get_top_neighbors(user_items, target_user_id, k_neighbors)
    if not neighbors:
        return []

    candidate_score: Dict[str, float] = {}
    for neighbor_id, sim in neighbors:
        items = user_items.get(neighbor_id, set())
        for isbn in items:
            # chỉ gợi ý sách mà user chưa mượn
            if isbn in SA:
                continue
            candidate_score[isbn] = candidate_score.get(isbn, 0.0) + sim

    # sắp xếp theo score giảm dần
    ranked = sorted(candidate_score.items(), key=lambda x: x[1], reverse=True)
    return ranked[:top_n]


# ================== HÀM IN CHI TIẾT CHO 1 USER (MINH HỌA BÁO CÁO) ==================

def print_user_detail(
    user_id: int,
    user_items: Dict[int, Set[str]],
    isbn_title: Dict[str, str]
):
    """
    In danh sách ISBN + tên sách mà user đã mượn,
    để đưa vào phần ví dụ minh họa CF.
    """
    items = user_items.get(user_id, set())
    if not items:
        print(f"❌ User {user_id} chưa mượn sách nào.")
        return

    print(f"\n===== SÁCH USER {user_id} ĐÃ MƯỢN ({len(items)} ISBN) =====")
    for isbn in sorted(items):
        title = isbn_title.get(isbn, "(Không tìm thấy tên sách)")
        print(f"- {isbn} – {title}")
    print("====================================================\n")


def print_neighbors_detail(
    target_user_id: int,
    user_items: Dict[int, Set[str]],
    isbn_title: Dict[str, str],
    k: int = 5
):
    """
    In top-k hàng xóm của user + số sách trùng + vài sách trùng,
    để có dữ liệu ghi vào chương 3.
    """
    neighbors = get_top_neighbors(user_items, target_user_id, k)
    SA = user_items.get(target_user_id, set())
    if not SA or not neighbors:
        return

    print(f"===== TOP {k} HÀNG XÓM GẦN NHẤT CỦA USER {target_user_id} =====")
    for rank, (uid, score) in enumerate(neighbors, 1):
        SB = user_items.get(uid, set())
        inter = SA & SB
        print(f"{rank}. User {uid} – Jaccard = {score:.3f}, "
              f"{len(inter)} sách trùng")
        # in tối đa 5 sách trùng
        for i, isbn in enumerate(sorted(inter), 1):
            if i > 5:
                break
            title = isbn_title.get(isbn, "(Không tìm thấy tên sách)")
            print(f"    • Chung: {isbn} – {title}")
    print("====================================================\n")


def print_recommendations_detail(
    target_user_id: int,
    user_items: Dict[int, Set[str]],
    isbn_title: Dict[str, str],
    k_neighbors: int = 10,
    top_n: int = 10
):
    """
    In danh sách sách gợi ý cho user: ISBN + tên + score.
    """
    recs = recommend_for_user(user_items, target_user_id, k_neighbors, top_n)
    if not recs:
        print(f"❌ Không có gợi ý nào cho user {target_user_id}.")
        return

    print(f"===== TOP {top_n} GỢI Ý CHO USER {target_user_id} =====")
    for rank, (isbn, score) in enumerate(recs, 1):
        title = isbn_title.get(isbn, "(Không tìm thấy tên sách)")
        print(f"{rank:2d}. {isbn} – {title}   |   score = {score:.3f}")
    print("=================================================\n")


# ================== ĐÁNH GIÁ CF: HR@K, PRECISION@K ==================

def hit_rate_at_k(recommended: List[str], relevant: Set[str], k: int = 10) -> float:
    """
    Hit@K: = 1 nếu trong top-K có ÍT NHẤT 1 cuốn nằm trong tập relevant, ngược lại = 0.
    """
    top_k = recommended[:k]
    return 1.0 if any(item in relevant for item in top_k) else 0.0


def precision_at_k(recommended: List[str], relevant: Set[str], k: int = 10) -> float:
    """
    Precision@K: số cuốn đúng / K (nếu không có gợi ý thì = 0).
    """
    top_k = recommended[:k]
    if not top_k:
        return 0.0
    hits = sum(1 for item in top_k if item in relevant)
    return hits / float(k)


def evaluate_cf(
    recommendations: Dict[int, List[str]],
    ground_truth: Dict[int, Set[str]],
    k: int = 10
) -> Dict[str, float]:
    """
    Tính HR@K và Precision@K trung bình trên toàn bộ user trong ground_truth.
    """
    hr_list: List[float] = []
    prec_list: List[float] = []

    for uid, relevant_items in ground_truth.items():
        recs = recommendations.get(uid, [])
        hr_list.append(hit_rate_at_k(recs, relevant_items, k))
        prec_list.append(precision_at_k(recs, relevant_items, k))

    if not hr_list:
        return {f"HR@{k}": 0.0, f"Precision@{k}": 0.0}

    avg_hr = sum(hr_list) / len(hr_list)
    avg_prec = sum(prec_list) / len(prec_list)

    return {f"HR@{k}": avg_hr, f"Precision@{k}": avg_prec}


# =========== CHIA TRAIN / TEST (HOLD-OUT) CHO ĐÁNH GIÁ OFFLINE ===========

def train_test_split_holdout(
    user_items: Dict[int, Set[str]],
    min_items: int = 3,
    n_test: int = 1
) -> Tuple[Dict[int, Set[str]], Dict[int, Set[str]]]:
    """
    Tạo tập train/test đơn giản theo kiểu hold-out:
      - Với user có >= min_items sách:
          + Chọn n_test ISBN (theo thứ tự sorted) làm test.
          + Các ISBN còn lại dùng để train cho chính user đó.
      - Các user khác vẫn giữ nguyên lịch sử để làm hàng xóm.

    Trả về:
      - train_user_items: map user -> tập ISBN (đã bỏ bớt test của chính user đó)
      - ground_truth:     map user -> tập ISBN test (chỉ gồm user đủ điều kiện)
    """
    train_user_items: Dict[int, Set[str]] = {}
    ground_truth: Dict[int, Set[str]] = {}

    for uid, items in user_items.items():
        items_set = set(items)
        if len(items_set) >= min_items:
            sorted_items = sorted(items_set)
            test_items = set(sorted_items[:n_test])
            train_items = items_set - test_items

            train_user_items[uid] = train_items
            ground_truth[uid] = test_items
        else:
            # không dùng user này để test, nhưng vẫn giữ làm hàng xóm
            train_user_items[uid] = items_set

    return train_user_items, ground_truth


# ================== BASELINE: GỢI Ý SÁCH PHỔ BIẾN ==================

def build_popular_baseline(train_user_items: Dict[int, Set[str]]) -> List[str]:
    """
    Xây dựng danh sách ISBN phổ biến nhất từ dữ liệu train
    (dùng cho baseline "gợi ý sách phổ biến").
    """
    counter: Counter[str] = Counter()
    for items in train_user_items.values():
        counter.update(items)

    popular = [isbn for isbn, _ in counter.most_common()]
    return popular


def recommend_popular_for_user(
    popular_items: List[str],
    train_user_items: Dict[int, Set[str]],
    user_id: int,
    top_n: int = 10
) -> List[str]:
    """
    Gợi ý top-n sách phổ biến cho 1 user,
    loại bỏ những sách user đã mượn trong dữ liệu train.
    """
    already = train_user_items.get(user_id, set())
    result: List[str] = []
    for isbn in popular_items:
        if isbn in already:
            continue
        result.append(isbn)
        if len(result) >= top_n:
            break
    return result


def run_offline_evaluation(
    user_items: Dict[int, Set[str]],
    k_neighbors: int = 10,
    top_k_eval: int = 10,
    min_items: int = 3,
    n_test: int = 1
) -> None:
    """
    Chạy đánh giá offline:
      - Tách train/test bằng hold-out.
      - Đánh giá:
          + CF (user-based) hiện tại.
          + Baseline: gợi ý sách phổ biến nhất.
      - In HR@K và Precision@K cho cả hai.
    """
    print("\n===== BẮT ĐẦU ĐÁNH GIÁ OFFLINE CF =====")
    train_user_items, ground_truth = train_test_split_holdout(
        user_items, min_items=min_items, n_test=n_test
    )

    print(f"Số user được đưa vào tập kiểm thử: {len(ground_truth)}")
    if not ground_truth:
        print("❌ Không đủ dữ liệu để đánh giá (không user nào có đủ số ISBN).")
        return

    # 1) CF hiện tại
    recommendations_cf: Dict[int, List[str]] = {}
    for uid in ground_truth.keys():
        recs_scored = recommend_for_user(
            train_user_items, uid,
            k_neighbors=k_neighbors,
            top_n=top_k_eval
        )
        recs = [isbn for isbn, _ in recs_scored]
        recommendations_cf[uid] = recs

    metrics_cf = evaluate_cf(recommendations_cf, ground_truth, k=top_k_eval)

    # 2) Baseline: sách phổ biến
    popular_items = build_popular_baseline(train_user_items)
    recommendations_pop: Dict[int, List[str]] = {}
    for uid in ground_truth.keys():
        recommendations_pop[uid] = recommend_popular_for_user(
            popular_items, train_user_items, uid, top_n=top_k_eval
        )

    metrics_pop = evaluate_cf(recommendations_pop, ground_truth, k=top_k_eval)

    print("\n--- Kết quả đánh giá (so sánh CF và baseline phổ biến) ---")
    print(f"Top-K được dùng để đánh giá: K = {top_k_eval}")
    print(f"CF (User-based):   HR@{top_k_eval} = {metrics_cf[f'HR@{top_k_eval}']:.4f}, "
          f"Precision@{top_k_eval} = {metrics_cf[f'Precision@{top_k_eval}']:.4f}")
    print(f"Baseline phổ biến: HR@{top_k_eval} = {metrics_pop[f'HR@{top_k_eval}']:.4f}, "
          f"Precision@{top_k_eval} = {metrics_pop[f'Precision@{top_k_eval}']:.4f}")
    print("=========================================================\n")


# ================== MAIN: CHẠY ĐỂ LẤY DỮ LIỆU CHƯƠNG 3 ==================

if __name__ == "__main__":
    # 1) Load dữ liệu
    user_items = load_user_isbn_map()
    isbn_title = load_isbn_title_map()

    # 2) In thống kê tổng quan CF
    print_cf_global_stats(user_items)

    # 3) CHỌN 1 USER ĐỂ LÀM VÍ DỤ CF TRONG BÁO CÁO
    TARGET_USER_ID = 16   # bạn đổi id ở đây nếu muốn

    # 4) In sách user đã mượn
    print_user_detail(TARGET_USER_ID, user_items, isbn_title)

    # 5) In top-k hàng xóm
    print_neighbors_detail(TARGET_USER_ID, user_items, isbn_title, k=5)

    # 6) In top-n sách gợi ý
    print_recommendations_detail(
        TARGET_USER_ID,
        user_items,
        isbn_title,
        k_neighbors=10,
        top_n=10
    )

    # 7) Đánh giá offline CF vs baseline phổ biến
    run_offline_evaluation(
        user_items,
        k_neighbors=10,   # số hàng xóm dùng cho CF
        top_k_eval=10,    # K trong HR@K, Precision@K
        min_items=3,      # chỉ đánh giá user đã mượn >= 3 ISBN
        n_test=1          # mỗi user giữ lại 1 ISBN để test
    )
