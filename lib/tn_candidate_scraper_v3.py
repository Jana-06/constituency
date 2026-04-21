"""
TN Legislative Assembly 2026 - Candidate Details Scraper v3
=============================================================
Fix: Alternating 0-candidate issue caused by stale ViewState.

Root cause: After a postback, ASP.NET returns a NEW ViewState in the
response. We must extract it from the RESPONSE (not re-use the previous
one). The v2 script did update soup after each post, but if the response
contained a partial/UpdatePanel response, the ViewState parsing failed.

This version:
  1. After each POST, explicitly extracts ViewState from the response
  2. If ViewState is missing/empty in response, does a fresh GET to reset
  3. Adds retry logic for 0-candidate results
  4. Saves all 0-candidate debug HTML for inspection

Usage:
    pip install requests beautifulsoup4
    python tn_candidate_scraper_v3.py
"""

import re, csv, json, time, os
import requests
from bs4 import BeautifulSoup

BASE_URL = "https://erolls.tn.gov.in/acwithcandidate_tnla2026/AC_List.aspx"
HEADERS  = {
    "User-Agent":    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                     "AppleWebKit/537.36 (KHTML, like Gecko) "
                     "Chrome/124.0.0.0 Safari/537.36",
    "Referer":       BASE_URL,
    "Content-Type":  "application/x-www-form-urlencoded",
    "Accept":        "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Cache-Control": "no-cache",
}
DELAY       = 1.2   # seconds between requests
MAX_RETRIES = 3     # retries for 0-candidate results


# ── helpers ───────────────────────────────────────────────────────────────────

def fresh_soup(session):
    """Do a clean GET and return (soup, hidden_fields)."""
    resp = session.get(BASE_URL, timeout=30)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, "html.parser")
    return soup, extract_hidden(soup)


def extract_hidden(soup):
    """Extract all hidden form fields from soup."""
    fields = {}
    for inp in soup.find_all("input", {"type": "hidden"}):
        name = inp.get("name", "")
        val  = inp.get("value", "")
        if name:
            fields[name] = val
    return fields


def do_postback(session, hidden, event_target):
    """POST the postback and return (response_soup, new_hidden_fields)."""
    post_data = {
        **hidden,
        "__EVENTTARGET":   event_target,
        "__EVENTARGUMENT": "",
    }
    resp = session.post(BASE_URL, data=post_data, timeout=30)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, "html.parser")
    new_hidden = extract_hidden(soup)
    return soup, new_hidden, resp.text


def parse_candidates(soup, constituency_name, ac_number):
    candidates = []

    for table in soup.find_all("table"):
        rows = table.find_all("tr")
        if len(rows) < 2:
            continue

        # Find header row
        header_row = None
        header_idx = 0
        for idx, row in enumerate(rows[:5]):
            cells_text = [c.get_text(strip=True).lower()
                          for c in row.find_all(["th", "td"])]
            joined = " ".join(cells_text)
            if ("name" in joined or "candidate" in joined) and \
               ("party" in joined or "symbol" in joined or "affiliation" in joined):
                header_row = row
                header_idx = idx
                break

        if header_row is None:
            continue

        # Map columns
        headers = [c.get_text(strip=True).lower()
                   for c in header_row.find_all(["th", "td"])]
        col = {}
        for i, h in enumerate(headers):
            if re.search(r'sl\.?\s*no|^no$', h):
                col.setdefault("sl_no", i)
            if re.search(r'\bname\b|\bcandidate\b', h):
                col.setdefault("name", i)
            if re.search(r'\bparty\b|\baffiliation\b', h):
                col.setdefault("party", i)
            if re.search(r'\bsymbol\b', h):
                col.setdefault("symbol", i)
            if re.search(r'\bfather\b|\bhusband\b', h):
                col["father"] = i
            if re.search(r'\bage\b', h):
                col["age"] = i
            if re.search(r'\bsex\b|\bgender\b', h):
                col["sex"] = i
            if re.search(r'\baddress\b', h):
                col["address"] = i
            if re.search(r'\bcategory\b|\bcaste\b', h):
                col["category"] = i

        if "name" not in col:
            continue

        def cell_val(cells, key):
            idx = col.get(key)
            if idx is not None and idx < len(cells):
                return cells[idx].get_text(separator=" ", strip=True)
            return ""

        def get_img_url(cells):
            idx = col.get("symbol")
            if idx is not None and idx < len(cells):
                img = cells[idx].find("img")
                if img:
                    src = img.get("src", "").strip()
                    if src and not src.startswith("http"):
                        src = ("https://erolls.tn.gov.in"
                               "/acwithcandidate_tnla2026/" + src.lstrip("/"))
                    return src
            return ""

        for row in rows[header_idx + 1:]:
            cells = row.find_all(["td", "th"])
            if not cells:
                continue
            name = cell_val(cells, "name")
            if not name or name.lower() in ("name", "candidate name", "candidate"):
                continue
            if not "".join(c.get_text(strip=True) for c in cells):
                continue

            candidates.append({
                "ac_number":        ac_number,
                "constituency":     constituency_name,
                "sl_no":            cell_val(cells, "sl_no"),
                "candidate_name":   name,
                "party":            cell_val(cells, "party"),
                "symbol":           cell_val(cells, "symbol"),
                "symbol_image_url": get_img_url(cells),
                "father_husband":   cell_val(cells, "father"),
                "age":              cell_val(cells, "age"),
                "sex":              cell_val(cells, "sex"),
                "address":          cell_val(cells, "address"),
                "category":         cell_val(cells, "category"),
            })

        if candidates:
            return candidates

    return candidates


# ── main ──────────────────────────────────────────────────────────────────────

def scrape_all():
    session = requests.Session()
    session.headers.update(HEADERS)

    os.makedirs("debug_html", exist_ok=True)

    print("Loading constituency list…")
    soup, hidden = fresh_soup(session)

    constituencies = []
    for row in soup.find_all("tr"):
        cells = row.find_all("td")
        if len(cells) < 2:
            continue
        link = cells[1].find("a")
        if not link:
            continue
        href = link.get("href", "")
        match = re.search(r"ctrl(\d+)", href)
        if not match:
            continue
        ctrl_idx = int(match.group(1))
        name = link.get_text(strip=True)
        event_target = (
            f"ctl00$ContentPlaceHolder1$lv_Candidate"
            f"$ctrl{ctrl_idx}$ctl00$lnk_Pc_Name"
        )
        ac_number = cells[0].get_text(strip=True)
        constituencies.append({
            "ac_number":    ac_number,
            "name":         name,
            "event_target": event_target,
        })

    total = len(constituencies)
    print(f"Found {total} constituencies.\n")

    all_candidates = []
    zero_acs       = []
    errors         = []

    for i, ac in enumerate(constituencies, 1):
        label = f"[{i:3}/{total}] {ac['name']} (AC {ac['ac_number']})"
        print(f"{label}… ", end="", flush=True)

        candidates = []
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                resp_soup, new_hidden, raw_html = do_postback(
                    session, hidden, ac["event_target"]
                )

                # ── KEY FIX ──────────────────────────────────────────
                # Always update hidden from the response.
                # If __VIEWSTATE is empty/missing, do a fresh GET to reset.
                vs = new_hidden.get("__VIEWSTATE", "")
                if not vs:
                    print(f"(ViewState empty on attempt {attempt}, resetting) ", end="", flush=True)
                    soup, hidden = fresh_soup(session)
                    time.sleep(DELAY)
                    continue
                hidden = new_hidden
                # ─────────────────────────────────────────────────────

                candidates = parse_candidates(
                    resp_soup, ac["name"], ac["ac_number"]
                )

                if candidates:
                    break  # success

                # 0 candidates — might be stale ViewState; reset and retry
                if attempt < MAX_RETRIES:
                    print(f"(0 results, attempt {attempt}, resetting ViewState) ", end="", flush=True)
                    # Save debug
                    debug_path = f"debug_html/ac_{ac['ac_number']}_{ac['name'].replace(' ','_')}.html"
                    with open(debug_path, "w", encoding="utf-8") as f:
                        f.write(raw_html)
                    # Fresh GET to reset state
                    soup, hidden = fresh_soup(session)
                    time.sleep(DELAY)

            except Exception as e:
                print(f"(error attempt {attempt}: {e}) ", end="", flush=True)
                try:
                    soup, hidden = fresh_soup(session)
                except Exception:
                    pass
                time.sleep(DELAY)

        if candidates:
            all_candidates.extend(candidates)
            print(f"{len(candidates)} candidates ✓")
        else:
            print(f"0 candidates ✗  (saved to debug_html/)")
            zero_acs.append(ac["name"])
            debug_path = f"debug_html/ac_{ac['ac_number']}_{ac['name'].replace(' ','_')}.html"
            try:
                with open(debug_path, "w", encoding="utf-8") as f:
                    f.write(raw_html)
            except Exception:
                pass

        time.sleep(DELAY)

    # Summary
    print(f"\n{'─'*60}")
    print(f"Total candidates : {len(all_candidates)}")
    print(f"ACs with 0 found : {len(zero_acs)}")
    if zero_acs:
        for z in zero_acs:
            print(f"  • {z}")
    if errors:
        print(f"Errors           : {len(errors)}")
    print(f"{'─'*60}\n")

    return all_candidates, errors


def save_json(data, path="tn_candidates.json"):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"✅ JSON → {path}  ({len(data)} records)")


def save_csv(data, path="tn_candidates.csv"):
    if not data:
        print("No data to save.")
        return
    with open(path, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=list(data[0].keys()))
        writer.writeheader()
        writer.writerows(data)
    print(f"✅ CSV  → {path}  ({len(data)} records)")


if __name__ == "__main__":
    candidates, errors = scrape_all()
    save_json(candidates)
    save_csv(candidates)
    print("Done!")
