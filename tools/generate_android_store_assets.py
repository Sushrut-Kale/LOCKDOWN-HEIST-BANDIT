"""
tools/generate_android_store_assets.py
Generates Android icons, adaptive foreground/background, notification icons,
blueprint splash card, Play Store feature graphic, and screenshots.
"""

import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ANDROID_DIR = "assets/store/android"
PLAY_DIR = "assets/store/play"
UI_DIR = "assets/ui"

for d in [ANDROID_DIR, PLAY_DIR, UI_DIR]:
    os.makedirs(d, exist_ok=True)

# Colors
NAVY_DEEP = (10, 18, 34, 255)
NAVY_GRID = (24, 48, 86, 255)
NAVY_ACCENT = (36, 75, 130, 255)
CYAN_GLOW = (0, 220, 255, 255)
GOLD_KEY = (255, 215, 0, 255)
GOLD_DARK = (218, 165, 32, 255)
WHITE = (255, 255, 255, 255)
MASK_GRAY = (40, 44, 52, 255)
BANDIT_FUR = (130, 140, 155, 255)
CRIMSON = (255, 50, 60, 255)

def draw_blueprint_grid(draw, w, h, step=40, grid_col=(20, 42, 75, 255)):
    for x in range(0, w, step):
        col = (30, 65, 115, 255) if x % (step * 4) == 0 else grid_col
        draw.line([(x, 0), (x, h)], fill=col, width=2 if x % (step * 4) == 0 else 1)
    for y in range(0, h, step):
        col = (30, 65, 115, 255) if y % (step * 4) == 0 else grid_col
        draw.line([(0, y), (w, y)], fill=col, width=2 if y % (step * 4) == 0 else 1)

def draw_raccoon_mask(draw, cx, cy, scale=1.0):
    # Mask silhouette
    w = 260 * scale
    h = 95 * scale
    draw.polygon([
        (cx - w, cy - h*0.2),
        (cx - w*0.7, cy - h*0.9),
        (cx - w*0.2, cy - h*0.5),
        (cx, cy - h*0.2),
        (cx + w*0.2, cy - h*0.5),
        (cx + w*0.7, cy - h*0.9),
        (cx + w, cy - h*0.2),
        (cx + w*0.8, cy + h*0.8),
        (cx + w*0.3, cy + h*0.5),
        (cx, cy + h*0.9),
        (cx - w*0.3, cy + h*0.5),
        (cx - w*0.8, cy + h*0.8)
    ], fill=(25, 28, 35, 255), outline=CYAN_GLOW, width=int(4 * scale))

    # Eyes (glowing bandit eyes)
    ew = 42 * scale
    eh = 24 * scale
    for ex in [cx - 90 * scale, cx + 90 * scale]:
        draw.ellipse([ex - ew, cy - eh*0.6, ex + ew, cy + eh*0.6], fill=(255, 255, 240, 255))
        draw.ellipse([ex - ew*0.5, cy - eh*0.5, ex + ew*0.5, cy + eh*0.5], fill=CYAN_GLOW)
        draw.ellipse([ex - ew*0.2, cy - eh*0.3, ex + ew*0.2, cy + eh*0.3], fill=(10, 20, 30, 255))

def draw_master_key(draw, cx, cy, scale=1.0, angle_deg=-30):
    rad = math.radians(angle_deg)
    cos_a = math.cos(rad)
    sin_a = math.sin(rad)

    def rot(lx, ly):
        rx = lx * cos_a - ly * sin_a
        ry = lx * sin_a + ly * cos_a
        return (cx + rx * scale, cy + ry * scale)

    # Key Bow (Ring)
    ring_r = 70
    steps = 36
    outer_pts = [rot(ring_r * math.cos(2*math.pi*i/steps), ring_r * math.sin(2*math.pi*i/steps)) for i in range(steps)]
    draw.polygon(outer_pts, fill=GOLD_KEY, outline=(255, 240, 120, 255), width=int(4*scale))
    
    inner_r = 38
    inner_pts = [rot(inner_r * math.cos(2*math.pi*i/steps), inner_r * math.sin(2*math.pi*i/steps)) for i in range(steps)]
    draw.polygon(inner_pts, fill=NAVY_DEEP)

    # Shaft
    p1 = rot(ring_r * 0.8, -12)
    p2 = rot(ring_r * 0.8 + 190, -12)
    p3 = rot(ring_r * 0.8 + 190, 12)
    p4 = rot(ring_r * 0.8, 12)
    draw.polygon([p1, p2, p3, p4], fill=GOLD_KEY, outline=(255, 240, 120, 255), width=int(3*scale))

    # Teeth / Bits
    b1 = rot(ring_r * 0.8 + 140, 12)
    b2 = rot(ring_r * 0.8 + 140, 48)
    b3 = rot(ring_r * 0.8 + 160, 48)
    b4 = rot(ring_r * 0.8 + 160, 12)
    draw.polygon([b1, b2, b3, b4], fill=GOLD_KEY)

    c1 = rot(ring_r * 0.8 + 175, 12)
    c2 = rot(ring_r * 0.8 + 175, 60)
    c3 = rot(ring_r * 0.8 + 190, 60)
    c4 = rot(ring_r * 0.8 + 190, 12)
    draw.polygon([c1, c2, c3, c4], fill=GOLD_KEY)

def generate_adaptive_icons():
    # 1. Background 1024x1024
    bg = Image.new("RGBA", (1024, 1024), NAVY_DEEP)
    bdraw = ImageDraw.Draw(bg)
    draw_blueprint_grid(bdraw, 1024, 1024, step=48)
    # Vignette glow
    glow = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([212, 212, 812, 812], fill=(15, 60, 110, 140))
    glow = glow.filter(ImageFilter.GaussianBlur(70))
    bg.paste(Image.alpha_composite(bg, glow), (0, 0))
    bg.save(os.path.join(ANDROID_DIR, "ic_launcher_background.png"))

    # 2. Foreground 1024x1024 (Safe zone within inner 66% = 675px circle)
    fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    fdraw = ImageDraw.Draw(fg)
    # Central elements: Raccoon Mask on top, Gold Master Key below
    draw_raccoon_mask(fdraw, 512, 420, scale=1.35)
    draw_master_key(fdraw, 490, 640, scale=1.45, angle_deg=-25)
    fg.save(os.path.join(ANDROID_DIR, "ic_launcher_foreground.png"))

    # 3. Combined Icon 1024x1024
    icon1024 = Image.alpha_composite(bg, fg)
    icon1024.save(os.path.join(ANDROID_DIR, "icon_1024.png"))
    
    # 4. Icon 512x512
    icon512 = icon1024.resize((512, 512), Image.Resampling.LANCZOS)
    icon512.save(os.path.join(ANDROID_DIR, "icon_512.png"))
    icon512.save(os.path.join(PLAY_DIR, "store_icon_512.png"))

    # 5. Round Icon 512x512
    mask = Image.new("L", (512, 512), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.ellipse([8, 8, 504, 504], fill=255)
    round512 = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    round512.paste(icon512, (0, 0), mask)
    round512.save(os.path.join(ANDROID_DIR, "icon_round_512.png"))

    # 6. Notification Icon 96x96 (White silhouette on transparent)
    notif = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    ndraw = ImageDraw.Draw(notif)
    # Pure white key silhouette
    # Ring
    ndraw.ellipse([14, 20, 48, 54], outline=WHITE, width=6)
    # Shaft
    ndraw.line([(45, 37), (82, 37)], fill=WHITE, width=6)
    # Teeth
    ndraw.line([(68, 37), (68, 55)], fill=WHITE, width=6)
    ndraw.line([(80, 37), (80, 62)], fill=WHITE, width=6)
    notif.save(os.path.join(ANDROID_DIR, "notification_icon_96.png"))

def generate_splash():
    # 1920x1080 Blueprint Boot Card
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), NAVY_DEEP)
    draw = ImageDraw.Draw(img)
    draw_blueprint_grid(draw, w, h, step=48)

    # Center glow
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([w//2 - 450, h//2 - 250, w//2 + 450, h//2 + 250], fill=(20, 65, 120, 160))
    glow = glow.filter(ImageFilter.GaussianBlur(90))
    img.paste(Image.alpha_composite(img, glow), (0, 0))

    draw = ImageDraw.Draw(img)
    # Living Blueprint Border
    draw.rectangle([60, 60, w - 60, h - 60], outline=CYAN_GLOW, width=3)
    draw.rectangle([70, 70, w - 70, h - 70], outline=(30, 80, 140, 200), width=1)
    
    # Corner registration marks
    for cx, cy in [(60, 60), (w-60, 60), (60, h-60), (w-60, h-60)]:
        draw.line([(cx - 20, cy), (cx + 20, cy)], fill=CYAN_GLOW, width=2)
        draw.line([(cx, cy - 20), (cx, cy + 20)], fill=CYAN_GLOW, width=2)

    # Center Key Art
    draw_raccoon_mask(draw, w // 2, 360, scale=1.4)
    draw_master_key(draw, w // 2 - 20, 520, scale=1.3, angle_deg=-20)

    # Title Banner
    # Top subtitle
    draw.text((w // 2, 680), "A  C O O P E R - C L A S S   S T E A L T H   T H R I L L E R", fill=(130, 180, 230, 255), anchor="mm")
    # Main Title
    draw.text((w // 2, 740), "LOCKDOWN HEIST: BANDIT", fill=CYAN_GLOW, anchor="mm")
    draw.text((w // 2, 785), "SECTOR INFILTRATION // PROTOCOL V0.3.0", fill=(200, 220, 240, 200), anchor="mm")
    
    # Progress / Loading indicator
    draw.rectangle([w // 2 - 180, 880, w // 2 + 180, 888], outline=CYAN_GLOW, width=1)
    draw.rectangle([w // 2 - 176, 882, w // 2 - 20, 886], fill=GOLD_KEY)
    draw.text((w // 2, 920), "INITIALIZING SECURITY BYPASS...", fill=(120, 160, 200, 255), anchor="mm")

    img.save(os.path.join(ANDROID_DIR, "splash_card.png"))

def generate_play_store_graphics():
    # 1. Feature Graphic 1024x500
    fw, fh = 1024, 500
    feat = Image.new("RGBA", (fw, fh), NAVY_DEEP)
    draw = ImageDraw.Draw(feat)
    draw_blueprint_grid(draw, fw, fh, step=40)

    # Diagonal stealth flashlight sweep
    beam = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(beam)
    bdraw.polygon([(0, 0), (550, 0), (820, fh), (200, fh)], fill=(255, 230, 140, 45))
    beam = beam.filter(ImageFilter.GaussianBlur(15))
    feat.paste(Image.alpha_composite(feat, beam), (0, 0))
    draw = ImageDraw.Draw(feat)

    # Red Lockdown alarm accent on right edge
    alarm = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(alarm)
    adraw.ellipse([fw - 200, fh // 2 - 200, fw + 200, fh // 2 + 200], fill=(255, 40, 60, 80))
    alarm = alarm.filter(ImageFilter.GaussianBlur(50))
    feat.paste(Image.alpha_composite(feat, alarm), (0, 0))
    draw = ImageDraw.Draw(feat)

    # Bandit artwork left/center
    draw_raccoon_mask(draw, 340, 200, scale=1.1)
    draw_master_key(draw, 450, 280, scale=1.0, angle_deg=-25)

    # Bold Typography right
    draw.text((640, 150), "LOCKDOWN HEIST", fill=WHITE, font=None)
    draw.text((640, 195), "BANDIT", fill=CYAN_GLOW, font=None)
    draw.text((640, 260), "OUTSMART PATROLS. STEAL THE KEY.", fill=(255, 220, 80, 255), font=None)
    draw.text((640, 290), "SURVIVE THE CRIMSON LOCKDOWN.", fill=(255, 120, 120, 255), font=None)
    draw.text((640, 350), "★ 100% Non-Lethal Pure Stealth Thriller", fill=(170, 210, 255, 255), font=None)
    draw.text((640, 380), "★ Offline Play & Instant 60 FPS", fill=(170, 210, 255, 255), font=None)

    feat.save(os.path.join(PLAY_DIR, "feature_graphic_1024x500.png"))

    # 2. Screenshots (4 Landscape 1920x1080)
    # Screenshot 1: Main Menu & Loadout
    s1 = Image.new("RGBA", (1920, 1080), NAVY_DEEP)
    d1 = ImageDraw.Draw(s1)
    draw_blueprint_grid(d1, 1920, 1080, step=48)
    draw_raccoon_mask(d1, 960, 420, scale=1.6)
    draw_master_key(d1, 940, 600, scale=1.4, angle_deg=-25)
    d1.rectangle([700, 720, 1220, 780], fill=(0, 180, 220, 240), outline=WHITE, width=2)
    d1.text((960, 750), "PLAY CAMPAIGN — FLOOR 1", fill=NAVY_DEEP, anchor="mm")
    d1.rectangle([700, 800, 1220, 850], fill=(25, 45, 80, 220), outline=CYAN_GLOW, width=2)
    d1.text((960, 825), "DAILY HEIST // EQUIPPED: SMOKE PELLET", fill=CYAN_GLOW, anchor="mm")
    d1.text((960, 120), "LOCKDOWN HEIST: BANDIT", fill=CYAN_GLOW, anchor="mm")
    d1.text((960, 170), "TACTICAL BLUEPRINT STEALTH // V0.3.0", fill=(180, 210, 240, 220), anchor="mm")
    s1.save(os.path.join(PLAY_DIR, "screenshot_01_main_menu.png"))

    # Screenshot 2: Infiltration flashlight cones
    s2 = Image.new("RGBA", (1920, 1080), (12, 20, 36, 255))
    d2 = ImageDraw.Draw(s2)
    draw_blueprint_grid(d2, 1920, 1080, step=48)
    # Flashlight beams
    b_layer = Image.new("RGBA", (1920, 1080), (0, 0, 0, 0))
    bd = ImageDraw.Draw(b_layer)
    bd.polygon([(300, 450), (950, 220), (980, 680)], fill=(255, 240, 140, 80))
    bd.polygon([(1400, 650), (820, 520), (800, 920)], fill=(255, 240, 140, 80))
    b_layer = b_layer.filter(ImageFilter.GaussianBlur(12))
    s2.paste(Image.alpha_composite(s2, b_layer), (0, 0))
    d2 = ImageDraw.Draw(s2)
    # Bandit sneaking
    d2.ellipse([480, 580, 540, 640], fill=BANDIT_FUR, outline=CYAN_GLOW, width=3)
    d2.text((510, 560), "BANDIT (SNEAKING)", fill=CYAN_GLOW, anchor="mm")
    # HUD Top Bar
    d2.rectangle([0, 0, 1920, 72], fill=(8, 14, 26, 230))
    d2.text((100, 36), "FLOOR 03 // SEED #481920", fill=CYAN_GLOW, anchor="lm")
    d2.text((960, 36), "INFILTRATION PHASE — LOCATE THE MASTER KEY", fill=(255, 220, 80, 255), anchor="mm")
    d2.text((1820, 36), "LOOT: 14 / 28", fill=GOLD_KEY, anchor="rm")
    s2.save(os.path.join(PLAY_DIR, "screenshot_02_infiltration_flashlights.png"))

    # Screenshot 3: Crimson Lockdown Siren
    s3 = Image.new("RGBA", (1920, 1080), (28, 10, 16, 255))
    d3 = ImageDraw.Draw(s3)
    draw_blueprint_grid(d3, 1920, 1080, step=48, grid_col=(70, 20, 30, 255))
    # Crimson alarm lighting
    c_layer = Image.new("RGBA", (1920, 1080), (0, 0, 0, 0))
    cd = ImageDraw.Draw(c_layer)
    cd.rectangle([0, 0, 1920, 1080], fill=(255, 30, 40, 45))
    cd.ellipse([700, 300, 1220, 820], fill=(255, 60, 80, 70))
    c_layer = c_layer.filter(ImageFilter.GaussianBlur(25))
    s3.paste(Image.alpha_composite(s3, c_layer), (0, 0))
    d3 = ImageDraw.Draw(s3)
    # Lockdown banner
    d3.rectangle([360, 110, 1560, 190], fill=(180, 20, 30, 240), outline=(255, 120, 130, 255), width=3)
    d3.text((960, 150), "LOCKDOWN INITIATED — ESCAPE TO THE VAULT!", fill=WHITE, anchor="mm")
    d3.text((960, 540), "TRANSPONDER PING: 4s", fill=(255, 230, 80, 255), anchor="mm")
    # HUD
    d3.rectangle([0, 0, 1920, 72], fill=(18, 6, 10, 230))
    d3.text((100, 36), "FLOOR 08 // LOCKDOWN ACTIVE", fill=CRIMSON, anchor="lm")
    d3.text((1820, 36), "BAG: HEAVY (SLOW -12%)", fill=(255, 160, 60, 255), anchor="rm")
    s3.save(os.path.join(PLAY_DIR, "screenshot_03_crimson_lockdown.png"))

    # Screenshot 4: Vault Victory Newspaper
    s4 = Image.new("RGBA", (1920, 1080), NAVY_DEEP)
    d4 = ImageDraw.Draw(s4)
    draw_blueprint_grid(d4, 1920, 1080, step=48)
    # Newspaper frame
    d4.rectangle([460, 140, 1460, 940], fill=(245, 240, 225, 255), outline=(180, 160, 130, 255), width=6)
    d4.text((960, 200), "THE METROPOLIS CHRONICLE", fill=(20, 20, 20, 255), anchor="mm")
    d4.line([(500, 230), (1420, 230)], fill=(30, 30, 30, 255), width=3)
    d4.text((960, 280), "BANDIT OUTSMARTS VAULT SECURITY AGAIN!", fill=(160, 20, 20, 255), anchor="mm")
    draw_raccoon_mask(d4, 960, 460, scale=1.3)
    d4.text((960, 640), "★★★ HEIST RATING: MASTER THIEF ★★★", fill=(218, 165, 32, 255), anchor="mm")
    d4.text((960, 700), "Coins Pocketed: +42 Gold // Stealth Bonus: Undetected", fill=(40, 40, 40, 255), anchor="mm")
    d4.rectangle([760, 770, 1160, 840], fill=(30, 140, 60, 255), outline=WHITE, width=2)
    d4.text((960, 805), "NEXT FLOOR >>", fill=WHITE, anchor="mm")
    s4.save(os.path.join(PLAY_DIR, "screenshot_04_vault_victory.png"))

    # Tablet Screenshot (2560x1600)
    t = s2.resize((2560, 1600), Image.Resampling.LANCZOS)
    t.save(os.path.join(PLAY_DIR, "screenshot_tablet_2560x1600.png"))

def generate_touch_icons():
    # Generate high-res circular touch action icons
    icons = [
        ("touch_context_knockout.png", (0, 220, 255, 230), "KNOCKOUT", "BONK"),
        ("touch_context_cuff.png", (255, 180, 40, 230), "CUFF", "ZIP"),
        ("touch_context_pickpocket.png", (255, 215, 0, 230), "STEAL", "HOLD"),
        ("touch_context_hide.png", (100, 220, 120, 230), "HIDE", "LOCKER"),
        ("touch_context_vent.png", (80, 240, 180, 230), "VENT", "CRAWL"),
        ("touch_context_unlock.png", (255, 215, 0, 230), "UNLOCK", "VAULT"),
        ("touch_context_default.png", (140, 160, 190, 200), "ACTION", "[E]"),
        ("touch_sprint.png", (255, 140, 40, 230), "SPRINT", "RUN"),
        ("touch_pause.png", (180, 200, 225, 230), "PAUSE", "II"),
    ]
    size = 128
    for fname, color, label, sub in icons:
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        # Outer ring
        draw.ellipse([6, 6, size-6, size-6], fill=(15, 24, 42, 190), outline=color, width=4)
        draw.ellipse([14, 14, size-14, size-14], outline=(color[0], color[1], color[2], 90), width=2)
        # Inner text
        draw.text((size // 2, size // 2 - 10), sub, fill=color, anchor="mm")
        draw.text((size // 2, size // 2 + 16), label, fill=WHITE, anchor="mm")
        img.save(os.path.join(UI_DIR, fname))

if __name__ == "__main__":
    print("Generating Android adaptive icons & store assets...")
    generate_adaptive_icons()
    generate_splash()
    generate_play_store_graphics()
    generate_touch_icons()
    print("All store assets generated successfully!")
