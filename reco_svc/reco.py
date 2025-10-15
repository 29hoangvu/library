from collections import defaultdict

def jaccard(a: set, b: set) -> float:
    if not a and not b: return 0.0
    inter = len(a & b)
    uni = len(a | b)
    return 0.0 if uni == 0 else inter / uni

def recommend_user_cf(user_items: dict[int, set[str]],
                      target_user_id: int,
                      k: int = 20,
                      n: int = 10) -> list[str]:
    SA = user_items.get(target_user_id, set())
    # tính sim
    sims = []
    for uid, items in user_items.items():
        if uid == target_user_id: continue
        s = jaccard(SA, items)
        if s > 0: sims.append((uid, s))
    sims.sort(key=lambda x: x[1], reverse=True)
    sims = sims[:k]

    # chấm điểm
    score = defaultdict(float)
    for uid, w in sims:
        for isbn in user_items[uid]:
            if isbn not in SA:
                score[isbn] += w

    # top-n
    ranked = sorted(score.items(), key=lambda x: x[1], reverse=True)
    return [isbn for isbn, _ in ranked[:n]]

    