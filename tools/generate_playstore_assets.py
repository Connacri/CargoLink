import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)))
SRC_ICON = os.path.join(BASE, "..", "assets", "icons", "icon2.png")
OUT = os.path.join(BASE, "..", "playstore", "assets")
os.makedirs(OUT, exist_ok=True)

INDIGO = (99, 102, 241)
VIOLET = (139, 92, 246)
INDIGO_DEEP = (67, 56, 202)
WHITE = (255, 255, 255)

FONT_DIR = r"C:\Windows\Fonts"
FONT_BOLD = os.path.join(FONT_DIR, "arialbd.ttf")
FONT_REG = os.path.join(FONT_DIR, "arial.ttf")


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.load_default()


def gradient(size, top, bottom, vertical=True):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = y / h if vertical else x / w
            px[x, y] = (
                int(top[0] + (bottom[0] - top[0]) * t),
                int(top[1] + (bottom[1] - top[1]) * t),
                int(top[2] + (bottom[2] - top[2]) * t),
            )
    return img


def rounded(canvas, r):
    mask = Image.new("L", canvas.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, canvas.size[0], canvas.size[1]], radius=r, fill=255)
    out = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    out.paste(canvas, (0, 0), mask)
    return out


def load_icon(target=0):
    icon = Image.open(SRC_ICON).convert("RGBA")
    if target:
        icon.thumbnail((target, target), Image.LANCZOS)
    return icon


def shadow_text(d, xy, text, fnt, fill, anchor=None):
    x, y = xy
    d.text((x + 2, y + 2), text, font=fnt, fill=(0, 0, 0, 160), anchor=anchor)
    d.text((x, y), text, font=fnt, fill=fill, anchor=anchor)


# ---- 1. Play Store icon 512x512 (square, rounded) -------------------------
icon = load_icon(512)
canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
g = gradient((512, 512), INDIGO, INDIGO_DEEP)
g = rounded(g, 110)
canvas.paste(g, (0, 0), g)
icon = icon.resize((360, 360), Image.LANCZOS)
icon_mask = icon.split()[3].point(lambda a: min(a, 255))
canvas.paste(icon, ((512 - 360) // 2, (512 - 360) // 2), icon_mask)
canvas.convert("RGB").save(os.path.join(OUT, "app_icon_512.png"))
print("app_icon_512.png OK")

# ---- 2. Feature graphic 1024x500 ------------------------------------------
W, H = 1024, 500
fg = gradient((W, H), INDIGO, VIOLET)
d = ImageDraw.Draw(fg)
feat_icon = load_icon(330)
fg.paste(feat_icon, (72, (H - 330) // 2), feat_icon)
f_big = font(FONT_BOLD, 84)
f_sub = font(FONT_REG, 40)
d.text((470, 175), "CargoLink", font=f_big, fill=WHITE)
d.text((470, 275), "Votre logistique, simplifiee", font=f_sub, fill=(230, 232, 255, 255))
fg.save(os.path.join(OUT, "feature_graphic_1024x500.png"))
print("feature_graphic_1024x500.png OK")

# ---- 3. Screenshots 1080x1920 (9:16) with device-like frame ---------------
SHOT_W, SHOT_H = 1080, 1920


def phone_frame():
    frame = Image.new("RGBA", (SHOT_W, SHOT_H), (0, 0, 0, 0))
    body = Image.new("RGBA", (SHOT_W, SHOT_H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.rounded_rectangle([60, 60, SHOT_W - 60, SHOT_H - 60], radius=90, fill=(18, 22, 33, 255))
    frame.paste(body, (0, 0), body)
    screen = Image.new("RGBA", (SHOT_W, SHOT_H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(screen)
    sd.rounded_rectangle([88, 88, SHOT_W - 88, SHOT_H - 88], radius=55, fill=(248, 250, 252, 255))
    frame.paste(screen, (0, 0), screen)
    return frame


def app_bar(img, title):
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([88, 88, SHOT_W - 88, 250], radius=0, fill=(99, 102, 241, 255))
    d.rectangle([88, 170, SHOT_W - 88, 250], fill=(99, 102, 241, 255))
    f = font(FONT_BOLD, 48)
    d.text((150, 130), title, font=f, fill=WHITE)


def bottom_card(img, items, y0=1400):
    d = ImageDraw.Draw(img)
    card = Image.new("RGBA", (SHOT_W, SHOT_H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle([150, y0, SHOT_W - 150, 1750], radius=40, fill=(255, 255, 255, 255))
    img.paste(card, (0, 0), card)
    f = font(FONT_BOLD, 40)
    fs = font(FONT_REG, 34)
    y = y0 + 70
    for title, sub in items:
        d.ellipse([190, y + 20, 250, y + 80], fill=(99, 102, 241, 255))
        d.text((300, y + 18), title, font=f, fill=(30, 41, 59, 255))
        d.text((300, y + 78), sub, font=fs, fill=(100, 116, 139, 255))
        y += 130


def status_bar(img):
    d = ImageDraw.Draw(img)
    d.text((130, 118), "9:41", font=font(FONT_REG, 36), fill=(255, 255, 255, 255))


def save_shot(img, name):
    img.convert("RGB").save(os.path.join(OUT, name))
    print(name, "OK")


# Shot 1: Accueil / suivi colis
s = phone_frame()
d = ImageDraw.Draw(s)
hero = gradient((SHOT_W - 176, 520), INDIGO, VIOLET)
hero = rounded(hero, 60)
s.paste(hero, (88, 300), hero)
d.text((170, 350), "Colis en transit", font=font(FONT_BOLD, 44), fill=WHITE)
d.text((170, 430), "SUIVI  •  arrivee prevue: 22/08", font=font(FONT_REG, 34), fill=(230, 232, 255, 255))
d.ellipse((170, 560, 230, 620), fill=WHITE)
status_bar(s)
bottom_card(s, [("Colis #CG48201", "Alger -> Oran  •  en cours"),
                ("Colis #CG48187", "Livraison planifiee demain"),
                ("Colis #CG48140", "En attente au depot")], 1000)
save_shot(s, "screenshot_home_1080x1920.png")

# Shot 2: Carte / suivi en direct
s = phone_frame()
d = ImageDraw.Draw(s)
status_bar(s)
mapc = gradient((SHOT_W - 176, 900), (148, 163, 184), (100, 116, 139))
mapc = rounded(mapc, 60)
s.paste(mapc, (88, 300), mapc)
d = ImageDraw.Draw(s)
marker = load_icon(130)
s.paste(marker, (SHOT_W // 2 - 65, 650), marker)
d.text((SHOT_W // 2 - 140, 900), "Suivi GPS en temps reel", font=font(FONT_BOLD, 44), fill=(30, 41, 59, 255))
bottom_card(s, [("Livraison en cours", "Chauffeur: Mohamed  •  3 km"),
                ("Etape suivante", "Depot central - Alger Centre")], 1250)
save_shot(s, "screenshot_tracking_1080x1920.png")

# Shot 3: Offres / transport
s = phone_frame()
d = ImageDraw.Draw(s)
status_bar(s)
app_bar(s, "Trouver un transport")
cards = [("Offre Express", "1 200 DZD/kg  •  Alger - Paris", INDIGO),
         ("Offre Economique", "850 DZD/kg  •  Alger - Dubai", VIOLET),
         ("Offre Standard", "980 DZD/kg  •  Oran - Lyon", INDIGO)]
y = 330
f = font(FONT_BOLD, 40)
fs = font(FONT_REG, 34)
for title, sub, color in cards:
    card = Image.new("RGBA", (SHOT_W, SHOT_H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle([150, y, SHOT_W - 150, y + 180], radius=36, fill=(255, 255, 255, 255))
    s.paste(card, (0, 0), card)
    d = ImageDraw.Draw(s)
    d.ellipse([200, y + 55, 260, y + 115], fill=color + (255,))
    d.text((310, y + 45), title, font=f, fill=(30, 41, 59, 255))
    d.text((310, y + 105), sub, font=fs, fill=(100, 116, 139, 255))
    y += 230
save_shot(s, "screenshot_offers_1080x1920.png")

# Shot 4: Finance / stats
s = phone_frame()
d = ImageDraw.Draw(s)
status_bar(s)
app_bar(s, "Mes finances")
card = gradient((SHOT_W - 176, 380), INDIGO, INDIGO_DEEP)
card = rounded(card, 50)
s.paste(card, (88, 330), card)
d = ImageDraw.Draw(s)
d.text((170, 380), "Solde disponible", font=font(FONT_REG, 36), fill=(230, 232, 255, 255))
d.text((170, 440), "128 450 DZD", font=font(FONT_BOLD, 64), fill=WHITE)
bars = [(260, INDIGO), (420, VIOLET), (180, (139, 92, 246)), (520, INDIGO), (340, VIOLET)]
x = 170
for h, c in bars:
    d.rounded_rectangle([x, 900 - h, x + 90, 900], radius=14, fill=c + (255,))
    x += 140
d.text((170, 950), "Revenus - 30 derniers jours", font=font(FONT_BOLD, 42), fill=(30, 41, 59, 255))
bottom_card(s, [("Depots collectes", "+45 200 DZD"),
                ("Livraisons effectuees", "+83 250 DZD"),
                ("Commission plateforme", "-4 120 DZD")], 1200)
save_shot(s, "screenshot_finance_1080x1920.png")

# ---- 4. Resume / banner for store text files ------------------------------
summary = """ASSETS PLAY STORE — CargoLink
====================================
app_icon_512.png          -> Icône Play Store (512x512, fond indigo arrondi)
feature_graphic_1024x500  -> Bannière en haut de la fiche (1024x500)
screenshot_home           -> Capture: suivi des colis en transit (1080x1920)
screenshot_tracking       -> Capture: suivi GPS temps réel (1080x1920)
screenshot_offers         -> Capture: recherche de transport (1080x1920)
screenshot_finance        -> Capture: finances & stats (1080x1920)

Note: les captures sont des maquettes générées (textes FR sans accents).
Pour de vraies captures, lancer l'app et prendre des screenshots device.
"""
with open(os.path.join(OUT, "README.txt"), "w", encoding="utf-8") as f:
    f.write(summary)
print("README.txt OK")
print("Terminé. Sortie:", os.path.normpath(OUT))
