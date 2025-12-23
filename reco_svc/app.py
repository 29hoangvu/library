from fastapi import FastAPI, HTTPException, Query, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import List, Dict, Set, Optional
from pydantic import BaseModel, Field
import os, re, json, asyncio, logging, base64
import httpx

from dotenv import load_dotenv
load_dotenv(override=True)

from db import get_conn
from reco import recommend_user_cf
from scrapers import get_book_from_tiki, get_book_from_fahasa, NotFound

# ========== Logging ==========
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("reco_svc")

# ========== Keys ==========
GOOGLE_BOOKS_KEY = os.getenv("GOOGLE_BOOKS_KEY", "")
GEMINI_KEY = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY", "")

logger.info(f"GEMINI_KEY: {GEMINI_KEY[:20]}..." if GEMINI_KEY else "NOT SET")
logger.info(f"GOOGLE_BOOKS_KEY: {'YES' if GOOGLE_BOOKS_KEY else 'NO'}")

GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

# ========== Gemini ==========
def _build_gemini_prompt() -> str:
    return (
        "Bạn là trợ lý trích xuất metadata sách từ ảnh bìa.\n\n"
        "PHÂN TÍCH KỸ ẢNH:\n"
        "- MẶT TRƯỚC: TÊN SÁCH (chữ lớn), TÁC GIẢ, hình minh họa\n"
        "- MẶT SAU: ISBN barcode, mô tả, giá\n"
        "- Nếu chỉ thấy ISBN → chỉ trả isbn, notes='mặt sau'\n\n"
        "TRƯỜNG JSON (null nếu không có):\n"
        "isbn, title, authorName, publisher, publicationYear, numberOfPages, format, language, confidence, notes\n\n"
        "QUY TẮC:\n"
        "- ISBN: 13 số (978/979) hoặc 10 số\n"
        "- title: Tên sách (CHỮ LỚN NHẤT)\n"
        "- authorName: Tên tác giả\n"
        "- publisher: Nhà xuất bản (NXB...)\n"
        "- publicationYear: chỉ năm YYYY\n"
        "- numberOfPages: chỉ số nếu thấy rõ\n"
        "- format: EBOOK/HARDCOVER/PAPERBACK\n"
        "- language: vi/en\n"
        "- confidence: 0-1\n"
        "Trả về CHỈ JSON, không markdown."
    )

class GeminiBookSchema(BaseModel):
    isbn: Optional[str] = None
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
    rawText: Optional[str] = None

def _extract_json(text: str):
    if not text:
        return None
    start = text.find("{")
    while start != -1:
        depth, i, in_str, esc = 0, start, False, False
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
                        try:
                            return json.loads(text[start:i+1])
                        except:
                            break
            i += 1
        start = text.find("{", start + 1)
    return None

async def _call_gemini(payload: dict) -> dict:
    if not GEMINI_KEY:
        raise HTTPException(503, "Gemini key missing")
    async with httpx.AsyncClient(timeout=30) as cli:
        try:
            r = await cli.post(GEMINI_ENDPOINT, params={"key": GEMINI_KEY}, json=payload)
            if r.status_code != 200:
                logger.error("Gemini %s: %s", r.status_code, r.text)
                raise HTTPException(503, f"Gemini {r.status_code}")
            return r.json()
        except httpx.TimeoutException:
            raise HTTPException(503, "Gemini timeout")
        except httpx.RequestError as e:
            raise HTTPException(503, f"Gemini error: {e}")

async def _gemini_extract(image_bytes: bytes, mime: str = "image/jpeg") -> dict:
    b64 = base64.b64encode(image_bytes).decode()
    payload = {
        "contents": [{
            "role": "user",
            "parts": [
                {"text": _build_gemini_prompt()},
                {"inlineData": {"mimeType": mime, "data": b64}}
            ]
        }],
        "generationConfig": {"temperature": 0.2}
    }
    data = await _call_gemini(payload)
    try:
        text = data["candidates"][0]["content"]["parts"][0].get("text", "")
    except (KeyError, IndexError):
        raise HTTPException(503, "Invalid Gemini response")
    if not text:
        raise HTTPException(503, "Empty Gemini response")
    
    try:
        parsed = json.loads(text)
    except:
        parsed = _extract_json(text)
    
    if not isinstance(parsed, dict):
        raise HTTPException(503, "Invalid JSON from Gemini")
    
    valid = set(GeminiBookSchema.model_fields.keys())
    clean = {k: v for k, v in parsed.items() if k in valid}
    
    for k in ["publicationYear", "numberOfPages"]:
        if k in clean and isinstance(clean[k], str):
            clean[k] = int(clean[k]) if clean[k].isdigit() else None
    if "confidence" in clean and isinstance(clean["confidence"], str):
        try:
            clean["confidence"] = float(clean["confidence"])
        except:
            clean["confidence"] = None
    
    try:
        return GeminiBookSchema(**clean).model_dump()
    except:
        return clean

# ========== Helpers ==========
def _year_from_date(s):
    if not s:
        return None
    for t in str(s).split("-"):
        if t.isdigit() and len(t) == 4:
            y = int(t)
            if 1400 <= y <= 2100:
                return y

def _pick(a, b):
    return a if a not in (None, "", []) else b

def _isbn10_valid(s: str) -> bool:
    s = re.sub(r'[^0-9Xx]', '', s)
    if len(s) != 10:
        return False
    total = sum((i + 1) * int(s[i]) for i in range(9))
    check = s[9].upper()
    total += 10 * (10 if check == 'X' else int(check) if check.isdigit() else 0)
    return total % 11 == 0

def _isbn13_valid(s: str) -> bool:
    if len(s) != 13 or not s.isdigit():
        return False
    total = sum(int(s[i]) * (1 if i % 2 == 0 else 3) for i in range(12))
    return (10 - total % 10) % 10 == int(s[12])

# ========== Enrich ==========
import random
from httpx import HTTPError, ReadTimeout

async def _fetch_google_books(isbn=None, title=None, author=None):
    def norm(s):
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
        for _ in range(3):
            try:
                r = await cli.get(url, params=params)
                if r.status_code == 200:
                    items = r.json().get("items", [])
                    break
            except:
                await asyncio.sleep(0.3)
        else:
            return None
    
    if not items:
        return None
    
    tnorm, anorm = norm(title or ""), norm(author or "")
    def score(it):
        vi = it.get("volumeInfo", {})
        s = 0
        if norm(vi.get("title")) == tnorm:
            s += 40
        auths = [norm(a) for a in vi.get("authors", [])]
        if anorm and any(a.endswith(anorm) or anorm in a for a in auths):
            s += 25
        ids = vi.get("industryIdentifiers", [])
        if any(x.get("type") in ("ISBN_13", "ISBN_10") for x in ids):
            s += 60
        if vi.get("pageCount"):
            s += 5
        if vi.get("imageLinks", {}).get("thumbnail"):
            s += 5
        if vi.get("language") == "vi":
            s += 10
        return s
    
    items.sort(key=score, reverse=True)
    vi = items[0].get("volumeInfo", {})
    ids = vi.get("industryIdentifiers", [])
    isbn13 = next((x["identifier"] for x in ids if x.get("type") == "ISBN_13"), None)
    isbn10 = next((x["identifier"] for x in ids if x.get("type") == "ISBN_10"), None)
    
    return BookMeta(
        isbn=isbn or isbn13 or isbn10,
        title=vi.get("title"),
        authorName=(vi.get("authors") or [None])[0],
        publisher=vi.get("publisher"),
        publicationYear=_year_from_date(vi.get("publishedDate")),
        numberOfPages=vi.get("pageCount"),
        format=None,
        language=vi.get("language"),
        coverImage=(vi.get("imageLinks", {}).get("thumbnail") or vi.get("imageLinks", {}).get("smallThumbnail")),
        genres=vi.get("categories", []),
        source="google_books"
    )

async def _fetch_openlibrary(isbn=None, title=None, author=None):
    def norm(s):
        return re.sub(r'[\W_]+', ' ', (s or '')).strip().lower()
    
    async with httpx.AsyncClient(timeout=10) as cli:
        if isbn:
            try:
                r = await cli.get(f"https://openlibrary.org/isbn/{isbn}.json")
                if r.status_code == 200:
                    b = r.json()
                    return BookMeta(
                        isbn=isbn,
                        title=b.get("title"),
                        authorName=None,
                        publisher=(b.get("publishers") or [None])[0],
                        publicationYear=_year_from_date(b.get("publish_date")),
                        numberOfPages=b.get("number_of_pages"),
                        format=None,
                        language=None,
                        coverImage=f"https://covers.openlibrary.org/b/id/{b['covers'][0]}-L.jpg" if b.get("covers") else None,
                        genres=[],
                        source="openlibrary"
                    )
            except:
                pass
        
        if not title:
            return None
        
        params = {"title": title, "limit": 15}
        if author:
            params["author"] = author
        
        for _ in range(3):
            try:
                r = await cli.get("https://openlibrary.org/search.json", params=params)
                if r.status_code == 200:
                    docs = r.json().get("docs", [])
                    break
            except:
                await asyncio.sleep(0.3)
        else:
            return None
        
        if not docs:
            return None
        
        tnorm, anorm = norm(title), norm(author) if author else None
        def score(d):
            s = 0
            if norm(d.get("title")) == tnorm:
                s += 50
            if anorm and any(norm(a) == anorm for a in d.get("author_name", [])):
                s += 30
            s += min(d.get("edition_count", 0), 20)
            if d.get("cover_i"):
                s += 5
            return s
        
        best = max(docs, key=score)
        return BookMeta(
            isbn=(best.get("isbn") or [None])[0],
            title=best.get("title"),
            authorName=(best.get("author_name") or [None])[0],
            publisher=(best.get("publisher") or [None])[0],
            publicationYear=best.get("first_publish_year"),
            numberOfPages=best.get("number_of_pages_median"),
            format=None,
            language=None,
            coverImage=f"https://covers.openlibrary.org/b/id/{best['cover_i']}-L.jpg" if best.get("cover_i") else None,
            genres=(best.get("subject") or [])[:8],
            source="openlibrary"
        )

def _merge_meta(m1, m2):
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

async def _enrich_core(isbn, title, authorName):
    if not isbn and not title:
        raise HTTPException(400, "Need isbn or title")
    
    async def safe(*aws):
        rs = await asyncio.gather(*aws, return_exceptions=True)
        return [r if not isinstance(r, Exception) else None for r in rs]
    
    if isbn:
        g, o = await safe(_fetch_google_books(isbn=isbn), _fetch_openlibrary(isbn=isbn))
    else:
        g, o = await safe(_fetch_google_books(title=title, author=authorName),
                         _fetch_openlibrary(title=title, author=authorName))
    
    meta = _merge_meta(o if not isbn else g, g if not isbn else o)
    
    if not meta and isbn:
        try:
            tk = await get_book_from_tiki(isbn)
            meta = BookMeta(isbn=isbn, title=tk.get("title"), authorName=tk.get("authorName"),
                           publisher=tk.get("publisher"), coverImage=tk.get("coverImage"), source="tiki")
        except:
            pass
        if not meta:
            try:
                fh = await get_book_from_fahasa(isbn)
                meta = BookMeta(isbn=isbn, title=fh.get("title"), authorName=fh.get("authorName"),
                               publisher=fh.get("publisher"), coverImage=fh.get("coverImage"), source="fahasa")
            except:
                pass
    
    if not meta:
        raise HTTPException(404, "No match found")
    return meta

# ========== Models ==========
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

# ========== App ==========
app = FastAPI(title="Reco Svc")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True,
                   allow_methods=["*"], allow_headers=["*"])

@app.get("/diag")
def diag():
    return {
        "gemini_key": GEMINI_KEY[:20] if GEMINI_KEY else "NOT SET",
        "google_books_key": bool(GOOGLE_BOOKS_KEY),
    }

@app.get("/diag-gemini")
async def diag_gemini():
    data = await _call_gemini({"contents": [{"role": "user", "parts": [{"text": "ping"}]}]})
    return {"ok": True, "reply": data["candidates"][0]["content"]["parts"][0]["text"]}

# ========== Extract Endpoints ==========
@app.post("/extract-gemini", response_model=ExtractResponse)
async def extract_single(file: UploadFile = File(...)):
    """Extract from single image - auto-enriches if only ISBN found"""
    img = await file.read()
    g = await _gemini_extract(img, file.content_type or "image/jpeg")
    
    # Validate ISBN
    isbn = g.get("isbn")
    if isbn:
        s = re.sub(r'[^0-9Xx]', '', isbn)
        if not ((len(s) == 13 and s.startswith(("978", "979")) and _isbn13_valid(s)) or
                (len(s) == 10 and _isbn10_valid(s))):
            isbn = None
    
    # Auto-enrich: có ISBN nhưng thiếu title
    if isbn and not g.get("title"):
        logger.info(f"Auto-enriching ISBN: {isbn}")
        try:
            enriched = await _enrich_core(isbn=isbn, title=None, authorName=None)
            return ExtractResponse(
                isbn=isbn,
                title=enriched.title,
                authorName=enriched.authorName,
                publisher=enriched.publisher,
                publicationYear=enriched.publicationYear,
                numberOfPages=enriched.numberOfPages,
                format=enriched.format
            )
        except Exception as e:
            logger.warning(f"Auto-enrich failed: {e}")
    
    return ExtractResponse(
        isbn=isbn,
        title=g.get("title"),
        authorName=g.get("authorName"),
        publisher=g.get("publisher"),
        publicationYear=g.get("publicationYear"),
        numberOfPages=g.get("numberOfPages"),
        format=g.get("format")
    )

@app.post("/extract-gemini-multi", response_model=ExtractResponse)
async def extract_multi(files: List[UploadFile] = File(...)):
    """Extract from multiple images (front + back) - prioritizes title, keeps ISBN"""
    if not files:
        raise HTTPException(400, "No files")
    
    results = []
    for f in files[:2]:
        try:
            img = await f.read()
            g = await _gemini_extract(img, f.content_type or "image/jpeg")
            results.append(g)
        except Exception as e:
            logger.warning(f"Extract failed {f.filename}: {e}")
    
    if not results:
        raise HTTPException(503, "All extractions failed")
    
    # Merge: ISBN từ bất kỳ, title ưu tiên có giá trị
    merged = {}
    for r in results:
        if not merged.get("isbn") and r.get("isbn"):
            s = re.sub(r'[^0-9Xx]', '', r["isbn"])
            if (len(s) == 13 and s.startswith(("978", "979")) and _isbn13_valid(s)) or \
               (len(s) == 10 and _isbn10_valid(s)):
                merged["isbn"] = r["isbn"]
        
        for key in ["title", "authorName", "publisher", "publicationYear", "numberOfPages", "format"]:
            if not merged.get(key) and r.get(key):
                merged[key] = r[key]
    
    # Auto-enrich nếu có ISBN nhưng thiếu title
    isbn = merged.get("isbn")
    if isbn and not merged.get("title"):
        logger.info(f"Multi auto-enrich: {isbn}")
        try:
            enriched = await _enrich_core(isbn=isbn, title=None, authorName=None)
            return ExtractResponse(
                isbn=isbn,
                title=enriched.title,
                authorName=enriched.authorName,
                publisher=enriched.publisher,
                publicationYear=enriched.publicationYear,
                numberOfPages=enriched.numberOfPages,
                format=enriched.format
            )
        except Exception as e:
            logger.warning(f"Multi enrich failed: {e}")
    
    return ExtractResponse(**merged)

@app.get("/health")
def health():
    return {"ok": True}

@app.post("/enrich", response_model=BookMeta)
async def enrich_post(isbn: Optional[str] = Form(None), title: Optional[str] = Form(None),
                     authorName: Optional[str] = Form(None)):
    return await _enrich_core(isbn, title, authorName)

@app.get("/enrich", response_model=BookMeta)
async def enrich_get(isbn: Optional[str] = None, title: Optional[str] = None, authorName: Optional[str] = None):
    return await _enrich_core(isbn, title, authorName)

# ========== Recommend ==========
def load_user_isbn_map():
    m = {}
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT br.user_id uid, bi.book_isbn isbn
                FROM borrow br JOIN bookitem bi ON br.book_item_id = bi.book_item_id
                WHERE br.status IN ('Borrowed','Returned','Overdue')
                GROUP BY br.user_id, bi.book_isbn
            """)
            for r in cur.fetchall():
                m.setdefault(int(r["uid"]), set()).add(r["isbn"])
    return m

def filter_deleted(isbns):
    if not isbns:
        return []
    ph = ",".join(["%s"] * len(isbns))
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(f"SELECT isbn FROM book WHERE isbn IN ({ph}) AND UPPER(status) <> 'DELETED'", isbns)
            keep = [r["isbn"] for r in cur.fetchall()]
    order = {s: i for i, s in enumerate(isbns)}
    keep.sort(key=lambda s: order.get(s, 10**9))
    return keep

def fetch_book_cards(isbns):
    if not isbns:
        return []
    ph = ",".join(["%s"] * len(isbns))
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(f"""
                SELECT b.isbn, b.title, b.coverImage, b.authorID, a.name author
                FROM book b LEFT JOIN author a ON a.id = b.authorID
                WHERE b.isbn IN ({ph})
            """, isbns)
            rows = cur.fetchall()
    order = {s: i for i, s in enumerate(isbns)}
    rows.sort(key=lambda r: order.get(r["isbn"], 10**9))
    return [{"isbn": r["isbn"], "title": r["title"], "coverImage": r["coverImage"],
             "author": r.get("author"), "authorID": r.get("authorID")} for r in rows]

def _recommend_core(uid, k, n):
    user_items = load_user_isbn_map()
    already = user_items.get(uid, set())
    if not already:
        return {"userId": uid, "items": []}
    rec = recommend_user_cf(user_items, uid, k, n) or []
    rec = list(dict.fromkeys(rec))
    rec = [s for s in rec if s not in already]
    rec = filter_deleted(rec)
    return {"userId": uid, "items": fetch_book_cards(rec)}

@app.get("/recommend/{user_id}")
def recommend_path(user_id: int, k: int = 20, n: int = 10):
    try:
        return _recommend_core(user_id, k, n)
    except Exception as e:
        raise HTTPException(500, str(e))

@app.get("/recommend")
def recommend_query(userId: int = Query(...), k: int = 20, n: int = 10):
    try:
        return _recommend_core(userId, k, n)
    except Exception as e:
        raise HTTPException(500, str(e))

# ========== Search ==========
@app.get("/search/suggestions")
def search_suggestions(q: str = Query(..., min_length=2), limit: int = 10):
    like = f"%{q}%"
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT b.isbn, b.title, b.coverImage, b.format, b.numberOfPages, b.publicationYear,
                       a.name author, GROUP_CONCAT(DISTINCT g.name ORDER BY g.name SEPARATOR ', ') genres
                FROM book b
                LEFT JOIN author a ON a.id = b.authorId
                LEFT JOIN book_genre bg ON bg.book_id = b.id
                LEFT JOIN genre g ON g.id = bg.genre_id
                WHERE (b.title LIKE %s OR a.name LIKE %s OR g.name LIKE %s OR b.format LIKE %s
                       OR CAST(b.numberOfPages AS CHAR) LIKE %s OR CAST(b.publicationYear AS CHAR) LIKE %s)
                  AND (b.status IS NULL OR UPPER(b.status) <> 'DELETED')
                GROUP BY b.isbn LIMIT %s
            """, (like, like, like, like, like, like, limit))
            return [{"isbn": r["isbn"], "title": r["title"], "author": r.get("author"),
                    "genres": r.get("genres"), "format": r.get("format"),
                    "numberOfPages": r.get("numberOfPages"), "publicationYear": r.get("publicationYear"),
                    "coverImage": r.get("coverImage")} for r in cur.fetchall()]

@app.get("/search/advanced")
def search_advanced(q: Optional[str] = None, genre: Optional[str] = None,
                   book_format: Optional[str] = Query(None, alias="format"),
                   min_pages: Optional[int] = None, max_pages: Optional[int] = None,
                   year_from: Optional[int] = None, year_to: Optional[int] = None, limit: int = 20):
    where = ["(b.status IS NULL OR UPPER(b.status) <> 'DELETED')"]
    params = []
    if q:
        like = f"%{q}%"
        where.append("(b.title LIKE %s OR a.name LIKE %s)")
        params += [like, like]
    if genre:
        where.append("g.name LIKE %s")
        params.append(f"%{genre}%")
    if book_format:
        where.append("b.format = %s")
        params.append(book_format)
    if min_pages:
        where.append("b.numberOfPages >= %s")
        params.append(min_pages)
    if max_pages:
        where.append("b.numberOfPages <= %s")
        params.append(max_pages)
    if year_from:
        where.append("b.publicationYear >= %s")
        params.append(year_from)
    if year_to:
        where.append("b.publicationYear <= %s")
        params.append(year_to)
    params.append(limit)
    
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(f"""
                SELECT b.isbn, b.title, b.coverImage, b.format, b.numberOfPages, b.publicationYear,
                       a.name author, GROUP_CONCAT(DISTINCT g.name ORDER BY g.name SEPARATOR ', ') genres
                FROM book b
                LEFT JOIN author a ON a.id = b.authorId
                LEFT JOIN book_genre bg ON bg.book_id = b.id
                LEFT JOIN genre g ON g.id = bg.genre_id
                WHERE {" AND ".join(where)}
                GROUP BY b.isbn ORDER BY b.title LIMIT %s
            """, tuple(params))
            return [{"isbn": r["isbn"], "title": r["title"], "author": r.get("author"),
                    "genres": r.get("genres"), "format": r.get("format"),
                    "numberOfPages": r.get("numberOfPages"), "publicationYear": r.get("publicationYear"),
                    "coverImage": r.get("coverImage")} for r in cur.fetchall()]