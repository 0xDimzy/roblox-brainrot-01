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
    # v2.5 cast: 10 more characters, 27 -> 37, across every rarity.
    ("Captain Couch", "COMMON", 8, (150, 100, 60)),
    ("Bubble Brian", "COMMON", 10, (140, 200, 255)),
    ("Grandpa Gravy", "RARE", 20, (190, 150, 90)),
    ("MC Microwave", "RARE", 28, (200, 200, 200)),
    ("Baron Von Bagel", "EPIC", 95, (230, 180, 110)),
    ("Lady Lawnmower", "EPIC", 130, (90, 180, 90)),
    ("Sultan of Seltzer", "LEGENDARY", 340, (150, 220, 255)),
    ("Madame Meme", "LEGENDARY", 420, (255, 120, 220)),
    ("Void Vic", "MYTHIC", 1200, (40, 40, 60)),
    ("The Algorithm", "TRANSCENDENT", 12000, (255, 215, 0)),
    # v3 cast: 15 more characters, 37 -> 52, two new Transcendents.
    ("Sir Soggy", "COMMON", 5, (120, 160, 200)),
    ("Mayo Marge", "COMMON", 12, (250, 250, 230)),
    ("Duke Dumpster", "COMMON", 14, (90, 120, 90)),
    ("Professor Pickle Jar", "RARE", 24, (110, 190, 70)),
    ("Lady Lamp", "RARE", 32, (255, 240, 150)),
    ("Captain Croissant", "RARE", 34, (230, 190, 110)),
    ("Baroness Bubblewrap", "EPIC", 100, (180, 220, 255)),
    ("Doctor Donut", "EPIC", 140, (255, 170, 200)),
    ("General Gravy Boat", "EPIC", 160, (170, 120, 60)),
    ("Queen Quinoa", "LEGENDARY", 360, (220, 200, 160)),
    ("Lord Lawn Flamingo", "LEGENDARY", 450, (255, 120, 180)),
    ("Madame Midnight Snack", "MYTHIC", 1300, (80, 60, 120)),
    ("The Intern", "SECRET", 4200, (200, 200, 220)),
    ("Supreme Ohio Overlord", "TRANSCENDENT", 15000, (255, 215, 0)),
    ("Mega Ohio Final Boss", "TRANSCENDENT", 18000, (255, 60, 60)),
]
# v2.5 pets: name, bonus %, color, cost — the six companions (P to open).
PETS = [
    ("Milo the Moth", 10, (220, 200, 140), 2500),
    ("Biscuit Blob", 15, (255, 170, 120), 6000),
    ("Sir Peeps", 20, (255, 230, 80), 12000),
    ("Noodle Nibbler", 25, (255, 210, 140), 25000),
    ("Captain Crumbs", 35, (140, 180, 255), 50000),
    ("Void Kitten", 50, (60, 60, 90), 100000),
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

def draw_pet(draw, x, z, name, color):
    # v2.5: the follower — a half-size companion trailing the player.
    px, py = proj(x, 0, z)
    draw.rounded_rectangle([px - 8, py - 26, px + 8, py - 8], radius=4, fill=color, outline=(20, 20, 20), width=2)
    draw.rounded_rectangle([px - 7, py - 40, px + 7, py - 26], radius=4, fill=color, outline=(20, 20, 20), width=2)
    draw.ellipse([px - 6, py - 36, px - 2, py - 30], fill=(20, 20, 20))
    draw.ellipse([px + 2, py - 36, px + 6, py - 30], fill=(20, 20, 20))
    draw.text((px, py - 52), name, font=font(12), fill=(255, 255, 255), anchor="mm",
              stroke_width=3, stroke_fill=(0, 0, 0))

def draw_world_labels(draw):
    # v2.5: the pet park sign and the quest board, as the world shows them.
    sx, sy = proj(88, 0, 30)
    draw.text((sx, sy - 46), "PET PARK", font=font(15), fill=(40, 40, 40), anchor="mm",
              stroke_width=3, stroke_fill=(255, 195, 0))
    qx, qy = proj(-14, 0, 38)
    draw.text((qx - 60, qy - 52), "DAILY QUESTS", font=font(14), fill=(60, 30, 10), anchor="mm",
              stroke_width=3, stroke_fill=(255, 255, 255))
    # v3: the trading post sign, the raid pad sign and the sky plaza sign.
    tx, ty = proj(-45, 0, 42)
    draw.text((tx, ty - 52), "TRADING POST", font=font(14), fill=(255, 255, 255), anchor="mm",
              stroke_width=3, stroke_fill=(60, 200, 120))
    rx, ry = proj(-12, 0, 70)
    draw.text((rx, ry - 40), "BOSS RAID", font=font(14), fill=(255, 255, 255), anchor="mm",
              stroke_width=3, stroke_fill=(200, 60, 60))

def draw_v3_extras(draw):
    # v3: the raid pad (scorched red circle south of the spawn), the sky
    # lift pad (neon, by the plaza), the coin rush ring markers around
    # the fountain, and the Sky Plaza slab floating 40 studs up.
    ground_rect(draw, -12, 58, 12, 82, 0.5, (200, 60, 60))
    ground_rect(draw, -4, 16, 4, 24, 0.6, (140, 220, 255))
    for k in range(8):
        ang = k * math.pi / 4
        cx, cy = proj(18 * math.cos(ang), 0, 10 + 18 * math.sin(ang))
        draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(255, 215, 0), outline=(150, 110, 0), width=1)
    # Sky Plaza slab: a pale platform over the north plots, on pillars.
    ground_rect(draw, -55, -83, 55, -33, 40, (230, 240, 255))
    for (px, pz) in [(-52, -80), (52, -80), (-52, -36), (52, -36)]:
        bx0, by0 = proj(px, 0, pz)
        bx1, by1 = proj(px, 40, pz)
        draw.line([bx0, by0, bx1, by1], fill=(200, 210, 230), width=5)
    # No text label on the slab itself: the title bar and the raid bar
    # already crowd the top of the frame, and the pale slab reads as a
    # floating platform on its own.

def draw_boss(draw, x, z, name, hp, max_hp):
    # v3: the raid boss — a 3x brainrot with a crown and an HP bar.
    px, py = proj(x, 0, z)
    scale = 2.2
    bw, bh = 30 * scale, 26 * scale
    draw.rounded_rectangle([px - bw / 2, py - bh - 8 * scale, px + bw / 2, py - 8 * scale],
                           radius=8, fill=(255, 60, 60), outline=(20, 20, 20), width=3)
    hw, hh = 22 * scale, 18 * scale
    draw.rounded_rectangle([px - hw / 2, py - bh - hh - 8 * scale, px + hw / 2, py - bh - 8 * scale],
                           radius=6, fill=(255, 60, 60), outline=(20, 20, 20), width=3)
    # crown
    draw.polygon([(px - hw / 2, py - bh - hh - 8 * scale), (px - hw / 4, py - bh - hh - 26 * scale),
                  (px, py - bh - hh - 14 * scale), (px + hw / 4, py - bh - hh - 26 * scale),
                  (px + hw / 2, py - bh - hh - 8 * scale)], fill=(255, 215, 0), outline=(150, 110, 0))
    draw.ellipse([px - 18 * scale / 2, py - bh - hh + 3 * scale, px - 4, py - bh - hh + 11 * scale], fill=(20, 20, 20))
    draw.ellipse([px + 4, py - bh - hh + 3 * scale, px + 18 * scale / 2, py - bh - hh + 11 * scale], fill=(20, 20, 20))
    draw.text((px, py - bh - hh - 58 * scale), name, font=font(20), fill=(255, 255, 255), anchor="mm",
              stroke_width=4, stroke_fill=(0, 0, 0))
    draw.text((px, py - bh - hh - 34 * scale), "TRANSCENDENT", font=font(14), fill=(255, 215, 0), anchor="mm",
              stroke_width=3, stroke_fill=(0, 0, 0))
    # HP bar under the name
    bar_w = 180
    draw.rounded_rectangle([px - bar_w / 2, py - bh - hh - 26 * scale + 52, px + bar_w / 2, py - bh - hh - 26 * scale + 68],
                           radius=6, fill=(60, 20, 20))
    draw.rounded_rectangle([px - bar_w / 2, py - bh - hh - 26 * scale + 52,
                            px - bar_w / 2 + bar_w * hp / max_hp, py - bh - hh - 26 * scale + 68],
                           radius=6, fill=(255, 60, 60))
    draw.text((px, py - bh - hh - 26 * scale + 60), f"BOSS HP: {hp:,} / {max_hp:,}", font=font(13),
              fill=(255, 255, 255), anchor="mm", stroke_width=3, stroke_fill=(0, 0, 0))

def draw_coin(draw, x, z):
    # v3: a gold coin on the rush ring — a spinning prize worth $250.
    px, py = proj(x, 0, z)
    draw.ellipse([px - 12, py - 30, px + 12, py - 6], fill=(255, 215, 0), outline=(150, 110, 0), width=2)
    draw.text((px, py - 18), "$", font=font(16), fill=(150, 110, 0), anchor="mm")

def raid_bar(draw, boss_name, hp, max_hp, time_left, my_damage, share_pct):
    # v3: the top-center raid bar — boss name, HP fill, timer, your share.
    draw.rounded_rectangle([430, 64, 850, 172], radius=12, fill=(25, 25, 35, 235))
    draw.text((640, 84), f"BOSS RAID: {boss_name}", font=font(20), fill=(255, 80, 80), anchor="mm")
    draw.rounded_rectangle([442, 100, 838, 118], radius=6, fill=(60, 20, 20))
    draw.rounded_rectangle([442, 100, 442 + 396 * hp / max_hp, 118], radius=6, fill=(255, 60, 60))
    draw.text((640, 132), f"HP {hp:,} / {max_hp:,}  ·  {time_left} left  ·  Press F to fight!",
              font=font(15), fill=(255, 215, 0), anchor="mm")
    draw.text((640, 156), f"Your damage: {my_damage:,} ({share_pct}% of the reward pool)",
              font=font(15), fill=(120, 255, 140), anchor="mm")

def trade_panel(draw, offers):
    # v3: the trading panel (T) — incoming offers with accept/decline/confirm.
    draw.rounded_rectangle([964, 130, 1264, 600], radius=12, fill=(25, 25, 35, 235))
    draw.text((1114, 152), "TRADING  (T to close)", font=font(22), fill=(120, 255, 140), anchor="mm")
    draw.text((976, 182), "1 incoming offer · stock: 9", font=font(14),
              fill=(200, 220, 255), anchor="lm")
    y = 208
    for (frm, offered, wanted, cash) in offers:
        draw.rounded_rectangle([976, y, 1252, y + 110], radius=8, fill=(45, 45, 60))
        draw.text((988, y + 12), f"{frm} offers {offered}", font=font(14), fill=(255, 255, 255), anchor="lm")
        draw.text((988, y + 32), f"for your {wanted} + {cash}", font=font(14), fill=(255, 255, 255), anchor="lm")
        draw.text((988, y + 52), "Expires in 0:47.", font=font(13), fill=(200, 220, 255), anchor="lm")
        draw.rounded_rectangle([988, y + 68, 1070, y + 100], radius=4, fill=(40, 150, 70))
        draw.text((1029, y + 84), "ACCEPT", font=font(13), fill=(255, 255, 255), anchor="mm")
        draw.rounded_rectangle([1078, y + 68, 1160, y + 100], radius=4, fill=(180, 60, 60))
        draw.text((1119, y + 84), "DECLINE", font=font(13), fill=(255, 255, 255), anchor="mm")
        draw.rounded_rectangle([1168, y + 68, 1240, y + 100], radius=4, fill=(60, 90, 200))
        draw.text((1204, y + 84), "CONFIRM", font=font(12), fill=(255, 255, 255), anchor="mm")
        y += 122

def minigame_panel(draw, coins_left, my_score, my_best):
    # v3: the coin rush panel — timer, coins left, your score and best.
    draw.rounded_rectangle([964, 76, 1264, 246], radius=12, fill=(25, 25, 35, 235))
    draw.text((1114, 98), "COIN RUSH!", font=font(22), fill=(255, 215, 0), anchor="mm")
    draw.text((976, 126), f"0:32 left, {coins_left} coins on the ring!", font=font(15),
              fill=(200, 220, 255), anchor="lm")
    draw.text((976, 152), f"Coins: {my_score}  ·  Best: {my_best}", font=font(15),
              fill=(120, 255, 140), anchor="lm")
    draw.text((976, 178), "1. YOU — 7 coins", font=font(14), fill=(255, 255, 255), anchor="lm")
    draw.text((976, 200), "2. rival-99 — 5 coins", font=font(14), fill=(255, 255, 255), anchor="lm")

def team_panel(draw, team_name, members, vault):
    # v3: the team panel (Y) — your team, members, vault, top teams.
    draw.rounded_rectangle([16, 130, 316, 550], radius=12, fill=(25, 25, 35, 235))
    draw.text((166, 152), "TEAMS  (Y to close)", font=font(22), fill=(120, 255, 140), anchor="mm")
    draw.text((28, 184), f"Team {team_name} (leader: YOU)", font=font(16),
              fill=(200, 220, 255), anchor="lm")
    draw.text((28, 210), f"Members (3/5): YOU, noodle-king, pickle-pete-fan", font=font(14),
              fill=(255, 255, 255), anchor="lm")
    draw.text((28, 234), f"Vault: {money(vault)}  ·  Pays $500/member/hour", font=font(15),
              fill=(255, 215, 0), anchor="lm")
    draw.rounded_rectangle([28, 258, 160, 290], radius=4, fill=(40, 150, 70))
    draw.text((94, 274), "CREATE ($10K)", font=font(13), fill=(255, 255, 255), anchor="mm")
    draw.rounded_rectangle([172, 258, 304, 290], radius=4, fill=(60, 90, 200))
    draw.text((238, 274), "JOIN", font=font(13), fill=(255, 255, 255), anchor="mm")
    draw.text((28, 310), "TOP TEAMS:", font=font(15), fill=(200, 220, 255), anchor="lm")
    draw.text((28, 334), "1. Noodle Gang — $48,200 earned, vault $3,400", font=font(14),
              fill=(255, 255, 255), anchor="lm")
    draw.text((28, 356), "2. Ohio Royals — $31,900 earned, vault $1,200", font=font(14),
              fill=(255, 255, 255), anchor="lm")

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
    # v2.5: pet park pad in the east corner + quest board west of spawn.
    ground_rect(draw, 80, 22, 96, 38, 0.5, (120, 220, 130))
    ground_rect(draw, -19, 36, -9, 40, 1.0, (200, 160, 90))
    # plots + pedestals
    for i, (px, pz) in enumerate(PLOT_POS):
        ground_rect(draw, px - 12, pz - 9, px + 12, pz + 9, 0.5, PLOT_COLORS[i])
        for ox, oz in PED_OFF:
            ground_rect(draw, px + ox - 2, pz + oz - 2, px + ox + 2, pz + oz + 2, 1.0, PLOT_COLORS[i])
    # v3: raid pad, lift pad, coin ring, Sky Plaza slab on its pillars.
    draw_v3_extras(draw)
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

def top_bar(draw, cash, income, count, rebirths, event=None, show_title=True):
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
    if not show_title:
        # v3: the raid shot hides the title so the raid bar owns the top.
        return
    draw.text((W / 2, 92), "BRAINROT BOULEVARD", font=font(34), fill=(255, 195, 0), anchor="mm",
              stroke_width=4, stroke_fill=(0, 0, 0))
    # v2: personal stats line under the title (bought / steals / best $/s).
    draw.text((W / 2, 122), "Bought 7  ·  Steals 2  ·  Slaps 1  ·  Best $1,240/s", font=font(18),
              fill=(200, 220, 255), anchor="mm", stroke_width=3, stroke_fill=(0, 0, 0))

def prompt_bar(draw, text):
    draw.rounded_rectangle([320, 648, 960, 696], radius=10, fill=(25, 25, 35, 220))
    draw.text((640, 672), text, font=font(22), fill=(255, 255, 255), anchor="mm")

def hint(draw):
    draw.text((16, 702), "WASD move  ·  E interact  ·  Q shop  ·  T trade  ·  Y team  ·  F raid",
              font=font_reg(14), fill=(255, 255, 255), anchor="lb", stroke_width=3, stroke_fill=(0, 0, 0))

def toast(draw, text, y=125):
    draw.text((640, y), text, font=font(24), fill=(255, 255, 255), anchor="mm",
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

def pets_panel(draw, owned):
    # v2.5: the pets panel (P) — six pets, owned ones marked, active one green.
    draw.rounded_rectangle([964, 130, 1264, 600], radius=12, fill=(25, 25, 35, 235))
    draw.text((1114, 152), "PETS  (P to close)", font=font(22), fill=(255, 215, 0), anchor="mm")
    draw.text((976, 180), "Milo the Moth is following you", font=font(16),
              fill=(120, 255, 140), anchor="lm")
    draw.text((976, 204), "2 of 6 pets (+25% income)", font=font(16),
              fill=(200, 220, 255), anchor="lm")
    y = 224
    for name, bonus, color, cost in PETS:
        if name in owned:
            state, state_color = "FOLLOWING", (120, 255, 140)
        elif name == "Biscuit Blob":
            state, state_color = "OWNED — click to equip", (200, 220, 255)
        else:
            state, state_color = money(cost), (200, 220, 255)
        bg = (40, 150, 70) if name in owned else (90, 60, 140)
        draw.rounded_rectangle([976, y, 1252, y + 52], radius=8, fill=bg)
        draw.ellipse([988, y + 14, 1008, y + 38], fill=color, outline=(20, 20, 20), width=2)
        draw.text((1016, y + 16), f"{name}  ·  +{bonus}%", font=font(15),
                  fill=(255, 255, 255), anchor="lm")
        draw.text((1016, y + 38), state, font=font_reg(13),
                  fill=state_color, anchor="lm")
        y += 60

def quests_panel(draw, quests):
    # v2.5: the daily quests panel (J) — three quests, live progress, claim buttons.
    draw.rounded_rectangle([16, 130, 316, 460], radius=12, fill=(25, 25, 35, 235))
    draw.text((166, 152), "DAILY QUESTS  (J to close)", font=font(20), fill=(120, 255, 140), anchor="mm")
    draw.text((28, 182), "1 of 3 quests done  ·  0 claimed", font=font(16),
              fill=(200, 220, 255), anchor="lm")
    y = 208
    for title, progress, target, reward, state in quests:
        draw.rounded_rectangle([28, y, 304, y + 72], radius=8, fill=(45, 45, 60))
        draw.text((40, y + 12), title, font=font(16), fill=(255, 255, 255), anchor="lm")
        draw.text((40, y + 34), f"{progress} / {target}", font=font(14),
                  fill=(200, 220, 255), anchor="lm")
        btn_bg = (40, 150, 70) if state == "CLAIM" else (80, 80, 90)
        draw.rounded_rectangle([40, y + 50, 292, y + 68], radius=4, fill=btn_bg)
        draw.text((166, y + 59), f"{state} +{money(reward)}" if state == "CLAIM" else state,
                  font=font(13), fill=(255, 255, 255), anchor="mm")
        y += 80

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
# v3: the belt carries the new Transcendent star, the Sky Plaza floats
# above the north plots, and the Mega Ohio Final Boss waits on the raid pad.
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img, "RGBA")
belt = []
# v3: five v1/v2 faces plus Mega Ohio Final Boss, the new Transcendent star.
for i, (name, rarity, rate, color) in enumerate(BRAINROTS[:5] + [BRAINROTS[51]]):
    belt.append((name, rarity, rate, color, -55 + i * 22, -25))
plots = []
plots.append(("Queen Blobfish", "LEGENDARY", 180, (255, 150, 180), -60 + 7, -58 + 4))
plots.append(("Elon Muskrat", "MYTHIC", 600, (100, 160, 255), 20 + 0, -58 - 4))
plots.append(("CEO of Ohio", "TRANSCENDENT", 9000, (255, 215, 0), 60 - 7, -58 + 4))
plots.append(("Madame Meme", "LEGENDARY", 420, (255, 120, 220), -20 - 7, 58 + 4))
draw_world(d, belt, plots)
draw_world_labels(d)
draw_boss(d, 10, 70, "Mega Ohio Final Boss", 5000, 5000)
draw_player(d, 30, 32, "YOU")
draw_pet(d, 34, 36, "Milo the Moth", (220, 200, 140))
top_bar(d, 12840, 342, 7, 1)
prompt_bar(d, "E — Buy Golden DJ Llama Drama for $1,320  ($44/s)")
hint(d)
save(img, "1-thumbnail.jpg")

# --- 2. Play: trading at the post, a coin rush on the ring, team panel open (v3).
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img, "RGBA")
belt2 = [("Toaster Tim", "COMMON", 4, (200, 120, 60), -40, -25),
         ("Chairman Meow", "RARE", 15, (255, 170, 60), -10, -25),
         ("Captain Couch", "COMMON", 8, (150, 100, 60), 20, -25),
         ("Lord Spaghetti", "LEGENDARY", 260, (255, 230, 150), 50, -25)]
plots2 = [("Queen Blobfish", "LEGENDARY", 180, (255, 150, 180), -60 - 7, 58 - 4),
          ("Madame Zucchini", "EPIC", 75, (90, 200, 90), -60 + 0, 58 - 4),
          ("Count Crumb", "EPIC", 110, (120, 80, 40), -60 + 7, 58 - 4),
          ("DJ Llama Drama", "RARE", 22, (220, 120, 220), -20 - 7, 58 + 4)]
draw_world(d, belt2, plots2)
draw_world_labels(d)
draw_coin(d, 14, 22)
draw_coin(d, -16, 4)
draw_coin(d, 8, -4)
draw_player(d, -30, 20, "YOU", carrying=("Lord Spaghetti", "LEGENDARY", 260, (255, 230, 150)))
draw_pet(d, -26, 24, "Milo the Moth", (220, 200, 140))
draw_player(d, 10, 55, "rival-99")
top_bar(d, 4520, 187, 4, 0)
trade_panel(d, [("rival-99", "Sir Barksalot (RARE)", "Queen Blobfish", "$500")])
team_panel(d, "Noodle Gang", ["YOU", "noodle-king", "pickle-pete-fan"], 3400)
prompt_bar(d, "Trade offer sent — press T to watch the inbox!")
hint(d)
toast(d, "COIN RUSH! Click the gold coins!", 160)
save(img, "2-play.jpg")

# --- 3. Event: the boss raid — the Mega Ohio Final Boss on the raid
# pad, the raid bar overhead, the whole server fighting it (v3).
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img, "RGBA")
belt3 = [("Pickle Pete", "COMMON", 6, (120, 200, 80), -30, -25),
         ("Sir Barksalot", "RARE", 30, (160, 110, 60), 5, -25),
         ("Void Vic", "MYTHIC", 1200, (40, 40, 60), 35, -25)]
plots3 = [("The Grand Noodle", "LEGENDARY", 380, (240, 200, 90), 20 + 7, -58 + 4),
          ("Elon Muskrat", "MYTHIC", 600, (100, 160, 255), 60 + 0, -58 - 4)]
draw_world(d, belt3, plots3)
draw_world_labels(d)
draw_boss(d, 0, 66, "Mega Ohio Final Boss", 3250, 5000)
draw_player(d, 20, 40, "YOU")
draw_pet(d, 24, 44, "Sir Peeps", (255, 230, 80))
draw_player(d, -45, 45, "rival-99")
draw_player(d, 35, 55, "noodle-king")
top_bar(d, 98400, 1240, 9, 2, event="BOSS RAID", show_title=False)
raid_bar(d, "Mega Ohio Final Boss", 3250, 5000, "3:12", 850, 34)
minigame_panel(d, 9, 7, 11)
banner(d, "BOSS RAID! FIGHT TOGETHER, SPLIT $50,000!")
prompt_bar(d, "Press F near the raid pad to hit the boss!")
hint(d)
save(img, "3-event.jpg")
print("done")
