"""App Store release of KoiKnife (version/build from pubspec.yaml): listing, rating, price, screenshots, submit.
Reuses JellyDazzle's ASC auth (call()). Each step is idempotent-ish and reports its own result."""
import importlib.util, hashlib, os, glob, json, sys, urllib.request
from PIL import Image
spec = importlib.util.spec_from_file_location("asc", "/Users/exeter/dev/m5/assembly/jellydazzle/v3.7.0/tools/asc_release.py")
asc = importlib.util.module_from_spec(spec); spec.loader.exec_module(asc); call = asc.call
APP = "6822839703"
# Version + build come from pubspec.yaml ("version: X.Y.Z+N"), so the script can never attach a
# stale build: it looks up the uploaded build numbered N and submits version X.Y.Z.
PUBSPEC = os.path.join(os.path.dirname(__file__), "..", "pubspec.yaml")
VERSION, BUILD_NO = [l.split(":", 1)[1].strip() for l in open(PUBSPEC) if l.startswith("version:")][0].split("+")
def build_id():
    bs = call("GET", f"/v1/builds?filter[app]={APP}&filter[version]={BUILD_NO}&filter[processingState]=VALID")["data"]
    if not bs: raise SystemExit(f"build {BUILD_NO} not uploaded/processed yet")
    return bs[0]["id"]
SHOTS = os.path.join(os.path.dirname(__file__), "..", "build", "storeshots")

def step(label, f):
    try: r = f(); print("OK  ", label); return r
    except SystemExit as e: print("FAIL", label, "→", e); return None

DESC = """KoiKnife is the Swiss Army Knife of koi knowledge: everything a koi keeper, buyer or admirer needs, in one beautifully illustrated app. Presented with B&M Aquatics of Hamburg, New Jersey, family owned since 2003.

IDENTIFY
• 33 koi varieties, from the Gosanke (Kohaku, Taisho Sanke, Showa) to Asagi, Shusui, Ogon, Kujaku, Chagoi, Ochiba, Goromo, Tancho, Doitsu, Ginrin and butterfly koi
• Large photographs, kanji names, colour swatches and rarity
• "Often confused with" links that teach the real differences
• Search and filter by variety group
• Save favourites to My Koi

PRICES
• Price bands from Pond grade and Hobbyist to Japanese import, Breeder-attributed and Show quality, at every size
• A size calculator: price grows with the square of length
• Why two koi the same size cost wildly different money

HISTORY
• Ten researched chapters on the real story of nishikigoi, from Chinese paddy carp and Niigata's snow country to the 1914 Tokyo exposition, the ¥203 million S Legend and the 2004 earthquake
• Myths busted, facts sourced
• A gallery of woodblock prints by Hokusai, Hiroshige, Kuniyoshi and more

POND CARE & SUPPLIES
• Feeding by water temperature (°F / °C)
• The pond year, season by season
• Water tests explained: ammonia, nitrite, nitrate, pH, KH
• The gear every pond needs, with practical tips
• Pond FAQ: green water, winter, UV, stocking

EXTRAS
• Name That Koi: a photo quiz where the wrong answers are the real lookalikes
• Koi of the Day
• A living koi pond to feed and play with

No account, no ads, no tracking. Everything works offline."""

def main():
    app = call("GET", f"/v1/apps/{APP}")["data"]
    # app-level: content rights (Commons photos are third-party content we have rights to use)
    step("content rights", lambda: call("PATCH", f"/v1/apps/{APP}", {"data": {"type": "apps", "id": APP,
         "attributes": {"contentRightsDeclaration": "USES_THIRD_PARTY_CONTENT"}}}))
    # app info: categories + localization (name, subtitle, privacy URL)
    infos = call("GET", f"/v1/apps/{APP}/appInfos")["data"]
    info = [i for i in infos if i["attributes"].get("appStoreState") != "READY_FOR_SALE"][0]
    step("categories Reference / Education", lambda: call("PATCH", f"/v1/appInfos/{info['id']}", {"data": {"type": "appInfos", "id": info["id"],
         "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "REFERENCE"}},
                           "secondaryCategory": {"data": {"type": "appCategories", "id": "EDUCATION"}}}}}))
    for loc in call("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations")["data"]:
        step(f"name/subtitle/privacy ({loc['attributes']['locale']})", lambda: call("PATCH", f"/v1/appInfoLocalizations/{loc['id']}", {"data": {
             "type": "appInfoLocalizations", "id": loc["id"], "attributes": {"name": "KoiKnife",
             "subtitle": "Koi ID, History, Prices & Care", "privacyPolicyUrl": "https://koiknife.jelia.nyc/privacy/"}}}))
    # age rating: nothing objectionable → 4+
    try:
        ar = call("GET", f"/v1/appInfos/{info['id']}/ageRatingDeclaration")["data"]
        none = {k: "NONE" for k in ["alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated", "medicalOrTreatmentInformation",
                "profanityOrCrudeHumor", "sexualContentGraphicAndNudity", "sexualContentOrNudity", "horrorOrFearThemes",
                "matureOrSuggestiveThemes", "violenceCartoonOrFantasy", "violenceRealistic", "violenceRealisticProlongedGraphicOrSadistic",
                "gunsOrOtherWeapons"]}
        flags = {k: False for k in ["gambling", "unrestrictedWebAccess", "lootBox", "messagingAndChat", "parentalControls",
                 "ageAssurance", "userGeneratedContent", "advertising", "healthOrWellnessTopics"]}
        attrs = {**none, **flags}
        # drop any key this API version doesn't know, retrying until accepted
        for _ in range(12):
            try:
                call("PATCH", f"/v1/ageRatingDeclarations/{ar['id']}", {"data": {"type": "ageRatingDeclarations", "id": ar["id"], "attributes": attrs}})
                print("OK   age rating (all none → 4+)"); break
            except SystemExit as e:
                bad = [k for k in attrs if k in str(e)]
                if not bad: print("FAIL age rating →", e); break
                for k in bad: attrs.pop(k)
    except SystemExit as e: print("FAIL age rating →", e)
    # version: copyright, release on approval, listing text, review contact
    ver = [v for v in call("GET", f"/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS")["data"]][0]
    vid = ver["id"]
    step("version copyright + auto-release", lambda: call("PATCH", f"/v1/appStoreVersions/{vid}", {"data": {"type": "appStoreVersions", "id": vid,
         "attributes": {"copyright": "2026 LIBCSYSTEMS LLC", "releaseType": "AFTER_APPROVAL"}}}))
    vloc = call("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")["data"][0]
    step("description/keywords/URLs", lambda: call("PATCH", f"/v1/appStoreVersionLocalizations/{vloc['id']}", {"data": {
         "type": "appStoreVersionLocalizations", "id": vloc["id"], "attributes": {"description": DESC,
         "keywords": "koi,nishikigoi,pond,kohaku,showa,sanke,goldfish,carp,fish,aquarium,water garden,identify",
         "promotionalText": "Identify 33 koi varieties, see what they cost from pond grade to show koi, and read the real history of the brocade carp.",
         "supportUrl": "https://koiknife.jelia.nyc/support/", "marketingUrl": "https://koiknife.jelia.nyc/"}}}))
    rd_body = {"contactFirstName": "John", "contactLastName": "Elia", "contactPhone": "+1 631 599 6611",
               "contactEmail": "koiknife@jelia.nyc", "demoAccountRequired": False,
               "notes": "No login or account. Fully offline koi reference; all content bundled. Variety photos are freely licensed from Wikimedia Commons (credits: B&M screen → Photo credits). Presented with B&M Aquatics, whose own site the text and store photos come from."}
    try: rd = call("GET", f"/v1/appStoreVersions/{vid}/appStoreReviewDetail")["data"]
    except SystemExit: rd = None
    if rd:
        step("review contact", lambda: call("PATCH", f"/v1/appStoreReviewDetails/{rd['id']}", {"data": {"type": "appStoreReviewDetails", "id": rd["id"], "attributes": rd_body}}))
    else:
        step("review contact", lambda: call("POST", "/v1/appStoreReviewDetails", {"data": {"type": "appStoreReviewDetails", "attributes": rd_body,
             "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}}))
    # price: free, USA base
    try:
        pts = call("GET", f"/v1/apps/{APP}/appPricePoints?filter[territory]=USA&limit=200")["data"]
        free = [p for p in pts if float(p["attributes"]["customerPrice"]) == 0][0]
        step("price: Free", lambda: call("POST", "/v1/appPriceSchedules", {"data": {"type": "appPriceSchedules",
             "relationships": {"app": {"data": {"type": "apps", "id": APP}}, "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                               "manualPrices": {"data": [{"type": "appPrices", "id": "${free}"}]}}},
             "included": [{"type": "appPrices", "id": "${free}", "attributes": {"startDate": None},
                           "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": free["id"]}}}}]}))
    except SystemExit as e: print("FAIL price →", e)
    # availability: every territory, plus future ones
    try:
        terrs = [t["id"] for t in call("GET", "/v1/territories?limit=200")["data"]]
        step(f"availability ({len(terrs)} territories)", lambda: call("POST", "/v2/appAvailabilities", {"data": {"type": "appAvailabilities",
             "attributes": {"availableInNewTerritories": True},
             "relationships": {"app": {"data": {"type": "apps", "id": APP}},
                               "territoryAvailabilities": {"data": [{"type": "territoryAvailabilities", "id": f"${{{t}}}"} for t in terrs]}}},
             "included": [{"type": "territoryAvailabilities", "id": f"${{{t}}}", "attributes": {"available": True},
                           "relationships": {"territory": {"data": {"type": "territories", "id": t}}}} for t in terrs]}))
    except SystemExit as e: print("FAIL availability →", e)
    # screenshots
    for prefix, dtype in (("iphone", "APP_IPHONE_67"), ("ipad", "APP_IPAD_PRO_3GEN_129")):
        sets = call("GET", f"/v1/appStoreVersionLocalizations/{vloc['id']}/appScreenshotSets")["data"]
        sset = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == dtype), None)
        if not sset:
            sset = call("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets", "attributes": {"screenshotDisplayType": dtype},
                   "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": vloc["id"]}}}}})["data"]
        have = {s["attributes"]["fileName"] for s in call("GET", f"/v1/appScreenshotSets/{sset['id']}/appScreenshots")["data"]}
        n = 0
        for f in sorted(glob.glob(f"{SHOTS}/{prefix}_*.png")):
            name = os.path.basename(f)
            if name in have: continue
            flat = f"/tmp/koiknife_{name}"; Image.open(f).convert("RGB").save(flat)  # no alpha channel
            data = open(flat, "rb").read()
            r = call("POST", "/v1/appScreenshots", {"data": {"type": "appScreenshots", "attributes": {"fileName": name, "fileSize": len(data)},
                     "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": sset["id"]}}}}})["data"]
            for op in r["attributes"]["uploadOperations"]:
                req = urllib.request.Request(op["url"], data=data[op["offset"]:op["offset"] + op["length"]], method=op["method"])
                for h in op["requestHeaders"]: req.add_header(h["name"], h["value"])
                urllib.request.urlopen(req).read()
            call("PATCH", f"/v1/appScreenshots/{r['id']}", {"data": {"type": "appScreenshots", "id": r["id"],
                 "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
            n += 1
        print(f"OK   screenshots {dtype}: {n} uploaded, {len(have)} already there")
    step(f"attach build {BUILD_NO}", lambda: call("PATCH", f"/v1/appStoreVersions/{vid}/relationships/build", {"data": {"type": "builds", "id": build_id()}}))
    if "--submit" in sys.argv:
        asc.APP_ID = APP
        step("SUBMIT for App Review", lambda: asc.submit("IOS", VERSION))

main()
