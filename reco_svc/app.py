# app.py
from fastapi import FastAPI, HTTPException, Query, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import List, Dict, Set, Optional
from pydantic import BaseModel

from PIL import Image, UnidentifiedImageError
import io, re
import asyncio
import httpx
import pytesseract
# thong bao khi khong tim thay
from scrapers import get_book_from_tiki, get_book_from_fahasa, NotFound

from db import get_conn
from reco import recommend_user_cf
import os
GOOGLE_BOOKS_KEY = os.getenv("AIzaSyDC3eO89WRzasiJ7U59VbbHB-bhMZU-msw", "")

if os.name == "nt":
    os.add_dll_directory(r"C:\zbar64\bin")
    # Không bắt buộc nếu đã copy libzbar-64.dll vào site-packages,
    # nhưng an toàn hơn khi chỉ rõ:
    os.environ.setdefault("ZBAR_DLL", r"C:\zbar64\bin\libzbar-64.dll")
# ============== Config OCR/Barcode ==============
# Nếu bạn không chạy Tesseract theo PATH, chỉnh lại dòng dưới
pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

# ============== Regex & helpers (trước khi định nghĩa route) ==============
ISBN_RE   = re.compile(r'\b(97[89][-– ]?\d{1,5}[-– ]?\d{1,7}[-– ]?\d{1,7}[-– ]?[\dxX])\b')
YEAR_RE   = re.compile(r'\b(1[5-9]\d{2}|20\d{2})\b')
PAGES_RE  = re.compile(r'(\d{2,4})\s*(?:trang|pages?)', re.IGNORECASE)
AUTHOR_HEADS  = [r"tác giả", r"author", r"\bby\b"]
PUBLISH_HEADS = [r"nhà xuất bản", r"\bnxb\b", r"publisher"]

def _clean_text(s: str) -> str:
    return re.sub(r'\s+', ' ', s or '').strip()

def _guess_format(txt: str) -> Optional[str]:
    t = (txt or "").lower()
    if "ebook" in t or "pdf" in t or "epub" in t: return "EBOOK"
    if "bìa cứng" in t or "hardcover" in t: return "HARDCOVER"
    if "bìa mềm" in t or "paperback" in t: return "PAPERBACK"
    return None

def _find_by_heads(lines, heads):
    pat = re.compile(r'(' + '|'.join(heads) + r')\s*[:\-]?\s*(.*)$', re.IGNORECASE)
    for ln in lines:
        m = pat.search(ln)
        if m:
            return _clean_text(m.group(2))
    return None

def _first_capital_line(lines):
    best, best_score = None, -1.0
    for ln in lines:
        words = [w for w in re.split(r'[^A-Za-zÀ-ỹ0-9]+', ln) if w]
        if not words:
            continue
        caps = sum(1 for w in words if w[:1].isupper())
        score = caps / max(1, len(words))
        if score > best_score and len(ln) > 10:
            best, best_score = ln, score
    return best

def _guess_title_from_lines(lines: List[str], fallback_text: Optional[str] = None) -> Optional[str]:
    t1 = _first_capital_line(lines)
    if t1:
        return _clean_text(t1)
    if lines:
        best = max(lines, key=len)
        if re.search(r'[A-Za-zÀ-ỹ]', best):
            return _clean_text(best)
    if fallback_text:
        parts = re.split(r'[.\n]+', fallback_text)
        parts = [p.strip() for p in parts if re.search(r'[A-Za-zÀ-ỹ]', p)]
        if parts:
            return max(parts, key=len)
    return None

def _preprocess_for_ocr(img: Image.Image) -> Image.Image:
    import numpy as np
    g = img.convert("L")
    arr = np.array(g)
    thr = int(arr.mean())
    bin_ = (arr > thr).astype("uint8") * 255
    return Image.fromarray(bin_)

from PIL import ImageOps

def _decode_barcode(img: Image.Image) -> Optional[str]:
    """
    Trả về ISBN hợp lệ (ưu tiên 13-digit 978/979). Bỏ qua các EAN nội địa (893, 880, ...).
    Thử xoay 0/90/180/270 và autocontrast để tăng tỉ lệ nhận diện.
    """
    if not HAS_ZBAR:
        return None

    candidates: List[str] = []
    # các biến thể để thử
    variants = []
    base = img
    variants.append(base)
    variants.append(ImageOps.autocontrast(base))
    for k in [1, 2, 3]:  # 90/180/270
        r = base.rotate(90 * k, expand=True)
        variants.append(r)
        variants.append(ImageOps.autocontrast(r))

    try:
        for im in variants:
            for code in zbar_decode(im):
                s = code.data.decode("utf-8", errors="ignore")
                digits = re.sub(r'[^0-9Xx]', '', s)
                if len(digits) == 13 and digits.startswith(("978", "979")) and _isbn13_valid(digits):
                    candidates.append(digits)
                elif len(digits) == 10 and _isbn10_valid(digits):
                    candidates.append(digits)
                # BỎ QUA EAN-13 khác (893..., 880..., ...) bằng cách không add
    except Exception:
        pass

    # ưu tiên ISBN-13 978/979
    for c in candidates:
        if len(c) == 13:
            return c
    return candidates[0] if candidates else None


def _ocr_text(img: Image.Image) -> str:
    proc = _preprocess_for_ocr(img)
    try:
        txt = pytesseract.image_to_string(proc, lang="vie+eng", config="--oem 3 --psm 6")
        if len(_clean_text(txt)) < 8:
            txt2 = pytesseract.image_to_string(proc, lang="vie+eng", config="--oem 3 --psm 7")
            if len(_clean_text(txt2)) > len(_clean_text(txt)):
                txt = txt2
        return txt or ""
    except Exception:
        return ""

def _year_from_date(date_str: Optional[str]) -> Optional[int]:
    if not date_str:
        return None
    for tok in date_str.split("-"):
        if tok.isdigit() and len(tok) == 4:
            y = int(tok)
            if 1400 <= y <= 2100:
                return y
    return None

def _pick(a, b):
    return a if a not in (None, "", []) else b

# ============== Pydantic models (trước khi dùng trong response_model) ==============
class ExtractResponse(BaseModel):
    isbn: Optional[str] = None
    title: Optional[str] = None
    authorName: Optional[str] = None
    publisher: Optional[str] = None
    publicationYear: Optional[int] = None
    numberOfPages: Optional[int] = None
    format: Optional[str] = None
    rawText: Optional[str] = None

class BookMeta(BaseModel):
    isbn: Optional[str] = None
    title: Optional[str] = None
    authorName: Optional[str] = None
    publisher: Optional[str] = None
    publicationYear: Optional[int] = None
    numberOfPages: Optional[int] = None
    format: Optional[str] = None
    language: Optional[str] = None
    coverImage: Optional[str] = None
    genres: Optional[List[str]] = None
    source: Optional[str] = None  # ghi chú nguồn dùng

# ============== App & CORS (trước các route) ==============
app = FastAPI(title="Reco Svc")

from pyzbar import zbar_library
zbar_library.load()  # xác thực có thể load DLL
from pyzbar.pyzbar import decode as zbar_decode
HAS_ZBAR = True
# --- Barcode support (optional)
try:
    from pyzbar.pyzbar import decode as zbar_decode
    HAS_ZBAR = True
except Exception:
    HAS_ZBAR = False

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8080", "http://127.0.0.1:8080"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# ============== DB helpers ==============
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

def filter_deleted(isbns: List[str]) -> List[str]:
    if not isbns:
        return []
    placeholders = ",".join(["%s"] * len(isbns))
    sql = f"""
      SELECT isbn
      FROM book
      WHERE isbn IN ({placeholders}) AND UPPER(status) <> 'DELETED'
    """
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, isbns)
            keep = [r["isbn"] for r in cur.fetchall()]
    order = {s: i for i, s in enumerate(isbns)}
    keep.sort(key=lambda s: order.get(s, 10**9))
    return keep

def fetch_book_cards(isbns: List[str]) -> List[dict]:
    if not isbns:
        return []
    placeholders = ",".join(["%s"] * len(isbns))
    sql = f"""
      SELECT b.isbn, b.title, b.coverImage, b.authorID, a.name AS author
      FROM book b
      LEFT JOIN author a ON a.id = b.authorID
      WHERE b.isbn IN ({placeholders})
    """
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, isbns)
            rows = cur.fetchall()
    order = {s: i for i, s in enumerate(isbns)}
    rows.sort(key=lambda r: order.get(r["isbn"], 10**9))
    return [
        {
            "isbn": r["isbn"],
            "title": r["title"],
            "coverImage": r["coverImage"],
            "author": r.get("author"),
            "authorID": r.get("authorID"),
        }
        for r in rows
    ]

@app.get("/health", operation_id="health_check")
def health():
    return {"ok": True}

# ============== Recommendation routes ==============
def _recommend_core(user_id: int, k: int, n: int) -> dict:
    user_items = load_user_isbn_map()
    already: Set[str] = user_items.get(user_id, set())
    if not already:
        return {"userId": user_id, "items": []}
    rec_isbns = recommend_user_cf(user_items, user_id, k, n) or []
    rec_isbns = list(dict.fromkeys(rec_isbns))
    rec_isbns = [s for s in rec_isbns if s not in already]
    rec_isbns = filter_deleted(rec_isbns)
    books = fetch_book_cards(rec_isbns)
    return {"userId": user_id, "items": books}

@app.get("/recommend/{user_id}", operation_id="recommend_by_path")
def recommend_path(user_id: int, k: int = 20, n: int = 10):
    try:
        return _recommend_core(user_id, k, n)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/recommend", operation_id="recommend_by_query")
def recommend_query(userId: int = Query(..., alias="userId"), k: int = 20, n: int = 10):
    try:
        return _recommend_core(userId, k, n)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============== Search routes ==============
@app.get("/search/suggestions", operation_id="search_suggestions")
def search_suggestions(
    q: str = Query(..., min_length=2),
    limit: int = 10
) -> List[Dict]:
    sql = """
        SELECT 
            b.isbn,
            b.title,
            b.coverImage,
            b.`format`,
            b.numberOfPages,
            b.publicationYear,
            a.name AS author,
            GROUP_CONCAT(DISTINCT g.name ORDER BY g.name SEPARATOR ', ') AS genres
        FROM book b
        LEFT JOIN author a       ON a.id = b.authorId
        LEFT JOIN book_genre bg  ON bg.book_id = b.id
        LEFT JOIN genre g        ON g.id = bg.genre_id
        WHERE
            (b.title              LIKE %s OR
             a.name               LIKE %s OR
             g.name               LIKE %s OR
             b.`format`           LIKE %s OR
             CAST(b.numberOfPages AS CHAR)    LIKE %s OR
             CAST(b.publicationYear AS CHAR)  LIKE %s)
          AND (b.status IS NULL OR UPPER(b.status) <> 'DELETED')
        GROUP BY b.isbn
        LIMIT %s
    """
    like = f"%{q}%"
    params = (like, like, like, like, like, like, limit)
    results: List[Dict] = []
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            for r in cur.fetchall():
                results.append({
                    "isbn": r["isbn"],
                    "title": r["title"],
                    "author": r.get("author"),
                    "genres": r.get("genres"),
                    "format": r.get("format"),
                    "numberOfPages": r.get("numberOfPages"),
                    "publicationYear": r.get("publicationYear"),
                    "coverImage": r.get("coverImage"),
                })
    return results

@app.get("/search/advanced", operation_id="search_advanced")
def search_advanced(
    q: Optional[str] = None,
    genre: Optional[str] = None,
    book_format: Optional[str] = Query(None, alias="format"),
    min_pages: Optional[int] = None,
    max_pages: Optional[int] = None,
    year_from: Optional[int] = None,
    year_to: Optional[int] = None,
    limit: int = 20,
):
    where = ["(b.status IS NULL OR UPPER(b.status) <> 'DELETED')"]
    params: list = []

    if q:
        like = f"%{q}%"
        where.append("(b.title LIKE %s OR a.name LIKE %s)")
        params += [like, like]

    if genre:
        where.append("g.name LIKE %s")
        params.append(f"%{genre}%")

    if book_format:
        where.append("b.`format` = %s")
        params.append(book_format)

    if min_pages is not None:
        where.append("b.numberOfPages >= %s")
        params.append(min_pages)

    if max_pages is not None:
        where.append("b.numberOfPages <= %s")
        params.append(max_pages)

    if year_from is not None:
        where.append("b.publicationYear >= %s")
        params.append(year_from)

    if year_to is not None:
        where.append("b.publicationYear <= %s")
        params.append(year_to)

    sql = f"""
        SELECT 
            b.isbn, b.title, b.coverImage, b.`format`,
            b.numberOfPages, b.publicationYear,
            a.name AS author,
            GROUP_CONCAT(DISTINCT g.name ORDER BY g.name SEPARATOR ', ') AS genres
        FROM book b
        LEFT JOIN author a      ON a.id = b.authorId
        LEFT JOIN book_genre bg ON bg.book_id = b.id
        LEFT JOIN genre g       ON g.id = bg.genre_id
        WHERE {" AND ".join(where)}
        GROUP BY b.isbn
        ORDER BY b.title
        LIMIT %s
    """
    params.append(limit)

    out = []
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, tuple(params))
            for r in cur.fetchall():
                out.append({
                    "isbn": r["isbn"],
                    "title": r["title"],
                    "author": r.get("author"),
                    "genres": r.get("genres"),
                    "format": r.get("format"),
                    "numberOfPages": r.get("numberOfPages"),
                    "publicationYear": r.get("publicationYear"),
                    "coverImage": r.get("coverImage"),
                })
    return out
#===============================================#
# --- ISBN validators ---
def _isbn10_valid(s: str) -> bool:
    s = re.sub(r'[^0-9Xx]', '', s)
    if len(s) != 10: 
        return False
    total = 0
    for i, ch in enumerate(s[:9], start=1):
        if not ch.isdigit(): 
            return False
        total += i * int(ch)
    check = s[9].upper()
    total += 10 * (10 if check == 'X' else int(check) if check.isdigit() else 0)
    return total % 11 == 0

def _isbn13_valid(s: str) -> bool:
    if len(s) != 13 or not s.isdigit(): 
        return False
    total = 0
    for i, d in enumerate(s[:12]):
        total += int(d) * (1 if i % 2 == 0 else 3)
    check = (10 - total % 10) % 10
    return check == int(s[12])

# --- OCR cho chuỗi số (whitelist) ---
def _ocr_digits(img: Image.Image) -> str:
    try:
        return pytesseract.image_to_string(
            img, lang="eng", config="--oem 3 --psm 6 -c tessedit_char_whitelist=0123456789Xx"
        )
    except Exception:
        return ""

# ============== Enrichment helpers & endpoints ==============
async def _fetch_google_books(isbn: Optional[str]=None, title: Optional[str]=None, author: Optional[str]=None) -> Optional[BookMeta]:
    def _norm(s: str) -> str:
        return re.sub(r'[\W_]+', ' ', (s or '')).strip().lower()

    if isbn:
        q = f"isbn:{isbn}"
    elif title and author:
        q = f'intitle:"{title}" inauthor:"{author}"'
    elif title:
        q = f'intitle:"{title}"'
    else:
        return None

    url = "https://www.googleapis.com/books/v1/volumes"
    params = {"q": q, "maxResults": 10}
     # ---- THÊM DÒNG NÀY ----
    if GOOGLE_BOOKS_KEY:
        params["key"] = GOOGLE_BOOKS_KEY
    async with httpx.AsyncClient(timeout=10) as cli:
        r = await cli.get(url, params=params)
        if r.status_code != 200:
            return None
        items = (r.json() or {}).get("items") or []
    if not items:
        return None

    tnorm = _norm(title or "")
    anorm = _norm(author or "")

    def score(it):
        vi = it.get("volumeInfo") or {}
        s = 0
        if _norm(vi.get("title")) == tnorm: s += 40
        if anorm and any(_norm(a) == anorm for a in (vi.get("authors") or [])): s += 25
        if vi.get("pageCount"): s += 5
        if (vi.get("imageLinks") or {}).get("thumbnail"): s += 5
        s += len(vi.keys())
        return s

    best = max(items, key=score)
    vi = best.get("volumeInfo") or {}
    industry = vi.get("industryIdentifiers") or []
    isbn13 = next((x["identifier"] for x in industry if x.get("type") == "ISBN_13"), None)
    isbn10 = next((x["identifier"] for x in industry if x.get("type") == "ISBN_10"), None)

    return BookMeta(
        isbn = isbn or isbn13 or isbn10,
        title = vi.get("title"),
        authorName = (vi.get("authors") or [None])[0],
        publisher = vi.get("publisher"),
        publicationYear = _year_from_date(vi.get("publishedDate")),
        numberOfPages = vi.get("pageCount"),
        format = None,
        language = vi.get("language"),
        coverImage = ((vi.get("imageLinks") or {}).get("thumbnail") or (vi.get("imageLinks") or {}).get("smallThumbnail")),
        genres = vi.get("categories") or [],
        source = "google_books"
    )

async def _fetch_openlibrary(isbn: Optional[str]=None, title: Optional[str]=None, author: Optional[str]=None) -> Optional[BookMeta]:
    def _norm(s: str) -> str:
        return re.sub(r'[\W_]+', ' ', (s or '')).strip().lower()

    async with httpx.AsyncClient(timeout=10) as cli:
        if isbn:
            r = await cli.get(f"https://openlibrary.org/isbn/{isbn}.json")
            if r.status_code == 200:
                b = r.json()
                works = b.get("works") or []
                work_key = works[0]["key"] if works else None
                subjects = []
                if work_key:
                    rw = await cli.get(f"https://openlibrary.org{work_key}.json")
                    if rw.status_code == 200:
                        wj = rw.json()
                        subjects = wj.get("subjects") or []

                authorName = None
                auths = b.get("authors") or []
                if auths:
                    ak = auths[0].get("key")
                    if ak:
                        ra = await cli.get(f"https://openlibrary.org{ak}.json")
                        if ra.status_code == 200:
                            authorName = ra.json().get("name")

                cover = None
                covers = b.get("covers") or []
                if covers:
                    cover = f"https://covers.openlibrary.org/b/id/{covers[0]}-L.jpg"

                publisher = (b.get("publishers") or [None])[0]
                year = _year_from_date(b.get("publish_date"))
                pages = b.get("number_of_pages")
                lang = None
                langs = b.get("languages") or []
                if langs:
                    lang = (langs[0].get("key") or "").split("/")[-1] or None

                title2 = b.get("title")
                return BookMeta(
                    isbn=isbn, title=title2, authorName=authorName, publisher=publisher,
                    publicationYear=year, numberOfPages=pages, format=None, language=lang,
                    coverImage=cover, genres=subjects[:8], source="openlibrary"
                )

        if not title:
            return None

        params = {"title": title, "limit": 15}
        if author: params["author"] = author
        r = await cli.get("https://openlibrary.org/search.json", params=params)
        if r.status_code != 200: return None
        docs = r.json().get("docs") or []
        if not docs: return None

        tnorm = _norm(title)
        anorm = _norm(author) if author else None

        def score(d):
            s = 0
            if _norm(d.get("title")) == tnorm: s += 50
            auths = d.get("author_name") or []
            if anorm and any(_norm(a) == anorm for a in auths): s += 30
            s += min(d.get("edition_count", 0), 20)
            if d.get("cover_i"): s += 5
            if d.get("number_of_pages_median"): s += 3
            # mẹo điểm cho "The Road" (ví dụ minh hoạ) - giữ nguyên nếu bạn cần
            if not anorm and _norm(d.get("title")) == "the road" and any("cormac" in _norm(a) for a in auths):
                s += 25
            return s

        best = max(docs, key=score)
        isbn_pick = (best.get("isbn") or [None])[0]
        cover = f"https://covers.openlibrary.org/b/id/{best['cover_i']}-L.jpg" if best.get("cover_i") else None

        return BookMeta(
            isbn=isbn_pick,
            title=best.get("title"),
            authorName=(best.get("author_name") or [None])[0],
            publisher=(best.get("publisher") or [None])[0],
            publicationYear=best.get("first_publish_year"),
            numberOfPages=best.get("number_of_pages_median"),
            format=None,
            language=(best.get("language") or [None])[0],
            coverImage=cover,
            genres=(best.get("subject") or [])[:8],
            source="openlibrary"
        )

def _merge_meta(m1: Optional[BookMeta], m2: Optional[BookMeta]) -> Optional[BookMeta]:
    if not m1 and not m2:
        return None
    if m1 and not m2:
        return m1
    if m2 and not m1:
        return m2
    return BookMeta(
        isbn=_pick(m1.isbn, m2.isbn),
        title=_pick(m1.title, m2.title),
        authorName=_pick(m1.authorName, m2.authorName),
        publisher=_pick(m1.publisher, m2.publisher),
        publicationYear=_pick(m1.publicationYear, m2.publicationYear),
        numberOfPages=_pick(m1.numberOfPages, m2.numberOfPages),
        format=_pick(m1.format, m2.format),
        language=_pick(m1.language, m2.language),
        coverImage=_pick(m1.coverImage, m2.coverImage),
        genres=_pick(m1.genres, m2.genres),
        source="merged"
    )

async def _enrich_core(isbn: Optional[str], title: Optional[str], authorName: Optional[str]):
    if not isbn and not title:
        raise HTTPException(status_code=400, detail="Provide at least isbn or title")

    g_task = _fetch_google_books(isbn=isbn, title=title, author=authorName)
    o_task = _fetch_openlibrary(isbn=isbn, title=title, author=authorName)
    g, o = await asyncio.gather(g_task, o_task)
    meta = _merge_meta(o if not isbn else g, g if not isbn else o) if (g or o) else None

    # ---- Fallback: Tiki/Fahasa khi có ISBN mà meta vẫn None ----
    if not meta and isbn:
        try:
            tk = await get_book_from_tiki(isbn)
            meta = BookMeta(
                isbn=tk.get("isbn") or isbn,
                title=tk.get("title"),
                authorName=tk.get("authorName"),
                publisher=tk.get("publisher"),
                numberOfPages=None,
                publicationYear=None,
                format=None,
                language=None,
                coverImage=tk.get("coverImage"),
                genres=None,
                source="tiki",
            )
        except Exception:
            pass

        if not meta:
            try:
                fh = await get_book_from_fahasa(isbn)
                meta = BookMeta(
                    isbn=fh.get("isbn") or isbn,
                    title=fh.get("title"),
                    authorName=fh.get("authorName"),
                    publisher=fh.get("publisher"),
                    numberOfPages=None,
                    publicationYear=None,
                    format=None,
                    language=None,
                    coverImage=fh.get("coverImage"),
                    genres=None,
                    source="fahasa",
                )
            except Exception:
                pass

    if not meta:
        raise HTTPException(status_code=404, detail="No match found")

    return meta


@app.post("/enrich", response_model=BookMeta, operation_id="enrich_meta_post")
async def enrich_post(
    isbn: Optional[str] = Form(None),
    title: Optional[str] = Form(None),
    authorName: Optional[str] = Form(None),
):
    return await _enrich_core(isbn, title, authorName)

@app.get("/enrich", response_model=BookMeta, operation_id="enrich_meta_get")
async def enrich_get(
    isbn: Optional[str] = None,
    title: Optional[str] = None,
    authorName: Optional[str] = None,
):
    return await _enrich_core(isbn, title, authorName)

# ============== OCR routes ==============
@app.post("/extract-dual", response_model=ExtractResponse, operation_id="extract_dual")
async def extract_dual(front: UploadFile = File(...), back: UploadFile = File(...)):
    """
    - OCR từ ảnh bìa trước → lấy title/author/publisher/year/pages/format (+ISBN nếu bắt được).
    - Barcode ưu tiên từ bìa sau → lấy ISBN.
    - So khớp và hợp nhất, rồi (nếu cần) tự enrich bằng Internet.
    """
    try:
        # ---- Load ảnh ----
        fb = await front.read()
        bb = await back.read()

        def load_rgb(data):
            try:
                im = Image.open(io.BytesIO(data)).convert("RGB")
                MAX_SIDE = 1600
                w, h = im.size
                if max(w, h) > MAX_SIDE:
                    ratio = MAX_SIDE / float(max(w, h))
                    im = im.resize((int(w*ratio), int(h*ratio)))
                return im
            except UnidentifiedImageError:
                return None

        img_front = load_rgb(fb)
        img_back  = load_rgb(bb)
        if img_front is None or img_back is None:
            raise HTTPException(status_code=400, detail="Ảnh không hợp lệ")

        # ---- Barcode (ưu tiên mặt sau) ----
        isbn_barcode = _decode_barcode(img_back) or _decode_barcode(img_front)
        # Fallback: thử OCR mặt sau để bắt chuỗi ISBN nếu barcode không đọc được
        if not isbn_barcode:
            back_txt = _clean_text(_ocr_digits(_preprocess_for_ocr(img_back)))
            m_back = ISBN_RE.search(back_txt.replace("–", "-"))
            if m_back:
                cand = re.sub(r'[-\s]', '', m_back.group(1))
                if (len(cand) == 13 and cand.startswith(("978", "979")) and _isbn13_valid(cand)) or \
                (len(cand) == 10 and _isbn10_valid(cand)):
                    isbn_barcode = cand
        # ---- OCR (mặt trước) ----
        ocr_text = _ocr_text(img_front)
        text  = _clean_text(ocr_text)
        lines = [_clean_text(l) for l in ocr_text.splitlines() if _clean_text(l)]

        # ISBN từ OCR (dự phòng)
        isbn_ocr = None
        m = ISBN_RE.search(text.replace("–", "-"))
        if m:
            cand = re.sub(r'[-\s]', '', m.group(1))
            if (len(cand) == 13 and cand.startswith(("978","979")) and _isbn13_valid(cand)) or \
            (len(cand) == 10 and _isbn10_valid(cand)):
                isbn_ocr = cand
        # Trích tiêu đề/tác giả/…
        title     = _first_capital_line(lines) or _guess_title_from_lines(lines, text)
        author    = _find_by_heads(lines, AUTHOR_HEADS)
        publisher = _find_by_heads(lines, PUBLISH_HEADS)

        year = None
        my = YEAR_RE.search(text)
        if my:
            try:
                y = int(my.group(1))
                if 1400 <= y <= 2100: year = y
            except:
                pass

        pages = None
        mp = PAGES_RE.search(text)
        if mp:
            try:
                pages = int(mp.group(1))
            except:
                pass

        fmt = _guess_format(text)

        # ---- So khớp & chọn ISBN ----
        explain_parts = []
        chosen_isbn = None
        if isbn_barcode and isbn_ocr:
            if isbn_barcode == isbn_ocr:
                chosen_isbn = isbn_barcode
                explain_parts.append(f"Barcode và OCR khớp ISBN {chosen_isbn}.")
                confidence = 0.98
            else:
                chosen_isbn = isbn_barcode  # ưu tiên barcode
                explain_parts.append(f"Xung đột ISBN (barcode={isbn_barcode}, ocr={isbn_ocr}). Ưu tiên barcode.")
                confidence = 0.9
        elif isbn_barcode:
            chosen_isbn = isbn_barcode
            explain_parts.append(f"Lấy ISBN từ barcode: {chosen_isbn}.")
            confidence = 0.95
        elif isbn_ocr:
            chosen_isbn = isbn_ocr
            explain_parts.append(f"Không có barcode, lấy ISBN từ OCR: {chosen_isbn}.")
            confidence = 0.75
        else:
            confidence = 0.55
            explain_parts.append("Không tìm thấy ISBN; sẽ enrich bằng tiêu đề/tác giả nếu có.")

        # ---- Enrich (ưu tiên dùng ISBN nếu có) ----
        meta = None
        try:
            if chosen_isbn:
                meta = await _enrich_core(chosen_isbn, None, None)
                explain_parts.append("Enrich theo ISBN (ưu tiên) thành công.")
            elif title:
                meta = await _enrich_core(None, title, author)
                explain_parts.append("Enrich theo Title/Author (không có ISBN).")
        except Exception as e:
            explain_parts.append(f"Enrich thất bại: {str(e)}")

        # ---- Hợp nhất dữ liệu OCR + Enrich ----
        resp = ExtractResponse(
            isbn = (meta.isbn if meta else None) or chosen_isbn,
            title = (meta.title if meta and meta.title else None) or title,
            authorName = (meta.authorName if meta and meta.authorName else None) or author,
            publisher = (meta.publisher if meta and meta.publisher else None) or publisher,
            publicationYear = (meta.publicationYear if meta and meta.publicationYear else None) or year,
            numberOfPages = (meta.numberOfPages if meta and meta.numberOfPages else None) or pages,
            format = (meta.format if meta and meta.format else None) or fmt,
            rawText = text[:2000]
        )
        base = resp.dict()
        base["confidence"] = confidence
        base["explain"] = " ".join(explain_parts)
        return JSONResponse(content=base)

    except HTTPException:
        raise
    except Exception as e:
        return JSONResponse(status_code=500, content={"detail": f"Lỗi server: {str(e)}"})

@app.post("/extract", response_model=ExtractResponse, operation_id="extract_image")
async def extract_from_image(file: UploadFile = File(...)):
    try:
        img_bytes = await file.read()
        try:
            img = Image.open(io.BytesIO(img_bytes)).convert("RGB")
        except UnidentifiedImageError:
            return JSONResponse(status_code=400, content={"detail": "File không phải ảnh hợp lệ"})

        MAX_SIDE = 1600
        w, h = img.size
        if max(w, h) > MAX_SIDE:
            ratio = MAX_SIDE / float(max(w, h))
            img = img.resize((int(w*ratio), int(h*ratio)))

        proc = _preprocess_for_ocr(img)

        isbn = _decode_barcode(img)

        try:
            ocr_text = pytesseract.image_to_string(proc, lang="vie+eng", config="--oem 3 --psm 6")
            if len(_clean_text(ocr_text)) < 8:
                ocr_text2 = pytesseract.image_to_string(proc, lang="vie+eng", config="--oem 3 --psm 7")
                if len(_clean_text(ocr_text2)) > len(_clean_text(ocr_text)):
                    ocr_text = ocr_text2
        except pytesseract.TesseractNotFoundError:
            return JSONResponse(status_code=500, content={"detail": "Chưa cài Tesseract trên máy chủ"})
        except Exception as e:
            return JSONResponse(status_code=500, content={"detail": f"OCR lỗi: {str(e)}"})

        text  = _clean_text(ocr_text or "")
        lines = [_clean_text(l) for l in (ocr_text or "").splitlines() if _clean_text(l)]

        if not isbn:
            m = ISBN_RE.search(text.replace("–", "-"))
            if m:
                cand = re.sub(r'[-\s]', '', m.group(1))
                if (len(cand) == 13 and cand.startswith(("978","979")) and _isbn13_valid(cand)) or \
                (len(cand) == 10 and _isbn10_valid(cand)):
                    isbn = cand

        title     = _first_capital_line(lines) or _guess_title_from_lines(lines, text)
        author    = _find_by_heads(lines, AUTHOR_HEADS)
        publisher = _find_by_heads(lines, PUBLISH_HEADS)

        year = None
        my = YEAR_RE.search(text)
        if my:
            try:
                y = int(my.group(1))
                if 1400 <= y <= 2100: year = y
            except:
                pass

        pages = None
        mp = PAGES_RE.search(text)
        if mp:
            try:
                pages = int(mp.group(1))
            except:
                pass

        fmt = _guess_format(text)

        # Auto-enrich khi không có ISBN nhưng có title
        if not isbn and title:
            try:
                meta = await _enrich_core(None, title, author)
                return ExtractResponse(
                    isbn=meta.isbn or isbn,
                    title=meta.title or title,
                    authorName=meta.authorName or author,
                    publisher=meta.publisher or publisher,
                    publicationYear=meta.publicationYear or year,
                    numberOfPages=meta.numberOfPages or pages,
                    format=meta.format or fmt,
                    rawText=text[:2000]
                )
            except Exception:
                pass

        return ExtractResponse(
            isbn=isbn, title=title, authorName=author, publisher=publisher,
            publicationYear=year, numberOfPages=pages, format=fmt, rawText=text[:2000]
        )
    except Exception as e:
        return JSONResponse(status_code=500, content={"detail": f"Lỗi server: {str(e)}"})
    