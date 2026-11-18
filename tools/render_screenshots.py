#!/usr/bin/env python3
"""Render Brainrot Boulevard screenshots headlessly.

Roblox Studio has no Linux build, so no Studio capture is possible on this
machine. These frames are drawn from the SAME layout data as the place file
(default.project.json + Config.luau): the same plot positions and colors,
the same conveyor, the same 27 brainrots with their names, rarities and
$/s, and the same HUD the client builds. After the place is published from
Studio, replace these with real Studio captures in a new recording.
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), "screenshots")

W, H = 1280, 720
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

def font(sz):
    return ImageFont.truetype(FONT, sz)

def font_reg(sz):
    return ImageFont.truetype(FONT_REG, sz)

# Oblique projection: world (x, z) ground plane, y up.
SCALE = 4.6
CX, CY = 640, 400
def proj(x, y, z):
    sx = CX + (x - z) * 0.866 * SCALE
    sy = CY + (x + z) * 0.5 * SCALE * 0.55 - y * SCALE
    return (sx, sy)

def poly(draw, pts, fill, outline=None):
    draw.polygon(pts, fill=fill, outline=outline)

def ground_rect(draw, x0, z0, x1, z1, y, fill):
    pts = [proj(x0, y, z0), proj(x1, y, z0), proj(x1, y, z1), proj(x0, y, z1)]
    poly(draw, pts, fill)

PLOT_COLORS = [
    (255, 107, 107), (255, 195, 0), (88, 214, 141), (93, 173, 226),
    (175, 122, 197), (244, 114, 182), (72, 201, 176), (245, 176, 65),
]
PLOT_POS = [(-60, -58), (-20, -58), (20, -58), (60, -58),
            (-60, 58), (-20, 58), (20, 58), (60, 58)]
PED_OFF = [(-7, -4), (0, -4), (7, -4), (-7, 4), (0, 4), (7, 4)]

BRAINROTS = [
    ("Toaster Tim", "COMMON", 4, (200, 120, 60)),
    ("Pickle Pete", "COMMON", 6, (120, 200, 80)),
    ("Sock Goblin", "COMMON", 9, (140, 140, 200)),
    ("Chairman Meow", "RARE", 15, (255, 170, 60)),
    ("DJ Llama Drama", "RARE", 22, (220, 120, 220)),
    ("Sir Barksalot", "RARE", 30, (160, 110, 60)),
    ("Professor Nugget", "EPIC", 50, (255, 220, 130)),
    ("Madame Zucchini", "EPIC", 75, (90, 200, 90)),
    ("Count Crumb", "EPIC", 110, (120, 80, 40)),
    ("Queen Blobfish", "LEGENDARY", 180, (255, 150, 180)),
    ("Lord Spaghetti", "LEGENDARY", 260, (255, 230, 150)),
    ("The Grand Noodle", "LEGENDARY", 380, (240, 200, 90)),
    ("Elon Muskrat", "MYTHIC", 600, (100, 160, 255)),
    ("Shrek's Cousin Greg", "MYTHIC", 900, (90, 190, 90)),
    ("Baby Gronk 2.0", "MYTHIC", 1400, (255, 120, 120)),
    ("Skibidi Overlord", "SECRET", 2500, (60, 220, 200)),
    ("Ohio Final Boss", "SECRET", 5000, (200, 60, 220)),
    # v2 cast: 10 more characters, 17 -> 27, with a Transcendent tier.
    ("Waffle Wally", "COMMON", 7, (220, 170, 90)),
    ("Banana Barry", "COMMON", 11, (255, 235, 80)),
    ("Milkman Mike", "COMMON", 13, (240, 240, 240)),
    ("Disco Dave", "RARE", 18, (255, 120, 200)),
    ("Grandma Glitch", "RARE", 26, (180, 140, 255)),
    ("Sir Reginald Frog", "EPIC", 90, (80, 200, 140)),
    ("Queen Queso", "LEGENDARY", 320, (255, 200, 40)),
    ("Doctor Doomscroll", "MYTHIC", 1100, (140, 80, 220)),
    ("The Tax Man", "SECRET", 3500, (60, 60, 60)),
    ("CEO of Ohio", "TRANSCENDENT", 9000, (255, 215, 0)),
]
RARITY_COLORS = {"COMMON": (200, 200, 200), "RARE": (93, 173, 226),
                 "EPIC": (175, 122, 197), "LEGENDARY": (255, 195, 0),
                 "MYTHIC": (255, 87, 51), "SECRET": (0, 255, 200),
                 "TRANSCENDENT": (255, 215, 0)}

def money(n):
    if n >= 1_000_000:
        return f"${n/1_000_000:.2f}M"
    if n >= 10_000:
        return f"${n/1000:.1f}K"
    return f"${n:,}"

def draw_brainrot(draw, x, z, name, rarity, rate, color, scale=1.0, label=True):
    px, py = proj(x, 0, z)
    bw, bh = 30 * scale, 26 * scale
    # body
    draw.rounded_rectangle([px - bw / 2, py - bh - 8 * scale, px + bw / 2, py - 8 * scale],
                           radius=5, fill=color, outline=(20, 20, 20), width=2)
    # head
    hw, hh = 22 * scale, 18 * scale
    draw.rounded_rectangle([px - hw / 2, py - bh - hh - 8 * scale, px + hw / 2, py - bh - 8 * scale],
                           radius=4, fill=color, outline=(20, 20, 20), width=2)
    # eyes
    draw.ellipse([px - 8 * scale, py - bh - hh + 3 * scale, px - 2 * scale, py - bh - hh + 11 * scale], fill=(20, 20, 20))
    draw.ellipse([px + 2 * scale, py - bh - hh + 3 * scale, px + 8 * scale, py - bh - hh + 11 * scale], fill=(20, 20, 20))
    # feet
    draw.rectangle([px - 12 * scale, py - 8 * scale, px - 2 * scale, py - 2 * scale], fill=(40, 40, 40))
    draw.rectangle([px + 2 * scale, py - 8 * scale, px + 12 * scale, py - 2 * scale], fill=(40, 40, 40))
    if label:
        draw.text((px, py - bh - hh - 34 * scale), name, font=font(int(15 * scale)),
                  fill=(255, 255, 255), anchor="mm", stroke_width=3, stroke_fill=(0, 0, 0))
        draw.text((px, py - bh - hh - 16 * scale), f"${rate:,}/s", font=font(int(14 * scale)),
                  fill=(120, 255, 140), anchor="mm", stroke_width=3, stroke_fill=(0, 0, 0))
        draw.text((px, py - bh - hh - 48 * scale), rarity, font=font(int(12 * scale)),
                  fill=RARITY_COLORS[rarity], anchor="mm", stroke_width=3, stroke_fill=(0, 0, 0))

def draw_player(draw, x, z, name="YOU", carrying=None):
    px, py = proj(x, 0, z)
    # classic blocky avatar: yellow head/arms, blue torso, green legs
    draw.rounded_rectangle([px - 11, py - 62, px + 11, py - 40], radius=4, fill=(245, 205, 48), outline=(20, 20, 20), width=2)
    draw.rounded_rectangle([px - 16, py - 40, px + 16, py - 14], radius=4, fill=(13, 105, 172), outline=(20, 20, 20), width=2)
    draw.rectangle([px - 15, py - 14, px - 2, py], fill=(75, 151, 75), outline=(20, 20, 20), width=2)
    draw.rectangle([px + 2, py - 14, px + 15, py], fill=(75, 151, 75), outline=(20, 20, 20), width=2)
    draw.rectangle([px - 24, py - 40, px - 16, py - 18], fill=(245, 205, 48), outline=(20, 20, 20), width=2)
    draw.rectangle([px + 16, py - 40, px + 24, py - 18], fill=(245, 205, 48), outline=(20, 20, 20), width=2)
    draw.text((px, py - 78), name, font=font(15), fill=(255, 255, 255), anchor="mm",
              stroke_width=3, stroke_fill=(0, 0, 0))
    if carrying:
        draw_brainrot(draw, x + 3, z - 4, *carrying, scale=0.9, label=False)

def draw_world(draw, belt_brainrots, plot_brainrots, wave_x=None):
    # sky + grass
    draw.rectangle([0, 0, W, H], fill=(135, 206, 235))
    # sun
    draw.ellipse([1080, 40, 1160, 120], fill=(255, 240, 150), outline=(255, 215, 0), width=3)
    # grass baseplate
    ground_rect(draw, -256, -256, 256, 256, 0, (90, 165, 90))
    # plaza
    ground_rect(draw, -95, -70, 95, 70, 0.4, (235, 218, 173))
    # conveyor belt + rails
    ground_rect(draw, -65, -29, 65, -21, 0.6, (38, 38, 46))
    ground_rect(draw, -65, -30.5, 65, -29, 1.2, (230, 190, 25))
    ground_rect(draw, -65, -21, 65, -19.5, 1.2, (230, 190, 25))
    # fountain
    ground_rect(draw, -7, 3, 7, 17, 1.0, (153, 153, 166))
    ground_rect(draw, -6, 4, 6, 16, 1.6, (51, 153, 255))
    # spawn pad
    ground_rect(draw, -11, 34, 11, 56, 0.5, (140, 217, 242))
    # plots + pedestals
    for i, (px, pz) in enumerate(PLOT_POS):
        ground_rect(draw, px - 12, pz - 9, px + 12, pz + 9, 0.5, PLOT_COLORS[i])
        for ox, oz in PED_OFF:
            ground_rect(draw, px + ox - 2, pz + oz - 2, px + ox + 2, pz + oz + 2, 1.0, PLOT_COLORS[i])
    # trees
    for (tx, tz) in [(-85, -70), (-45, -70), (45, -70), (85, -70), (-85, 70), (-45, 70), (45, 70), (85, 70)]:
        bx, by = proj(tx, 0, tz)
        draw.rectangle([bx - 3, by - 26, bx + 3, by], fill=(120, 72, 20))
        draw.ellipse([bx - 16, by - 56, bx + 16, by - 20], fill=(60, 180, 80), outline=(30, 120, 40), width=2)
    # sign at west gate
    sx, sy = proj(-66, 0, -25)
    draw.rectangle([sx - 3, sy - 90, sx + 3, sy], fill=(90, 60, 30))
    draw.rounded_rectangle([sx - 60, sy - 150, sx + 60, sy - 95], radius=8, fill=(255, 195, 0), outline=(40, 40, 40), width=3)
    draw.text((sx, sy - 122), "BRAINROT\nBOULEVARD", font=font(17), fill=(40, 40, 40), anchor="mm", align="center")
    # belt brainrots (sorted far to near)
    for (name, rarity, rate, color, bx, bz) in sorted(belt_brainrots, key=lambda b: b[4] + b[5]):
        draw_brainrot(draw, bx, bz, name, rarity, rate, color, scale=0.85)
    # plot brainrots
    for (name, rarity, rate, color, bx, bz) in sorted(plot_brainrots, key=lambda b: b[4] + b[5]):
        draw_brainrot(draw, bx, bz, name, rarity, rate, color, scale=0.85)
    # tsunami wave: a tall wall with foam crests on its top edge
    if wave_x is not None:
        wx0, wy = proj(wave_x, 0, -95)
        wx1, _ = proj(wave_x, 0, 95)
        top_y = wy - 140
        draw.polygon([(wx0, wy), (wx1, wy), (wx1, top_y), (wx0, top_y)], fill=(40, 140, 255))
        draw.polygon([(wx0, wy), (wx1, wy), (wx1, top_y), (wx0, top_y)], outline=(255, 255, 255))
        for k in range(6):
            fx = wx0 + (wx1 - wx0) * (k + 0.5) / 6
            draw.ellipse([fx - 16, top_y + 2, fx + 16, top_y + 26], fill=(255, 255, 255))

def chip(draw, x, y, w, text, color=(255, 255, 255), size=24):
    draw.rounded_rectangle([x, y, x + w, y + 44], radius=10, fill=(25, 25, 35, 220))
    draw.text((x + w / 2, y + 22), text, font=font(size), fill=color, anchor="mm")

def top_bar(draw, cash, income, count, rebirths, event=None):
    chips = [(190, money(cash), (120, 255, 140), 26),
             (170, f"${income:,}/s", (255, 230, 120), 26),
             (150, f"{count} brainrots", (255, 255, 255), 22),
             (165, f"Rebirth x{rebirths}", (255, 180, 255), 20)]
    if event:
        chips.append((200, event, (255, 215, 0), 20))
    total = sum(w for w, _, _, _ in chips) + 8 * (len(chips) - 1)
    x = (W - total) / 2
    for w, text, color, size in chips:
        chip(draw, x, 12, w, text, color, size)
        x += w + 8
    draw.text((W / 2, 92), "BRAINROT BOULEVARD", font=font(34), fill=(255, 195, 0), anchor="mm",
              stroke_width=4, stroke_fill=(0, 0, 0))
    # v2: personal stats line under the title (bought / steals / best $/s).
    draw.text((W / 2, 122), "Bought 7  ·  Steals 2  ·  Slaps 1  ·  Best $1,240/s", font=font(18),
              fill=(200, 220, 255), anchor="mm", stroke_width=3, stroke_fill=(0, 0, 0))

def prompt_bar(draw, text):
    draw.rounded_rectangle([320, 648, 960, 696], radius=10, fill=(25, 25, 35, 220))
    draw.text((640, 672), text, font=font(22), fill=(255, 255, 255), anchor="mm")

def hint(draw):
    draw.text((16, 702), "WASD move  ·  E interact  ·  Q shop",
              font=font_reg(14), fill=(255, 255, 255), anchor="lb", stroke_width=3, stroke_fill=(0, 0, 0))

def toast(draw, text):
    draw.text((640, 125), text, font=font(24), fill=(255, 255, 255), anchor="mm",
              stroke_width=4, stroke_fill=(0, 0, 0))

def shop_panel(draw, cash):
    draw.rounded_rectangle([964, 130, 1264, 530], radius=12, fill=(25, 25, 35, 235))
    draw.text((1114, 152), "SHOP  (Q to close)", font=font(22), fill=(255, 195, 0), anchor="mm")
    items = [("Speed Coil", "$1,000", "+6 walk speed, forever"),
             ("Base Lock", "$2,000", "No stealing for 60s"),
             ("Slime Trap", "$750", "Slows thieves 5s"),
             ("Freeze Trap", "$1,500", "Freezes thieves 4s"),
             ("Lucky Egg", "$5,000", "Hatches Epic or better")]
    y = 180
    for name, cost, desc in items:
        draw.rounded_rectangle([976, y, 1252, y + 56], radius=8, fill=(60, 90, 200))
        draw.text((1114, y + 16), f"{name}  ·  {cost}", font=font(17), fill=(255, 255, 255), anchor="mm")
        draw.text((1114, y + 40), desc, font=font_reg(15), fill=(220, 220, 220), anchor="mm")
        y += 66

def leaderboard_panel(draw, rows):
    draw.rounded_rectangle([16, 476, 316, 676], radius=12, fill=(25, 25, 35, 235))
    draw.text((166, 498), "TOP EARNERS", font=font(22), fill=(255, 215, 0), anchor="mm")
    y = 526
    for i, (name, earned, best) in enumerate(rows, 1):
        draw.text((28, y), f"{i}. {name}  ·  {money(earned)}  ·  ${best:,}/s", font=font(16),
                  fill=(255, 255, 255), anchor="lm")
        y += 28

def collection_panel(draw, owned):
    draw.rounded_rectangle([16, 130, 316, 460], radius=12, fill=(25, 25, 35, 235))
    draw.text((166, 152), "MY BRAINROTS", font=font(22), fill=(120, 255, 140), anchor="mm")
    y = 182
    for name, rarity, rate in owned:
        draw.text((28, y), f"{name}  ·  {rarity}  ·  ${rate:,}/s", font=font(16),
                  fill=(255, 255, 255), anchor="lm")
        y += 28

def banner(draw, text):
    draw.text((640, 250), text, font=font(44), fill=(255, 215, 0), anchor="mm",
              stroke_width=6, stroke_fill=(0, 0, 0))

def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    img.save(path, "JPEG", quality=82)
    print(name, os.path.getsize(path), "bytes")

# --- 1. Thumbnail / cover: the whole boulevard, conveyor full of brainrots.
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img, "RGBA")
belt = []
for i, (name, rarity, rate, color) in enumerate(BRAINROTS[:6]):
    belt.append((name, rarity, rate, color, -55 + i * 22, -25))
plots = []
plots.append(("Queen Blobfish", "LEGENDARY", 180, (255, 150, 180), -60 + 7, -58 + 4))
plots.append(("Elon Muskrat", "MYTHIC", 600, (100, 160, 255), 20 + 0, -58 - 4))
plots.append(("CEO of Ohio", "TRANSCENDENT", 9000, (255, 215, 0), 60 - 7, -58 + 4))
draw_world(d, belt, plots)
draw_player(d, -8, 30, "YOU")
top_bar(d, 12840, 342, 7, 1)
prompt_bar(d, "E — Buy Golden DJ Llama Drama for $1,320  ($44/s)")
hint(d)
save(img, "1-thumbnail.jpg")

# --- 2. Play: carrying a steal home, shop open, collection list.
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img, "RGBA")
belt2 = [("Toaster Tim", "COMMON", 4, (200, 120, 60), -40, -25),
         ("Chairman Meow", "RARE", 15, (255, 170, 60), -10, -25),
         ("Professor Nugget", "EPIC", 50, (255, 220, 130), 20, -25),
         ("Lord Spaghetti", "LEGENDARY", 260, (255, 230, 150), 50, -25)]
plots2 = [("Queen Blobfish", "LEGENDARY", 180, (255, 150, 180), -60 - 7, 58 - 4),
          ("Madame Zucchini", "EPIC", 75, (90, 200, 90), -60 + 0, 58 - 4),
          ("Count Crumb", "EPIC", 110, (120, 80, 40), -60 + 7, 58 - 4),
          ("DJ Llama Drama", "RARE", 22, (220, 120, 220), -20 - 7, 58 + 4)]
draw_world(d, belt2, plots2)
draw_player(d, -30, 20, "YOU", carrying=("Lord Spaghetti", "LEGENDARY", 260, (255, 230, 150)))
draw_player(d, 10, 55, "rival-99")
top_bar(d, 4520, 187, 4, 0)
shop_panel(d, 4520)
collection_panel(d, [("Queen Blobfish", "LEGENDARY", 180),
                     ("Madame Zucchini", "EPIC", 75),
                     ("Count Crumb", "EPIC", 110),
                     ("DJ Llama Drama", "RARE", 22)])
leaderboard_panel(d, [("YOU", 12840, 342), ("rival-99", 9840, 260),
                      ("noodle-king", 5210, 180), ("pickle-pete-fan", 3100, 90),
                      ("toaster-tim-2", 1200, 22)])
prompt_bar(d, "Hold E — claim your steal for your base!")
hint(d)
toast(d, "Stolen! Dash home and hold E on your base to claim it!")
save(img, "2-play.jpg")

# --- 3. Event: the tsunami sweeps the map during Golden Hour.
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img, "RGBA")
belt3 = [("Pickle Pete", "COMMON", 6, (120, 200, 80), -30, -25),
         ("Sir Barksalot", "RARE", 30, (160, 110, 60), 5, -25),
         ("Baby Gronk 2.0", "MYTHIC", 1400, (255, 120, 120), 35, -25)]
plots3 = [("The Grand Noodle", "LEGENDARY", 380, (240, 200, 90), 20 + 7, -58 + 4),
          ("Elon Muskrat", "MYTHIC", 600, (100, 160, 255), 60 + 0, -58 - 4)]
draw_world(d, belt3, plots3, wave_x=-10)
draw_player(d, 20, 40, "YOU")
draw_player(d, -45, 45, "rival-99")
top_bar(d, 98400, 1240, 9, 2, event="GOLDEN HOUR x2")
banner(d, "TSUNAMI! DASH HOME TO YOUR BASE!")
prompt_bar(d, "The wave is coming — get on your base pad!")
hint(d)
save(img, "3-event.jpg")
print("done")
