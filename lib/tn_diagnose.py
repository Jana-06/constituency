"""
TN Scraper - Diagnostic Tool
=============================
Run this FIRST to inspect what the server actually returns
after clicking one constituency link. Saves the raw HTML so
you can open it in a browser and check the table structure.

Usage:
    python tn_diagnose.py
"""

import re
import requests
from bs4 import BeautifulSoup

BASE_URL = "https://erolls.tn.gov.in/acwithcandidate_tnla2026/AC_List.aspx"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                  "AppleWebKit/537.36 Chrome/124 Safari/537.36",
    "Referer": BASE_URL,
    "Content-Type": "application/x-www-form-urlencoded",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}

session = requests.Session()
session.headers.update(HEADERS)

print("GET AC_List.aspx…")
resp = session.get(BASE_URL, timeout=30)
soup = BeautifulSoup(resp.text, "html.parser")

# Get hidden fields
hidden = {inp["name"]: inp.get("value", "")
          for inp in soup.find_all("input", {"type": "hidden"})
          if inp.get("name")}

print(f"Hidden fields found: {list(hidden.keys())}")

# Try AC 20 = Thousand Lights (ctrl19)
# That's the one showing 18 candidates in the screenshot
event_target = "ctl00$ContentPlaceHolder1$lv_Candidate$ctrl19$ctl00$lnk_Pc_Name"

print(f"\nPOSTing for 'Thousand Lights' (AC 20, ctrl19)…")
post_data = {**hidden, "__EVENTTARGET": event_target, "__EVENTARGUMENT": ""}
resp = session.post(BASE_URL, data=post_data, timeout=30)

print(f"Response status : {resp.status_code}")
print(f"Response size   : {len(resp.text)} bytes")

# Save raw HTML
with open("response_thousand_lights.html", "w", encoding="utf-8") as f:
    f.write(resp.text)
print("Saved → response_thousand_lights.html  (open in browser to inspect)")

# Analyse tables
soup2 = BeautifulSoup(resp.text, "html.parser")
tables = soup2.find_all("table")
print(f"\nTables found: {len(tables)}")
for ti, t in enumerate(tables):
    rows = t.find_all("tr")
    headers = []
    if rows:
        headers = [c.get_text(strip=True) for c in rows[0].find_all(["th","td"])]
    print(f"  Table {ti}: {len(rows)} rows | headers: {headers[:6]}")

# Check if candidate names from screenshot are present
names_to_check = ["EZHILAN", "KALANCHIYAM", "VALARMATHI", "KARTHIKEYAN"]
print("\nSearching for known candidate names in response…")
for name in names_to_check:
    found = name in resp.text.upper()
    print(f"  {name}: {'✅ FOUND' if found else '❌ NOT FOUND'}")

# Look for the constituency heading
import re
match = re.search(r"THOUSAND LIGHTS|ASSEMBLY CONSTITUENCY", resp.text, re.IGNORECASE)
if match:
    start = max(0, match.start() - 50)
    print(f"\nConstituency heading context:\n  …{resp.text[start:match.end()+100]}…")