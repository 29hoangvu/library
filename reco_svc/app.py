# app.py
from fastapi import FastAPI, HTTPException, Query, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import List, Dict, Set, Optional
from pydantic import BaseModel, Field
import os, re, json, asyncio, logging
import httpx

from dotenv import load_dotenv
load_dotenv()

from db import get_conn
from reco import recommend_user_cf
from scrapers import get_book_from_tiki, get_book_from_fahasa, NotFound  # fallback khi có ISBN

# ========== Logging ==========
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("reco_svc")

# ========== Keys ==========
GOOGLE_BOOKS_KEY = os.getenv("GOOGLE_BOOKS_KEY", "")
GEMINI_KEY = os.getenv("GOOGLE_API_KEY", "")

# ========== Gemini ==========
import google.generativeai as genai
if GEMINI_KEY:
    genai.configure(api_key=GEMINI_KEY)

# Ưu tiên các model mới hỗ trợ vision + generateContent (SDK tự map đúng API version)
PREFERRED_MODELS = [
    "gemini-2.5-flash",
    "gemini-2.5-flash-latest",
    "gemini-2.0-flash",
    "gemini-flash-latest",
    "gemini-2.5-pro",
    "gemini-pro-latest",
    # Fallback 1.5 (ổn định, có vision)
    "gemini-1.5-flash",
    "gemini-1.5-flash-002",
    "gemini-1.5-flash-latest",
    "gemini-1.5-pro",
    "gemini-1.5-pro-002",
]

def _pick_gemini_model() -> str:
    try:
        models = list(genai.list_models())
        supported = []
        for m in models:
            methods = set(getattr(m, "supported_generation_methods", []) or [])
            name = getattr(m, "name", "") or ""
            if "generateContent" in methods:
                supported.append(name)  # ví dụ: "models/gemini-2.5-flash"
        logger.info("Found %d models supporting generateContent", len(supported))
        for pref in PREFERRED_MODELS:
            full = f"models/{pref}"
            if full in supported:
                logger.info("Using preferred Gemini model: %s", full)
                return full
        if supported:
            logger.info("Using first available Gemini model: %s", supported[0])
            return supported[0]
    except Exception as e:
        logger.warning("Could not list models: %s", e)
    fallback = "models/gemini-1.5-flash"
    logger.info("Using fallback Gemini model: %s", fallback)
    return fallback

GEMINI_MODEL = _pick_gemini_model()
logger.info("Selected Gemini model: %s", GEMINI_MODEL)

def _build_gemini_prompt() -> str:
    return (
        "Bạn là trợ lý trích xuất metadata sách từ ảnh bìa. "
        "Hãy đọc TẤT CẢ chữ trên ảnh (kể cả gáy/cạnh) và trả về CHỈ JSON hợp lệ.\n\n"
        "Yêu cầu các khóa JSON (có thể null nếu không chắc):\n"
        "isbn, title, authorName, publisher, publicationYear, numberOfPages, format, language, confidence, notes\n\n"
        "Quy tắc:\n"
        "- ISBN: ưu tiên ISBN-13 (978/979); nếu không chắc để null.\n"
        "- publicationYear: chỉ YYYY; không suy diễn nếu không chắc.\n"
        "- numberOfPages: chỉ điền số nếu ảnh có ghi rõ; không đoán.\n"
        "- format: một trong [EBOOK, HARDCOVER, PAPERBACK] nếu thấy dấu hiệu; không thì null.\n"
        "- language: vi/en/... nếu nhận diện được; không thì null.\n"
        "- confidence: số thực 0..1 tổng thể.\n"
        "- notes: giải thích ngắn nguồn suy luận.\n"
    )

class GeminiBookSchema(BaseModel):
    isbn: Optional[str] = Field(None)
    title: Optional[str] = None
    authorName: Optional[str] = None
    publisher: Optional[str] = None
    publicationYear: Optional[int] = None
    numberOfPages: Optional[int] = None
    format: Optional[str] = None
    language: Optional[str] = None
    confidence: Optional[float] = None
    notes: Optional[str] = None

class ExtractResponse(BaseModel):
    isbn: Optional[str] = None
    title: Optional[str] = None
    authorName: Optional[str] = None
    publisher: Optional[str] = None
    publicationYear: Optional[int] = None
    numberOfPages: Optional[int] = None
    format: Optional[str] = None
    rawText: Optional[str] = None  # luôn None với Gemini

def _extract_first_json_block(text: str):
    if not text:
        return None
    start = text.find("{")
    while start != -1:
        depth = 0
        i = start
        in_str = False
        esc = False
        while i < len(text):
            ch = text[i]
            if in_str:
                if esc:
                    esc = False
                elif ch == '\\':
                    esc = True
                elif ch == '"':
                    in_str = False
            else:
                if ch == '"':
                    in_str = True
                elif ch == '{':
                    depth += 1
                elif ch == '}':
                    depth -= 1
                    if depth == 0:
                        block = text[start:i+1]
                        try:
                            return json.loads(block)
                        except Exception:
                            break
            i += 1
        start = text.find("{", start + 1)
    return None

async def _gemini_extract(image_bytes: bytes, mime_type: str = "image/jpeg") -> dict | None:
    if not GEMINI_KEY:
        logger.error("Gemini API key not configured")
        return None

    try:
        model = genai.GenerativeModel(
            GEMINI_MODEL,
            generation_config={
                "temperature": 0.2,
                "response_mime_type": "application/json",
            }
        )
    except Exception as e:
        logger.exception("Failed to initialize Gemini model: %s", e)
        raise HTTPException(status_code=503, detail=f"Không thể khởi tạo Gemini: {str(e)}")

    img_part = {"mime_type": mime_type or "image/jpeg", "data": image_bytes}
    prompt = _build_gemini_prompt()

    try:
        resp = await asyncio.to_thread(model.generate_content, [prompt, img_part])
    except Exception as e:
        logger.exception("Gemini generate_content failed: %s", e)
        raise HTTPException(status_code=503, detail=f"Gemini không phản hồi: {str(e)}")

    text = getattr(resp, "text", "")
    if not text:
        logger.error("Gemini returned empty response")
        raise HTTPException(status_code=503, detail="Gemini trả về response rỗng")

    data = None
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        data = _extract_first_json_block(text)

    if not data or not isinstance(data, dict):
        raw_preview = text[:400].replace("\n", " ")
        logger.warning("Gemini không trả JSON hợp lệ. Preview: %s", raw_preview)
        raise HTTPException(status_code=503, detail="Gemini trả về định dạng không hợp lệ")

    # lọc key + ép kiểu nhẹ
    valid_keys = set(GeminiBookSchema.model_fields.keys())
    clean = {k: v for k, v in data.items() if k in valid_keys}

    if "publicationYear" in clean and isinstance(clean["publicationYear"], str):
        clean["publicationYear"] = int(clean["publicationYear"]) if clean["publicationYear"].isdigit() else None
    if "numberOfPages" in clean and isinstance(clean["numberOfPages"], str):
        clean["numberOfPages"] = int(clean["numberOfPages"]) if clean["numberOfPages"].isdigit() else None
    if "confidence" in clean and isinstance(clean["confidence"], str):
        try:
            clean["confidence"] = float(clean["confidence"])
        except Exception:
            clean["confidence"] = None

    try:
        return GeminiBookSchema(**clean).model_dump()
    except Exception as e:
        logger.warning("Schema cast failed: %s ; data=%s", e, clean)
        return clean

# ========== Helpers ==========
def _year_from_date(date_str: Optional[str]) -> Optional[int]:
    if not date_str:
        return None
    for tok in str(date_str).split("-"):
        if tok.isdigit() and len(tok) == 4:
            y = int(tok)
            if 1400 <= y <= 2100:
                return y
    return None

def _pick(a, b):
    return a if a not in (None, "", []) else b

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

# ========== Enrichment ==========
import random
from httpx import HTTPError, ReadTimeout

async def _fetch_google_books(isbn: Optional[str]=None, title: Optional[str]=None, author: Optional[str]=None) -> Optional["BookMeta"]:
    def norm(s: str) -> str:
        import unicodedata
        s = unicodedata.normalize("NFKD", s or "")
        s = "".join(ch for ch in s if not unicodedata.combining(ch))
        return re.sub(r'[\W_]+', ' ', s).strip().lower()

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
    if GOOGLE_BOOKS_KEY:
        params["key"] = GOOGLE_BOOKS_KEY

    async with httpx.AsyncClient(timeout=10) as cli:
        last_err = None
        for attempt in range(3):
            try:
                r = await cli.get(url, params=params)
                if r.status_code != 200:
                    logger.warning("Google Books HTTP %s", r.status_code)
                    return None
                items = (r.json() or {}).get("items") or []
                break
            except (HTTPError, ReadTimeout) as e:
                last_err = e
                await asyncio.sleep(0.3 * (attempt + 1) + random.random() * 0.2)
        else:
            logger.warning("Google Books failed after retries: %s", last_err)
            return None
    if not items:
        return None

    tnorm = norm(title or "")
    anorm = norm(author or "")

    def has_isbn(vi):
        ids = vi.get("industryIdentifiers") or []
        return any(x.get("type") in ("ISBN_13", "ISBN_10") for x in ids)

    def score(it):
        vi = it.get("volumeInfo") or {}
        s = 0
        if norm(vi.get("title")) == tnorm:
            s += 40
        auths = [norm(a) for a in (vi.get("authors") or [])]
        if anorm and any(a.endswith(anorm) or anorm in a for a in auths):
            s += 25
        if has_isbn(vi):
            s += 60
        if vi.get("pageCount"):
            s += 5
        if (vi.get("imageLinks") or {}).get("thumbnail"):
            s += 5
        if vi.get("language") == "vi":
            s += 10
        return s

    items_sorted = sorted(items, key=score, reverse=True)
    vi = (items_sorted[0].get("volumeInfo") or {}) if items_sorted else {}
    ids = vi.get("industryIdentifiers") or []

    if not any(x.get("type") in ("ISBN_13", "ISBN_10") for x in ids):
        # kiếm item đầu tiên có ISBN
        for it in items_sorted:
            vii = (it.get("volumeInfo") or {})
            ids2 = vii.get("industryIdentifiers") or []
            if any(x.get("type") in ("ISBN_13", "ISBN_10") for x in ids2):
                vi = vii
                ids = ids2
                break

    isbn13 = next((x["identifier"] for x in ids if x.get("type") == "ISBN_13"), None)
    isbn10 = next((x["identifier"] for x in ids if x.get("type") == "ISBN_10"), None)

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

async def _fetch_openlibrary(isbn: Optional[str]=None, title: Optional[str]=None, author: Optional[str]=None) -> Optional["BookMeta"]:
    def _norm(s: str) -> str:
        return re.sub(r'[\W_]+', ' ', (s or '')).strip().lower()

    async with httpx.AsyncClient(timeout=10) as cli:
        if isbn:
            try:
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
                    pass
            except (HTTPError, ReadTimeout) as e:
                logger.warning("OpenLibrary ISBN failed: %s", e)

        if not title:
            return None

        params = {"title": title, "limit": 15}
        if author:
            params["author"] = author
        # Retry 3 lần cho /search.json
        last_err = None
        docs = None
        for attempt in range(3):
            try:
                r = await cli.get("https://openlibrary.org/search.json", params=params)
                if r.status_code == 200:
                    docs = r.json().get("docs") or []
                else:
                    logger.warning("OpenLibrary search HTTP %s", r.status_code)
                break
            except (HTTPError, ReadTimeout) as e:
                last_err = e
                await asyncio.sleep(0.3 * (attempt + 1))
        if docs is None:
            logger.warning("OpenLibrary search failed after retries: %s", last_err)
            return None
        if not docs:
            return None

        tnorm = _norm(title)
        anorm = _norm(author) if author else None

        def score(d):
            s = 0
            if _norm(d.get("title")) == tnorm:
                s += 50
            auths = d.get("author_name") or []
            if anorm and any(_norm(a) == anorm for a in auths):
                s += 30
            s += min(d.get("edition_count", 0), 20)
            if d.get("cover_i"):
                s += 5
            if d.get("number_of_pages_median"):
                s += 3
            return s

        best = max(docs, key=score)
        isbn_pick = (best.get("isbn") or [None])[0]

        # Nếu search doc không có trường isbn → kéo từ edition
        if not isbn_pick:
            eds = best.get("edition_key") or []
            if eds:
                edkey = eds[0]
                rd = await cli.get(f"https://openlibrary.org/books/{edkey}.json")
                if rd.status_code == 200:
                    bj = rd.json()
                    arr13 = bj.get("isbn_13") or []
                    arr10 = bj.get("isbn_10") or []
                    isbn_pick = (arr13[0] if arr13 else (arr10[0] if arr10 else None))

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

def _merge_meta(m1: Optional["BookMeta"], m2: Optional["BookMeta"]) -> Optional["BookMeta"]:
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

    async def _gather_safe(*aws):
        rs = await asyncio.gather(*aws, return_exceptions=True)
        out = []
        for r in rs:
            if isinstance(r, Exception):
                logger.warning("enrich subtask failed: %s", r)
                out.append(None)
            else:
                out.append(r)
        return out

    # Nếu có ISBN -> ưu tiên Google Books, OpenLibrary chỉ là phụ
    if isbn:
        g, o = await _gather_safe(
            _fetch_google_books(isbn=isbn, title=None, author=None),
            _fetch_openlibrary(isbn=isbn, title=None, author=None),
        )
    else:
        # Không có ISBN thì vẫn chạy song song 2 nguồn
        g, o = await _gather_safe(
            _fetch_google_books(isbn=None, title=title, author=authorName),
            _fetch_openlibrary(isbn=None, title=title, author=authorName),
        )


    meta = _merge_meta(o if not isbn else g, g if not isbn else o) if (g or o) else None

    # Fallback VN (Tiki/Fahasa) khi có ISBN nhưng vẫn chưa có meta
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

# ========== Pydantic ==========
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
    source: Optional[str] = None

# ========== App & CORS ==========
app = FastAPI(title="Reco Svc")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8080", "http://127.0.0.1:8080"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# ========== Routes ==========
@app.get("/health", operation_id="health_check")
def health():
    return {"ok": True}

@app.get("/diag")
def diag():
    return {
        "gemini_key_present": bool(GEMINI_KEY),
        "google_books_key_present": bool(GOOGLE_BOOKS_KEY),
    }

@app.get("/diag-gemini")
def diag_gemini():
    try:
        models = list(genai.list_models())
        out = []
        for m in models:
            out.append({
                "name": getattr(m, "name", ""),
                "methods": list(getattr(m, "supported_generation_methods", []) or [])
            })
        return {"ok": True, "models": out, "selected": GEMINI_MODEL}
    except Exception as e:
        return {"ok": False, "error": str(e)}

# ---- Gemini-only extract ----
@app.post("/extract-gemini", response_model=ExtractResponse, operation_id="extract_with_gemini")
async def extract_with_gemini(file: UploadFile = File(...)):
    try:
        img_bytes = await file.read()
        mime = file.content_type or "image/jpeg"

        g = await _gemini_extract(img_bytes, mime_type=mime)
        if not g:
            raise HTTPException(status_code=503, detail="Gemini chưa sẵn sàng hoặc không phản hồi")

        # Chuẩn hoá ISBN (chỉ chấp nhận ISBN-13 978/979 hoặc ISBN-10 hợp lệ)
        isbn = g.get("isbn")
        if isbn:
            s = re.sub(r'[^0-9Xx]', '', isbn)
            if (len(s) == 13 and s.startswith(("978", "979")) and _isbn13_valid(s)) or \
               (len(s) == 10 and _isbn10_valid(s)):
                isbn = s
            else:
                isbn = None

        title  = g.get("title")
        author = g.get("authorName")
        publisher = g.get("publisher")
        year   = g.get("publicationYear")
        pages  = g.get("numberOfPages")
        fmt    = g.get("format")

        # Enrich
        meta = None
        try:
            if isbn:
                meta = await _enrich_core(isbn, None, None)
            elif title:
                meta = await _enrich_core(None, title, author)
        except Exception:
            meta = None

        return ExtractResponse(
            isbn = (meta.isbn if meta else None) or isbn,
            title = (meta.title if meta and meta.title else None) or title,
            authorName = (meta.authorName if meta and meta.authorName else None) or author,
            publisher = (meta.publisher if meta and meta.publisher else None) or publisher,
            publicationYear = (meta.publicationYear if meta and meta.publicationYear else None) or year,
            numberOfPages = (meta.numberOfPages if meta and meta.numberOfPages else None) or pages,
            format = (meta.format if meta and meta.format else None) or fmt,
            rawText = None
        )

    except HTTPException:
        raise
    except Exception as e:
        return JSONResponse(status_code=500, content={"detail": f"Lỗi server: {str(e)}"})

# ---- Enrich (public) ----
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

# ---- Recommendation ----
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

# ---- Search ----
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
