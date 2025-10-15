# scrapers.py
import re, math
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from selectolax.parser import HTMLParser

HEADERS = {
    "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                  "AppleWebKit/537.36 (KHTML, like Gecko) "
                  "Chrome/126.0 Safari/537.36",
    "accept-language": "vi,vi-VN;q=0.9,en;q=0.8",
}

def _norm_text(s: str) -> str:
    return re.sub(r"\s+", " ", (s or "").strip())

def _extract_digits(s: str) -> str:
    return re.sub(r"[^\d]", "", s or "")

def _price_to_int(s: str):
    d = _extract_digits(s)
    return int(d) if d else None

class NotFound(Exception): ...
class BadStatus(Exception): ...

@retry(
    reraise=True,
    retry=retry_if_exception_type((httpx.HTTPError, BadStatus)),
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=0.5, min=0.5, max=3),
)
async def _get(client: httpx.AsyncClient, url: str, params=None) -> HTMLParser:
    r = await client.get(url, params=params, headers=HEADERS, timeout=10)
    if r.status_code >= 500:
        raise BadStatus(f"{r.status_code}")
    return HTMLParser(r.text)

# -------------------- TIKI --------------------
async def get_book_from_tiki(isbn: str) -> dict:
    """
    Tìm bằng trang search, lấy kết quả khớp ISBN, sau đó vào trang sản phẩm để lấy meta.
    Trả về dict chuẩn hoá. Ném NotFound nếu không tìm thấy.
    """
    async with httpx.AsyncClient(http2=True, headers=HEADERS) as client:
        # 1) search theo isbn
        search_url = "https://tiki.vn/search"
        doc = await _get(client, search_url, params={"q": isbn})

        # kết quả thường nằm trong data-qa="product-item" hoặc a.product-item, backup bằng CSS chung
        items = doc.css("a.product-item, a[data-view-id='product_list_item']")
        product_url = None
        for a in items:
            href = a.attributes.get("href") or ""
            text = a.text() or ""
            # tiki có thể hiện luôn ISBN trên card; nếu không thì vẫn thử vào link đầu
            if isbn in href or isbn in text:
                product_url = href if href.startswith("http") else "https://tiki.vn" + href
                break
        if not product_url and items:
            href = items[0].attributes.get("href") or ""
            product_url = href if href.startswith("http") else "https://tiki.vn" + href

        if not product_url:
            raise NotFound("No product on Tiki")

        # 2) trang chi tiết
        pd = await _get(client, product_url)

        # title
        title = _norm_text((pd.css_first("h1.title") or pd.css_first("h1")).text() if pd.css_first("h1") else None)

        # author (thường trong block 'Tác giả' hoặc breadcrumb)
        author = None
        for n in pd.css("a[href*='tac-gia'], a.author"):
            t = _norm_text(n.text())
            if t and len(t) <= 80:
                author = t; break

        # publisher (thường trong bảng thông tin)
        publisher = None
        pub_nodes = pd.css("td:contains('Nhà xuất bản'), div:contains('Nhà xuất bản')")
        if pub_nodes:
            # lấy sibling/value
            cell = pub_nodes[0].parent
            if cell:
                sib = cell.css_first("td:nth-child(2), div:nth-child(2)")
                publisher = _norm_text(sib.text()) if sib else None

        # ISBN (nếu có trong bảng)
        isbn_on_page = None
        for label in ["ISBN", "Mã Sản Phẩm", "Mã hàng"]:
            nodes = pd.css(f"td:contains('{label}'), div:contains('{label}')")
            if nodes:
                cell = nodes[0].parent
                if cell:
                    sib = cell.css_first("td:nth-child(2), div:nth-child(2)")
                    val = _norm_text(sib.text()) if sib else None
                    if val and re.search(r"\b97[89]\d{10}\b", val):
                        isbn_on_page = re.search(r"(97[89]\d{10})", val).group(1)
                        break

        # price
        price = None
        price_node = pd.css_first("[data-view-id='pdp_price'] *:matches('₫'), .product-price__current-price, .product-price__current-price-value")
        if price_node:
            price = _price_to_int(price_node.text())

        # image
        img = None
        img_node = pd.css_first("img[alt][srcset], img[alt][src]")
        if img_node:
            img = img_node.attributes.get("src") or img_node.attributes.get("srcset")

        return {
            "source": "tiki",
            "isbn": isbn_on_page or isbn,
            "title": title or None,
            "authorName": author,
            "publisher": publisher,
            "price": price,               # VND
            "coverImage": img,
        }

# -------------------- FAHASA --------------------
async def get_book_from_fahasa(isbn: str) -> dict:
    """
    Tương tự: search -> lấy item -> vào chi tiết -> trích meta.
    """
    async with httpx.AsyncClient(http2=True, headers=HEADERS) as client:
        search_url = "https://www.fahasa.com/catalogsearch/result/"
        doc = await _get(client, search_url, params={"q": isbn})

        items = doc.css("a.product-item-link, a.product-image-photo, li.item a")
        product_url = None
        for a in items:
            href = a.attributes.get("href") or ""
            text = a.text() or ""
            if isbn in href or isbn in text:
                product_url = href
                break
        if not product_url and items:
            product_url = items[0].attributes.get("href")

        if not product_url:
            raise NotFound("No product on Fahasa")

        pd = await _get(client, product_url)

        title = _norm_text((pd.css_first("h1.page-title span") or pd.css_first("h1.page-title")).text() if pd.css_first("h1.page-title") else None)

        # Trong bảng thông tin kỹ thuật
        publisher = author = None
        for row in pd.css("table.data.table.additional-attributes tr"):
            k = _norm_text((row.css_first("th") or row.css_first("td")).text() if row else "")
            v = _norm_text((row.css_first("td:nth-child(2)") or row.css_first("td")).text() if row else "")
            if not k: 
                continue
            if "nhà xuất bản" in k.lower():
                publisher = v
            if "tác giả" in k.lower() or "author" in k.lower():
                author = v
            if "isbn" in k.lower() and re.search(r"(97[89]\d{10})", v):
                isbn = re.search(r"(97[89]\d{10})", v).group(1)

        price = None
        price_node = pd.css_first("span.price")
        if price_node:
            price = _price_to_int(price_node.text())

        img = None
        img_node = pd.css_first("img.fhs-p-img, img.gallery-placeholder__image, img[src]")
        if img_node:
            img = img_node.attributes.get("src")

        return {
            "source": "fahasa",
            "isbn": isbn,
            "title": title or None,
            "authorName": author,
            "publisher": publisher,
            "price": price,
            "coverImage": img,
        }
