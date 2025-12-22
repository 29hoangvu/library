from app import load_user_isbn_map
from reco import jaccard

def debug_top_neighbors(user_items: dict[int, set[str]], target_user_id: int, k: int = 10):
    SA = user_items.get(target_user_id, set())
    if not SA:
        print(f"❌ User {target_user_id} chưa mượn sách nào.")
        return

    sims = []
    for uid, items in user_items.items():
        if uid == target_user_id:
            continue
        s = jaccard(SA, items)
        if s > 0:
            sims.append((uid, s))

    sims.sort(key=lambda x: x[1], reverse=True)
    print(f"\n📊 Top {k} người dùng tương tự nhất với user {target_user_id}:\n")
    for rank, (uid, score) in enumerate(sims[:k], 1):
        print(f"{rank:2d}. User {uid:4d} – Jaccard = {score:.3f}")

# ---- Chạy thật từ DB ----
if __name__ == "__main__":
    user_items = load_user_isbn_map()
    debug_top_neighbors(user_items, target_user_id=16, k=10)
