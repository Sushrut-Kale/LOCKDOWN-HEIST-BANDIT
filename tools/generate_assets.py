"""
tools/generate_assets.py
Comprehensive procedural asset generator for LOCKDOWN HEIST: BANDIT.
Generates:
1. High-DPI Living Blueprint + Comic Heist sprites & tilesets (Pillow).
2. UI icons, badges, input prompts, portraits.
3. Synchronized Dual-Stem 116-BPM Heist Music + 20 Synthesized SFX (.wav).
"""

import os
import math
import random
import struct
import wave
from PIL import Image, ImageDraw, ImageFilter

random.seed(42)

SPRITES_DIR = "assets/sprites"
UI_DIR = "assets/ui"
AUDIO_DIR = "assets/audio"
SFX_DIR = "assets/audio/sfx"

for d in [SPRITES_DIR, UI_DIR, AUDIO_DIR, SFX_DIR]:
    os.makedirs(d, exist_ok=True)

# -------------------------------------------------------------
# 1. VISUAL ASSETS GENERATION (PILLOW)
# -------------------------------------------------------------

def create_smooth_light_cone():
    """Generates a 512x512 smooth 55-degree flashlight cone texture."""
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    center_x = size // 2
    center_y = size // 2
    max_radius = size * 0.48
    half_angle_rad = math.radians(28.0) # 56 degree total cone

    # Direction: pointing Right (0 rad)
    pixels = img.load()
    for y in range(size):
        dy = y - center_y
        for x in range(size):
            dx = x - center_x
            dist = math.hypot(dx, dy)
            if dist == 0:
                pixels[x, y] = (255, 255, 230, 255)
                continue
            if dist > max_radius:
                continue

            angle = math.atan2(dy, dx)
            # Normalize angle to [-pi, pi]
            angle_diff = abs(angle)
            if angle_diff > half_angle_rad:
                continue

            # Angular falloff
            ang_factor = math.cos((angle_diff / half_angle_rad) * (math.pi / 2.0))
            # Radial falloff (smooth cubic/quadratic)
            rad_factor = max(0.0, 1.0 - (dist / max_radius))
            intensity = (rad_factor ** 1.5) * (ang_factor ** 1.2)

            alpha = int(255 * intensity)
            if alpha > 0:
                # Golden-white flashlight color
                pixels[x, y] = (255, 245, 200, alpha)

    img.save(os.path.join(SPRITES_DIR, "light_cone_smooth.png"))
    print("Created light_cone_smooth.png")

def create_soft_radial_light():
    """Generates a 256x256 smooth radial glow texture."""
    size = 256
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    center = size // 2
    max_r = size // 2
    pixels = img.load()
    for y in range(size):
        dy = y - center
        for x in range(size):
            dx = x - center
            dist = math.hypot(dx, dy)
            if dist <= max_r:
                factor = (1.0 - (dist / max_r)) ** 2.0
                alpha = int(255 * factor)
                pixels[x, y] = (180, 235, 255, alpha)
    img.save(os.path.join(SPRITES_DIR, "light_radial_soft.png"))
    print("Created light_radial_soft.png")

def create_bandit_sheet():
    """
    Creates a 64x64 frame sheet for Bandit Raccoon.
    Rows:
      Row 0: Sneak (4 frames)
      Row 1: Walk (4 frames)
      Row 2: Sprint (4 frames)
      Row 3: Actions (Peek L, Peek R, Bonk, Caught)
    Total dimensions: 256 x 256 (4x4 grid of 64x64).
    """
    sheet = Image.new("RGBA", (256, 256), (0, 0, 0, 0))

    def draw_bandit_frame(draw, cx, cy, state, frame_idx):
        # Body colors
        coat_grey = (85, 95, 110, 255)
        belly_light = (195, 205, 215, 255)
        mask_black = (25, 25, 30, 255)
        ear_pink = (230, 150, 160, 255)
        eye_white = (255, 255, 255, 255)
        eye_pupil = (20, 20, 25, 255)
        outline = (15, 20, 30, 255)

        # Offsets for animation
        bob = 0
        tail_angle = 0
        paw_offset = 0

        if state == "sneak":
            bob = int(math.sin(frame_idx * math.pi) * 1.5)
            tail_angle = math.sin(frame_idx * math.pi / 2) * 15
            paw_offset = int(math.sin(frame_idx * math.pi / 2) * 3)
        elif state == "walk":
            bob = int(abs(math.sin(frame_idx * math.pi / 2)) * 3)
            tail_angle = math.sin(frame_idx * math.pi / 2) * 25
            paw_offset = int(math.sin(frame_idx * math.pi / 2) * 6)
        elif state == "sprint":
            bob = int(abs(math.sin(frame_idx * math.pi / 2)) * 5)
            tail_angle = math.sin(frame_idx * math.pi / 2) * 40
            paw_offset = int(math.sin(frame_idx * math.pi / 2) * 9)
        elif state == "caught":
            bob = -2

        # 1. Striped Bushy Tail (behind body, drawn at cx - 18, cy)
        tail_len = 22
        t_rad = math.radians(tail_angle + 180)
        tail_tip_x = cx + math.cos(t_rad) * tail_len
        tail_tip_y = cy + math.sin(t_rad) * tail_len + bob
        # Tail base to tip with alternating rings
        for i in range(5):
            t_frac = i / 4.0
            seg_x = cx - 10 + (tail_tip_x - (cx - 10)) * t_frac
            seg_y = cy + (tail_tip_y - cy) * t_frac
            ring_col = mask_black if (i % 2 == 0) else coat_grey
            r = int(7 * (1.0 - t_frac * 0.35))
            draw.ellipse([seg_x - r, seg_y - r, seg_x + r, seg_y + r], fill=ring_col, outline=outline, width=1)

        # 2. Paws / Feet (top-down view)
        paws = [
            (cx - 10 + paw_offset, cy + 14 - bob),
            (cx + 10 - paw_offset, cy + 14 + bob),
            (cx - 12 - paw_offset, cy - 8),
            (cx + 12 + paw_offset, cy - 8)
        ]
        for px, py in paws:
            draw.ellipse([px - 4, py - 4, px + 4, py + 4], fill=mask_black, outline=outline, width=1)

        # 3. Main Torso
        body_r = 15
        draw.ellipse([cx - body_r, cy - body_r + bob, cx + body_r, cy + body_r + bob], fill=coat_grey, outline=outline, width=2)
        # Belly patch
        draw.ellipse([cx - 8, cy - 10 + bob, cx + 8, cy + 10 + bob], fill=belly_light)

        # 4. Ears
        ear_l = [(cx - 14, cy - 12 + bob), (cx - 18, cy - 24 + bob), (cx - 6, cy - 16 + bob)]
        ear_r = [(cx + 14, cy - 12 + bob), (cx + 18, cy - 24 + bob), (cx + 6, cy - 16 + bob)]
        draw.polygon(ear_l, fill=coat_grey, outline=outline)
        draw.polygon(ear_r, fill=coat_grey, outline=outline)
        draw.polygon([(cx - 13, cy - 14 + bob), (cx - 16, cy - 21 + bob), (cx - 8, cy - 16 + bob)], fill=ear_pink)
        draw.polygon([(cx + 13, cy - 14 + bob), (cx + 16, cy - 21 + bob), (cx + 8, cy - 16 + bob)], fill=ear_pink)

        # 5. Head
        head_r = 13
        draw.ellipse([cx - head_r, cy - 18 + bob, cx + head_r, cy + 4 + bob], fill=coat_grey, outline=outline, width=2)

        # 6. Bandit Mask (Black band across eyes)
        draw.polygon([
            (cx - 14, cy - 12 + bob),
            (cx - 4, cy - 14 + bob),
            (cx, cy - 11 + bob),
            (cx + 4, cy - 14 + bob),
            (cx + 14, cy - 12 + bob),
            (cx + 11, cy - 4 + bob),
            (cx, cy - 6 + bob),
            (cx - 11, cy - 4 + bob)
        ], fill=mask_black, outline=outline)

        # 7. Eyes
        if state == "caught":
            # Comic X eyes
            for ex in [cx - 6, cx + 6]:
                draw.line([ex - 3, cy - 10 + bob, ex + 3, cy - 6 + bob], fill=(255, 60, 60, 255), width=2)
                draw.line([ex - 3, cy - 6 + bob, ex + 3, cy - 10 + bob], fill=(255, 60, 60, 255), width=2)
        else:
            draw.ellipse([cx - 8, cy - 11 + bob, cx - 4, cy - 7 + bob], fill=eye_white)
            draw.ellipse([cx + 4, cy - 11 + bob, cx + 8, cy - 7 + bob], fill=eye_white)
            draw.ellipse([cx - 7, cy - 10 + bob, cx - 5, cy - 8 + bob], fill=eye_pupil)
            draw.ellipse([cx + 5, cy - 10 + bob, cx + 7, cy - 8 + bob], fill=eye_pupil)
            # Glint
            draw.point((cx - 6, cy - 10 + bob), fill=(255, 255, 255, 255))
            draw.point((cx + 6, cy - 10 + bob), fill=(255, 255, 255, 255))

        # 8. Muzzle & Nose
        draw.ellipse([cx - 4, cy - 6 + bob, cx + 4, cy - 2 + bob], fill=belly_light)
        draw.polygon([(cx - 2, cy - 6 + bob), (cx + 2, cy - 6 + bob), (cx, cy - 4 + bob)], fill=mask_black)

    # Render each row
    states = ["sneak", "walk", "sprint"]
    for row, state in enumerate(states):
        for col in range(4):
            frame_img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
            draw = ImageDraw.Draw(frame_img)
            draw_bandit_frame(draw, 32, 32, state, col)
            sheet.paste(frame_img, (col * 64, row * 64))

    # Row 3: Special frames
    row = 3
    # Frame 0: Peek Left
    f0 = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d0 = ImageDraw.Draw(f0)
    draw_bandit_frame(d0, 26, 32, "sneak", 0)
    sheet.paste(f0, (0 * 64, row * 64))

    # Frame 1: Peek Right
    f1 = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d1 = ImageDraw.Draw(f1)
    draw_bandit_frame(d1, 38, 32, "sneak", 0)
    sheet.paste(f1, (1 * 64, row * 64))

    # Frame 2: Punch / Bonk
    f2 = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d2 = ImageDraw.Draw(f2)
    draw_bandit_frame(d2, 32, 32, "walk", 1)
    # Extra extended punching paw with motion swoosh
    d2.ellipse([46, 20, 58, 32], fill=(25, 25, 30, 255), outline=(255, 255, 255, 255), width=2)
    d2.arc([40, 14, 60, 38], start=270, end=90, fill=(255, 255, 100, 255), width=3)
    sheet.paste(f2, (2 * 64, row * 64))

    # Frame 3: Caught
    f3 = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d3 = ImageDraw.Draw(f3)
    draw_bandit_frame(d3, 32, 32, "caught", 0)
    # Surrender paws raised
    d3.ellipse([14, 10, 22, 18], fill=(25, 25, 30, 255), outline=(15, 20, 30, 255), width=1)
    d3.ellipse([42, 10, 50, 18], fill=(25, 25, 30, 255), outline=(15, 20, 30, 255), width=1)
    sheet.paste(f3, (3 * 64, row * 64))

    sheet.save(os.path.join(SPRITES_DIR, "bandit_sheet.png"))
    print("Created bandit_sheet.png")

def create_loot_bags():
    """Generates bag_light.png, bag_medium.png, bag_heavy.png."""
    # 64x64 overlays centered to bandit's back
    for name, r_x, r_y, coins, color in [
        ("bag_light.png", 7, 7, 1, (180, 130, 80, 255)),
        ("bag_medium.png", 11, 10, 3, (190, 140, 75, 255)),
        ("bag_heavy.png", 15, 13, 6, (200, 145, 60, 255))
    ]:
        img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        cx, cy = 32, 42
        # Outline
        draw.ellipse([cx - r_x - 2, cy - r_y - 2, cx + r_x + 2, cy + r_y + 2], fill=(20, 15, 10, 255))
        # Bag body
        draw.ellipse([cx - r_x, cy - r_y, cx + r_x, cy + r_y], fill=color)
        # Tie knot
        draw.polygon([(cx - 4, cy - r_y - 2), (cx + 4, cy - r_y - 2), (cx, cy - r_y + 3)], fill=(230, 180, 110, 255))
        # Gold coins popping out
        for c in range(coins):
            co_x = cx - r_x + 5 + (c * 5) % (r_x * 2)
            co_y = cy - r_y + 1 + (c * 3) % 6
            draw.ellipse([co_x - 3, co_y - 3, co_x + 3, co_y + 3], fill=(255, 215, 0, 255), outline=(140, 100, 0, 255))
        img.save(os.path.join(SPRITES_DIR, name))
        print(f"Created {name}")

def create_guards():
    """Generates all 6 police guard archetypes as 64x64 multi-frame sheets."""
    guard_configs = [
        ("guard_rookie.png", (35, 60, 120), (25, 45, 95), "rookie"),
        ("guard_veteran.png", (45, 75, 130), (180, 150, 40), "veteran"),
        ("guard_radio.png", (30, 70, 110), (0, 220, 220), "radio"),
        ("guard_k9.png", (140, 90, 50), (200, 40, 40), "k9"),
        ("guard_heavy.png", (60, 65, 75), (220, 60, 60), "heavy"),
        ("guard_drone.png", (50, 55, 65), (0, 255, 150), "drone")
    ]

    for filename, primary_col, accent_col, role in guard_configs:
        sheet = Image.new("RGBA", (256, 64), (0, 0, 0, 0)) # 4 frames: idle, walk1, idle, walk2
        for frame in range(4):
            f_img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
            draw = ImageDraw.Draw(f_img)
            cx, cy = 32, 32
            outline = (15, 20, 30, 255)
            bob = int(math.sin(frame * math.pi) * 2) if frame % 2 != 0 else 0
            foot_shift = int(math.sin(frame * math.pi / 2) * 5)

            if role == "drone":
                # Quad-rotor Drone
                # Shadow
                draw.ellipse([cx - 18, cy + 12, cx + 18, cy + 24], fill=(0, 0, 0, 70))
                # 4 rotor arms
                d_bob = int(math.sin(frame * math.pi) * 2)
                draw.line([cx - 18, cy - 18 + d_bob, cx + 18, cy + 18 + d_bob], fill=(100, 110, 120, 255), width=3)
                draw.line([cx - 18, cy + 18 + d_bob, cx + 18, cy - 18 + d_bob], fill=(100, 110, 120, 255), width=3)
                # Spinning blades (circles)
                for rx, ry in [(-18, -18), (18, -18), (-18, 18), (18, 18)]:
                    blade_col = (180, 230, 255, 160) if (frame % 2 == 0) else (220, 245, 255, 180)
                    draw.ellipse([cx + rx - 8, cy + ry + d_bob - 4, cx + rx + 8, cy + ry + d_bob + 4], outline=blade_col, width=2)
                # Central chassis
                draw.ellipse([cx - 12, cy - 12 + d_bob, cx + 12, cy + 12 + d_bob], fill=(40, 45, 55, 255), outline=outline, width=2)
                # Glowing lens
                draw.ellipse([cx - 6, cy - 6 + d_bob, cx + 6, cy + 6 + d_bob], fill=accent_col)
                draw.ellipse([cx - 2, cy - 2 + d_bob, cx + 2, cy + 2 + d_bob], fill=(255, 255, 255, 255))

            elif role == "k9":
                # Police Dog
                # Tail
                tail_wag = math.sin(frame * math.pi) * 12
                draw.line([cx - 16, cy, cx - 26, cy + tail_wag], fill=primary_col, width=4)
                # Paws
                draw.ellipse([cx - 10 + foot_shift, cy - 10, cx - 4 + foot_shift, cy - 4], fill=(50, 30, 15, 255))
                draw.ellipse([cx - 10 - foot_shift, cy + 4, cx - 4 - foot_shift, cy + 10], fill=(50, 30, 15, 255))
                draw.ellipse([cx + 10 + foot_shift, cy - 10, cx + 16 + foot_shift, cy - 4], fill=(50, 30, 15, 255))
                draw.ellipse([cx + 10 - foot_shift, cy + 4, cx + 16 - foot_shift, cy + 10], fill=(50, 30, 15, 255))
                # Body
                draw.ellipse([cx - 15, cy - 8 + bob, cx + 12, cy + 8 + bob], fill=primary_col, outline=outline, width=2)
                # Vest / Collar
                draw.rectangle([cx - 4, cy - 8 + bob, cx + 4, cy + 8 + bob], fill=accent_col, outline=outline)
                # Head
                draw.ellipse([cx + 6, cy - 7 + bob, cx + 20, cy + 7 + bob], fill=primary_col, outline=outline, width=2)
                # Snout
                draw.polygon([(cx + 16, cy - 4 + bob), (cx + 25, cy + bob), (cx + 16, cy + 4 + bob)], fill=(40, 25, 15, 255))
                # Scent trail icon for K9
                draw.ellipse([cx + 26, cy - 2 + bob, cx + 30, cy + 2 + bob], fill=(255, 180, 0, 180))

            else:
                # Humanoid Top-down Guard
                # Boots / Feet
                draw.ellipse([cx - 10, cy + 8 - foot_shift, cx - 2, cy + 18 - foot_shift], fill=(20, 20, 25, 255))
                draw.ellipse([cx + 2, cy + 8 + foot_shift, cx + 10, cy + 18 + foot_shift], fill=(20, 20, 25, 255))
                # Shoulders / Torso
                sh_w = 18 if role != "heavy" else 24
                sh_h = 13 if role != "heavy" else 17
                draw.ellipse([cx - sh_w, cy - sh_h + bob, cx + sh_w, cy + sh_h + bob], fill=primary_col, outline=outline, width=2)

                # Special attachments
                if role == "heavy":
                    # Riot shoulder pauldrons
                    draw.rectangle([cx - 22, cy - 12 + bob, cx - 14, cy + 8 + bob], fill=(120, 125, 135, 255), outline=outline)
                    draw.rectangle([cx + 14, cy - 12 + bob, cx + 22, cy + 8 + bob], fill=(120, 125, 135, 255), outline=outline)
                elif role == "radio":
                    # Radio backpack & antenna
                    draw.rectangle([cx - 6, cy + 8 + bob, cx + 6, cy + 16 + bob], fill=(20, 30, 40, 255), outline=outline)
                    draw.line([cx + 4, cy + 12 + bob, cx + 14, cy + 24 + bob], fill=(180, 190, 200, 255), width=2)
                    draw.ellipse([cx + 13, cy + 23 + bob, cx + 17, cy + 27 + bob], fill=accent_col) # Glowing tip

                # Head / Hat
                head_r = 11
                draw.ellipse([cx - head_r, cy - 12 + bob, cx + head_r, cy + 8 + bob], fill=primary_col, outline=outline, width=2)

                # Cap Visor facing down/forward
                draw.arc([cx - head_r, cy - 4 + bob, cx + head_r, cy + 12 + bob], start=0, end=180, fill=(20, 20, 25, 255), width=3)

                # Role specific Hat insignia
                if role == "veteran":
                    # Gold chevron
                    draw.polygon([(cx - 4, cy - 2 + bob), (cx + 4, cy - 2 + bob), (cx, cy + 3 + bob)], fill=accent_col)
                elif role == "heavy":
                    # Reinforced Visor slot
                    draw.line([cx - 6, cy + 4 + bob, cx + 6, cy + 4 + bob], fill=accent_col, width=2)

                # Flashlight in hand (right hand facing forward)
                fl_x, fl_y = cx + 14, cy + 4 + bob
                draw.ellipse([fl_x - 3, fl_y - 3, fl_x + 3, fl_y + 3], fill=(80, 85, 95, 255), outline=outline)
                draw.ellipse([fl_x - 2, fl_y + 2, fl_x + 2, fl_y + 6], fill=(255, 250, 180, 255)) # Bulb

            sheet.paste(f_img, (frame * 64, 0))

        sheet.save(os.path.join(SPRITES_DIR, filename))
        print(f"Created {filename}")

def create_tileset_blueprint():
    """
    Creates tileset_blueprint.png with living blueprint aesthetic:
    Grid base 64x64:
      Col 0: Navy Blueprint Floor (grid lines)
      Col 1: Creaky Wood Floor
      Col 2: Glass Floor Hazard
      Col 3: Solid Wall / Center
      Col 4: Horiz Double Wall
      Col 5: Vert Double Wall
      Col 6: Corner Top-Left
      Col 7: Corner Top-Right
    Width: 512, Height: 64.
    """
    tiles = Image.new("RGBA", (512, 64), (0, 0, 0, 0))

    # Tile 0: Navy Blueprint Floor
    t0 = Image.new("RGBA", (64, 64), (18, 38, 63, 255))
    d0 = ImageDraw.Draw(t0)
    # Subtle 16x16 blueprint sub-grid lines
    for i in range(0, 64, 16):
        d0.line([i, 0, i, 64], fill=(28, 55, 90, 255), width=1)
        d0.line([0, i, 64, i], fill=(28, 55, 90, 255), width=1)
    # Architectural cross ticks at corners
    for px, py in [(8, 8), (56, 8), (8, 56), (56, 56)]:
        d0.line([px - 3, py, px + 3, py], fill=(45, 90, 140, 255), width=1)
        d0.line([px, py - 3, px, py + 3], fill=(45, 90, 140, 255), width=1)
    tiles.paste(t0, (0 * 64, 0))

    # Tile 1: Creaky Wood Floor
    t1 = t0.copy()
    d1 = ImageDraw.Draw(t1)
    for y in [16, 32, 48]:
        d1.line([0, y, 64, y], fill=(120, 80, 45, 180), width=2)
    # Nails
    for x, y in [(12, 16), (48, 16), (24, 32), (56, 32), (16, 48), (44, 48)]:
        d1.point((x, y), fill=(200, 180, 150, 255))
    tiles.paste(t1, (1 * 64, 0))

    # Tile 2: Glass Floor Hazard
    t2 = t0.copy()
    d2 = ImageDraw.Draw(t2)
    shards = [
        [(15, 20), (28, 14), (22, 30)],
        [(35, 25), (48, 32), (40, 45)],
        [(18, 42), (30, 48), (25, 55)],
        [(45, 12), (55, 18), (50, 26)]
    ]
    for s in shards:
        d2.polygon(s, fill=(180, 240, 255, 180), outline=(255, 255, 255, 240))
    tiles.paste(t2, (2 * 64, 0))

    # Tile 3: Solid Wall Center
    t3 = Image.new("RGBA", (64, 64), (10, 20, 35, 255))
    d3 = ImageDraw.Draw(t3)
    # Cross hatching blueprint interior
    for i in range(-64, 128, 12):
        d3.line([i, 0, i + 64, 64], fill=(22, 45, 75, 255), width=1)
    tiles.paste(t3, (3 * 64, 0))

    # Tile 4: Horizontal Wall (Double Cyan lines)
    t4 = t3.copy()
    d4 = ImageDraw.Draw(t4)
    cyan_line = (0, 230, 255, 255)
    d4.line([0, 12, 64, 12], fill=cyan_line, width=3)
    d4.line([0, 52, 64, 52], fill=cyan_line, width=3)
    tiles.paste(t4, (4 * 64, 0))

    # Tile 5: Vertical Wall (Double Cyan lines)
    t5 = t3.copy()
    d5 = ImageDraw.Draw(t5)
    d5.line([12, 0, 12, 64], fill=cyan_line, width=3)
    d5.line([52, 0, 52, 64], fill=cyan_line, width=3)
    tiles.paste(t5, (5 * 64, 0))

    # Tile 6: Corner Top-Left
    t6 = t3.copy()
    d6 = ImageDraw.Draw(t6)
    d6.line([12, 12, 64, 12], fill=cyan_line, width=3)
    d6.line([12, 12, 12, 64], fill=cyan_line, width=3)
    d6.line([52, 52, 64, 52], fill=cyan_line, width=3)
    d6.line([52, 52, 52, 64], fill=cyan_line, width=3)
    tiles.paste(t6, (6 * 64, 0))

    # Tile 7: Corner Top-Right
    t7 = t3.copy()
    d7 = ImageDraw.Draw(t7)
    d7.line([0, 12, 52, 12], fill=cyan_line, width=3)
    d7.line([52, 12, 52, 64], fill=cyan_line, width=3)
    d7.line([0, 52, 12, 52], fill=cyan_line, width=3)
    d7.line([12, 52, 12, 64], fill=cyan_line, width=3)
    tiles.paste(t7, (7 * 64, 0))

    tiles.save(os.path.join(SPRITES_DIR, "tileset_blueprint.png"))
    print("Created tileset_blueprint.png")

def create_interactive_props():
    """Generates shutter_door, vent_grate, master_key, coins, gems, lockers, etc."""

    # 1. Shutter Door (192 x 64: 3 frames: Open, Midway, Closed)
    shutter = Image.new("RGBA", (192, 64), (0, 0, 0, 0))
    # Frame 0: Open floor hazard strip
    f0 = Image.new("RGBA", (64, 64), (18, 38, 63, 255))
    d0 = ImageDraw.Draw(f0)
    for x in range(0, 64, 16):
        d0.polygon([(x, 24), (x + 8, 24), (x, 40), (x - 8, 40)], fill=(230, 180, 30, 200))
    d0.rectangle([0, 22, 64, 24], fill=(60, 60, 70, 255))
    d0.rectangle([0, 40, 64, 42], fill=(60, 60, 70, 255))
    shutter.paste(f0, (0, 0))

    # Frame 1: Midway closing
    f1 = f0.copy()
    d1 = ImageDraw.Draw(f1)
    d1.rectangle([0, 20, 64, 32], fill=(80, 85, 95, 255), outline=(20, 20, 25, 255), width=2)
    shutter.paste(f1, (64, 0))

    # Frame 2: Heavy Steel Blast Door with bold red hazard stripes
    f2 = Image.new("RGBA", (64, 64), (70, 75, 85, 255))
    d2 = ImageDraw.Draw(f2)
    d2.rectangle([0, 0, 64, 64], outline=(20, 20, 25, 255), width=4)
    # Red & White/Yellow Hazard stripes
    for x in range(-64, 128, 20):
        d2.polygon([(x, 0), (x + 10, 0), (x + 30, 64), (x + 20, 64)], fill=(220, 40, 50, 255))
    # Central mechanical lock latch
    d2.ellipse([24, 24, 40, 40], fill=(40, 45, 50, 255), outline=(255, 60, 60, 255), width=2)
    d2.line([28, 32, 36, 32], fill=(255, 255, 255, 255), width=2)
    shutter.paste(f2, (128, 0))
    shutter.save(os.path.join(SPRITES_DIR, "shutter_door.png"))
    print("Created shutter_door.png")

    # 2. Vent Grate (128 x 64: 2 frames: Closed Grate, Open Glowing Raccoon Vent)
    vent = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    # Frame 0: Sealed floor grate
    v0 = Image.new("RGBA", (64, 64), (40, 45, 55, 255))
    dv0 = ImageDraw.Draw(v0)
    dv0.rectangle([4, 4, 60, 60], outline=(20, 20, 25, 255), width=3)
    for x in range(12, 54, 8):
        dv0.line([x, 8, x, 56], fill=(20, 20, 25, 255), width=3)
    # Screws
    for px, py in [(8, 8), (56, 8), (8, 56), (56, 56)]:
        dv0.ellipse([px - 2, py - 2, px + 2, py + 2], fill=(180, 190, 200, 255))
    vent.paste(v0, (0, 0))

    # Frame 1: Open Green-lit Raccoon Vent
    v1 = Image.new("RGBA", (64, 64), (10, 35, 20, 255))
    dv1 = ImageDraw.Draw(v1)
    dv1.rectangle([4, 4, 60, 60], outline=(0, 230, 120, 255), width=3)
    # Neon green glow & shaft depth
    for r in range(24, 4, -4):
        alpha = int(255 * (1.0 - r / 24.0))
        dv1.ellipse([32 - r, 32 - r, 32 + r, 32 + r], outline=(0, 255, 140, alpha), width=2)
    # Spinning fan blades silhouette
    dv1.line([20, 20, 44, 44], fill=(0, 200, 100, 200), width=4)
    dv1.line([20, 44, 44, 20], fill=(0, 200, 100, 200), width=4)
    vent.paste(v1, (64, 0))
    vent.save(os.path.join(SPRITES_DIR, "vent_grate.png"))
    print("Created vent_grate.png")

    # 3. Master Key (64x64 glowing skeleton key)
    key = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    dk = ImageDraw.Draw(key)
    # Glow ring
    dk.ellipse([10, 10, 54, 54], outline=(255, 220, 50, 100), width=6)
    # Gold key shaft
    gold = (255, 215, 0, 255)
    gold_border = (160, 120, 0, 255)
    dk.line([22, 42, 46, 18], fill=gold, width=6)
    # Head ring
    dk.ellipse([12, 34, 30, 52], outline=gold, width=5)
    dk.ellipse([17, 39, 25, 47], fill=(0, 230, 255, 255)) # Glowing cyan gem
    # Key teeth
    dk.line([42, 22, 48, 28], fill=gold, width=4)
    dk.line([46, 18, 52, 24], fill=gold, width=4)
    key.save(os.path.join(SPRITES_DIR, "master_key.png"))
    print("Created master_key.png")

    # 4. Gold Coin (32x32)
    coin = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    dc = ImageDraw.Draw(coin)
    dc.ellipse([2, 2, 30, 30], fill=gold, outline=gold_border, width=2)
    dc.ellipse([6, 6, 26, 26], outline=(255, 240, 120, 255), width=2)
    # Star emblem
    dc.polygon([(16, 8), (18, 14), (24, 16), (18, 18), (16, 24), (14, 18), (8, 16), (14, 14)], fill=(255, 250, 200, 255))
    coin.save(os.path.join(SPRITES_DIR, "coin_gold.png"))
    print("Created coin_gold.png")

    # 5. Treasure Gem (32x32)
    gem = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    dg = ImageDraw.Draw(gem)
    emerald = (0, 230, 150, 255)
    dg.polygon([(16, 4), (27, 12), (22, 28), (10, 28), (5, 12)], fill=emerald, outline=(0, 100, 60, 255), width=2)
    dg.polygon([(16, 4), (20, 12), (16, 28), (12, 12)], fill=(120, 255, 200, 200))
    gem.save(os.path.join(SPRITES_DIR, "treasure_gem.png"))
    print("Created treasure_gem.png")

    # 6. Exit Vault Door (128x64: Frame 0 Locked Red, Frame 1 Unlocked Emerald)
    vault = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    # Frame 0: Locked
    v_l = Image.new("RGBA", (64, 64), (40, 45, 55, 255))
    dvl = ImageDraw.Draw(v_l)
    dvl.rectangle([0, 0, 64, 64], outline=(20, 20, 25, 255), width=4)
    dvl.ellipse([14, 14, 50, 50], fill=(60, 65, 75, 255), outline=(220, 40, 40, 255), width=4)
    # Heavy lock wheel spokes
    for a in range(0, 360, 45):
        rad = math.radians(a)
        dvl.line([32, 32, 32 + math.cos(rad) * 16, 32 + math.sin(rad) * 16], fill=(200, 210, 220, 255), width=3)
    dvl.ellipse([28, 28, 36, 36], fill=(220, 40, 40, 255))
    vault.paste(v_l, (0, 0))

    # Frame 1: Unlocked Moonlight Escape
    v_u = Image.new("RGBA", (64, 64), (10, 40, 30, 255))
    dvu = ImageDraw.Draw(v_u)
    dvu.rectangle([0, 0, 64, 64], outline=(0, 230, 120, 255), width=4)
    # Open doorway stairs receding
    dvu.rectangle([14, 8, 50, 56], fill=(15, 25, 45, 255))
    for y in range(16, 56, 8):
        dvu.line([14, y, 50, y], fill=(100, 180, 220, 255), width=2)
    # Glowing EXIT arrow
    dvu.polygon([(32, 14), (42, 24), (36, 24), (36, 36), (28, 36), (28, 24), (22, 24)], fill=(0, 255, 140, 255))
    vault.paste(v_u, (64, 0))
    vault.save(os.path.join(SPRITES_DIR, "exit_vault_door.png"))
    print("Created exit_vault_door.png")

    # 7. Entry Hatch (64x64)
    hatch = Image.new("RGBA", (64, 64), (18, 38, 63, 255))
    dh = ImageDraw.Draw(hatch)
    dh.rectangle([8, 8, 56, 56], fill=(10, 15, 25, 255), outline=(0, 200, 255, 255), width=3)
    dh.line([12, 12, 52, 52], fill=(0, 150, 200, 200), width=2)
    dh.line([12, 52, 52, 12], fill=(0, 150, 200, 200), width=2)
    hatch.save(os.path.join(SPRITES_DIR, "entry_hatch.png"))
    print("Created entry_hatch.png")

    # 8. Locker Hideout (64x64)
    locker = Image.new("RGBA", (64, 64), (55, 65, 80, 255))
    dl = ImageDraw.Draw(locker)
    dl.rectangle([4, 4, 60, 60], outline=(20, 25, 35, 255), width=3)
    # Vent louvers
    for y in [12, 18, 24, 30]:
        dl.line([16, y, 48, y], fill=(20, 25, 35, 255), width=2)
    # Handle & peek crack
    dl.rectangle([48, 34, 52, 44], fill=(200, 210, 220, 255))
    dl.line([10, 36, 44, 36], fill=(0, 255, 180, 180), width=2) # Green hideout peek crack
    locker.save(os.path.join(SPRITES_DIR, "locker_hideout.png"))
    print("Created locker_hideout.png")

    # 9. Fuse Box (64x64)
    fuse = Image.new("RGBA", (64, 64), (45, 50, 60, 255))
    df = ImageDraw.Draw(fuse)
    df.rectangle([10, 8, 54, 56], fill=(70, 75, 85, 255), outline=(20, 20, 25, 255), width=3)
    # Warning thunderbolt
    df.polygon([(34, 14), (24, 32), (32, 32), (30, 48), (42, 28), (34, 28)], fill=(255, 220, 0, 255))
    fuse.save(os.path.join(SPRITES_DIR, "fuse_box.png"))
    print("Created fuse_box.png")

    # 10. Zip-tie Cuff (64x64)
    cuff = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    dcu = ImageDraw.Draw(cuff)
    yellow = (255, 230, 40, 255)
    dcu.ellipse([8, 16, 32, 48], outline=yellow, width=4)
    dcu.ellipse([32, 16, 56, 48], outline=yellow, width=4)
    dcu.rectangle([28, 28, 36, 36], fill=(220, 180, 20, 255)) # Ratchet block
    cuff.save(os.path.join(SPRITES_DIR, "ziptie_cuff.png"))
    print("Created ziptie_cuff.png")

def create_ui_assets():
    """Generates stars, ribbons, portraits, input prompts, and mobile controls."""

    # 1. Stars (48x48)
    for name, fill_col in [("star_filled.png", (255, 215, 0, 255)), ("star_empty.png", (80, 90, 110, 150))]:
        star = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
        ds = ImageDraw.Draw(star)
        cx, cy = 24, 24
        points = []
        for i in range(10):
            r = 20 if (i % 2 == 0) else 8
            ang = math.radians(i * 36 - 90)
            points.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
        ds.polygon(points, fill=fill_col, outline=(30, 30, 40, 255), width=2)
        star.save(os.path.join(UI_DIR, name))

    # 2. Ribbons (64x64)
    # Ghost Ribbon (Cyan)
    ghost = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    dg = ImageDraw.Draw(ghost)
    dg.polygon([(16, 8), (48, 8), (56, 40), (48, 56), (32, 44), (16, 56), (8, 40)], fill=(0, 220, 255, 255), outline=(10, 30, 50, 255), width=2)
    # Ghost mask icon
    dg.ellipse([24, 18, 40, 34], fill=(255, 255, 255, 255))
    dg.ellipse([27, 22, 31, 26], fill=(10, 30, 50, 255))
    dg.ellipse([33, 22, 37, 26], fill=(10, 30, 50, 255))
    ghost.save(os.path.join(UI_DIR, "ribbon_ghost.png"))

    # Clean Sweep Ribbon (Gold)
    sweep = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    dsw = ImageDraw.Draw(sweep)
    dsw.polygon([(16, 8), (48, 8), (56, 40), (48, 56), (32, 44), (16, 56), (8, 40)], fill=(255, 200, 40, 255), outline=(60, 40, 0, 255), width=2)
    dsw.ellipse([22, 16, 42, 36], fill=(255, 240, 120, 255))
    sweep.save(os.path.join(UI_DIR, "ribbon_cleansweep.png"))

    # 3. Bandit Portrait (96x96)
    p_b = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    dpb = ImageDraw.Draw(p_b)
    # Outer frame
    dpb.ellipse([4, 4, 92, 92], fill=(25, 45, 75, 255), outline=(0, 230, 255, 255), width=4)
    # Raccoon head
    dpb.ellipse([20, 24, 76, 80], fill=(85, 95, 110, 255), outline=(15, 20, 30, 255), width=2)
    # Ears
    dpb.polygon([(18, 26), (12, 10), (32, 18)], fill=(85, 95, 110, 255), outline=(15, 20, 30, 255))
    dpb.polygon([(78, 26), (84, 10), (64, 18)], fill=(85, 95, 110, 255), outline=(15, 20, 30, 255))
    # Mask
    dpb.polygon([(22, 38), (48, 42), (74, 38), (70, 54), (48, 50), (26, 54)], fill=(25, 25, 30, 255))
    # Eyes & Glint
    dpb.ellipse([32, 40, 42, 50], fill=(255, 255, 255, 255))
    dpb.ellipse([54, 40, 64, 50], fill=(255, 255, 255, 255))
    dpb.ellipse([35, 42, 41, 48], fill=(20, 20, 25, 255))
    dpb.ellipse([57, 42, 63, 48], fill=(20, 20, 25, 255))
    # Smug smile
    dpb.arc([40, 56, 56, 68], start=20, end=160, fill=(25, 25, 30, 255), width=3)
    p_b.save(os.path.join(UI_DIR, "portrait_bandit.png"))

    # 4. Input Prompts (32x32 / 48x48 rounded badges)
    prompts = [
        ("prompt_wasd.png", "WASD", (60, 70, 85, 255)),
        ("prompt_e.png", "E", (0, 180, 220, 255)),
        ("prompt_shift.png", "SHIFT", (220, 100, 40, 255)),
        ("prompt_q.png", "Q", (240, 200, 50, 255)),
        ("prompt_f.png", "F", (180, 80, 220, 255)),
        ("prompt_esc.png", "ESC", (90, 95, 105, 255)),
        ("prompt_btn_a.png", "A", (40, 200, 80, 255)),
        ("prompt_btn_x.png", "X", (50, 120, 240, 255)),
        ("prompt_btn_rb.png", "RB", (100, 110, 125, 255)),
        ("prompt_btn_rt.png", "RT", (220, 60, 60, 255)),
        ("prompt_btn_start.png", "START", (80, 85, 95, 255))
    ]

    for filename, label, bg_col in prompts:
        w = 48 if len(label) > 2 else 32
        h = 32
        p_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        dp = ImageDraw.Draw(p_img)
        dp.rounded_rectangle([2, 2, w - 2, h - 2], radius=6, fill=bg_col, outline=(255, 255, 255, 220), width=2)
        # Simple letter lines
        dp.text((w // 2 - len(label) * 4, h // 2 - 6), label, fill=(255, 255, 255, 255))
        p_img.save(os.path.join(UI_DIR, filename))

    # 5. Mobile On-Screen Controls
    # Joystick Ring (128x128)
    j_ring = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    djr = ImageDraw.Draw(j_ring)
    djr.ellipse([6, 6, 122, 122], fill=(20, 40, 60, 80), outline=(0, 220, 255, 180), width=4)
    djr.ellipse([58, 58, 70, 70], fill=(0, 220, 255, 120))
    j_ring.save(os.path.join(UI_DIR, "touch_joystick_ring.png"))

    # Joystick Knob (64x64)
    j_knob = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    djk = ImageDraw.Draw(j_knob)
    djk.ellipse([4, 4, 60, 60], fill=(0, 200, 255, 200), outline=(255, 255, 255, 240), width=3)
    j_knob.save(os.path.join(UI_DIR, "touch_joystick_knob.png"))

    # Action Buttons (72x72)
    btns = [
        ("touch_action.png", (0, 220, 255, 200), "E"),
        ("touch_coin.png", (255, 215, 0, 200), "$"),
        ("touch_sneak.png", (140, 160, 190, 200), "SNK"),
        ("touch_gadget.png", (220, 100, 240, 200), "GAD")
    ]
    for bname, col, txt in btns:
        b_img = Image.new("RGBA", (72, 72), (0, 0, 0, 0))
        db = ImageDraw.Draw(b_img)
        db.ellipse([4, 4, 68, 68], fill=col, outline=(255, 255, 255, 240), width=3)
        db.text((36 - len(txt) * 5, 28), txt, fill=(20, 25, 35, 255))
        b_img.save(os.path.join(UI_DIR, bname))

    print("Created UI Badges, Prompts and Touch Controls")

# -------------------------------------------------------------
# 2. AUDIO SYNTHESIS ENGINE (16-BIT 44.1kHz WAV)
# -------------------------------------------------------------

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    """Writes a list/array of float samples [-1.0, 1.0] to a 16-bit mono WAV file."""
    with wave.open(filename, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        raw_bytes = bytearray()
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            ival = int(clamped * 32767)
            raw_bytes.extend(struct.pack("<h", ival))
        wf.writeframes(raw_bytes)

def generate_sound_effects():
    """Generates all 20 procedural SFX files in assets/audio/sfx/."""

    # 1. coin_pickup.wav (Dual-tone cheerful chime)
    samples = []
    dur = 0.25
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-12.0 * t)
        freq = 1320.0 if t < 0.1 else 1760.0
        s = math.sin(2 * math.pi * freq * t) * env * 0.6
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "coin_pickup.wav"), samples)

    # 2. coin_toss_clink.wav (Metallic ping with bounce)
    samples = []
    dur = 0.4
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env1 = math.exp(-22.0 * t)
        # Metallic overtone stack: 2400Hz, 3720Hz, 5100Hz
        s = (math.sin(2 * math.pi * 2400 * t) * 0.5 +
             math.sin(2 * math.pi * 3720 * t) * 0.3 +
             math.sin(2 * math.pi * 5100 * t) * 0.2) * env1
        # Secondary bounce clink at 0.12s
        if t > 0.12:
            t2 = t - 0.12
            env2 = math.exp(-30.0 * t2) * 0.4
            s += math.sin(2 * math.pi * 2800 * t2) * env2
        samples.append(s * 0.7)
    write_wav(os.path.join(SFX_DIR, "coin_toss_clink.wav"), samples)

    # 3. loot_bag_jingle.wav (Cluster of coins)
    samples = []
    dur = 0.35
    n_samples = int(SAMPLE_RATE * dur)
    offsets = [0.0, 0.05, 0.09, 0.15, 0.22]
    freqs = [1900, 2300, 2100, 2600, 2200]
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        for off, f in zip(offsets, freqs):
            if t >= off:
                dt = t - off
                val += math.sin(2 * math.pi * f * dt) * math.exp(-25.0 * dt) * 0.25
        samples.append(val)
    write_wav(os.path.join(SFX_DIR, "loot_bag_jingle.wav"), samples)

    # 4. footstep_soft.wav (Sneak/Walk step)
    samples = []
    dur = 0.14
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-35.0 * t)
        freq = 90 - (t / dur) * 30
        noise = (random.random() * 2.0 - 1.0) * 0.15
        s = (math.sin(2 * math.pi * freq * t) + noise) * env * 0.5
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "footstep_soft.wav"), samples)

    # 5. footstep_creak.wav (Wood creak)
    samples = []
    dur = 0.3
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / dur)) ** 1.5
        freq = 320 + math.sin(2 * math.pi * 25 * t) * 80
        s = math.sin(2 * math.pi * freq * t) * env * 0.4
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "footstep_creak.wav"), samples)

    # 6. knockout_bonk.wav (Comic pitch-drop bonk)
    samples = []
    dur = 0.35
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-14.0 * t)
        freq = 850.0 * math.exp(-8.0 * t) + 120.0
        s = (math.sin(2 * math.pi * freq * t) * 0.8 +
             (random.random() * 2.0 - 1.0) * math.exp(-40.0 * t) * 0.4) * env
        samples.append(s * 0.8)
    write_wav(os.path.join(SFX_DIR, "knockout_bonk.wav"), samples)

    # 7. ziptie_ratchet.wav (Multiple rapid teeth clicks)
    samples = []
    dur = 0.45
    n_samples = int(SAMPLE_RATE * dur)
    clicks = [0.04 * k for k in range(9)]
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        for c in clicks:
            if t >= c:
                dt = t - c
                val += (random.random() * 2.0 - 1.0) * math.exp(-80.0 * dt) * 0.3
                val += math.sin(2 * math.pi * 3200 * dt) * math.exp(-60.0 * dt) * 0.2
        samples.append(val)
    write_wav(os.path.join(SFX_DIR, "ziptie_ratchet.wav"), samples)

    # 8. pickpocket_zip.wav
    samples = []
    dur = 0.28
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / dur))
        freq = 600.0 + (t / dur) * 1400.0
        s = math.sin(2 * math.pi * freq * t) * env * 0.5
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "pickpocket_zip.wav"), samples)

    # 9. guard_snore.wav (Low gentle buzz)
    samples = []
    dur = 1.2
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / dur)) ** 2.0
        s = (math.sin(2 * math.pi * 75 * t) +
             math.sin(2 * math.pi * 150 * t) * 0.4 +
             math.sin(2 * math.pi * 225 * t) * 0.2) * env * 0.4
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "guard_snore.wav"), samples)

    # 10. suspicion_hm.wav (Curious questioning 'Mm?')
    samples = []
    dur = 0.32
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / dur))
        freq = 240.0 + (t / dur) * 180.0
        s = math.sin(2 * math.pi * freq * t) * env * 0.5
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "suspicion_hm.wav"), samples)

    # 11. spotted_sting.wav (Dramatic alert hit '!')
    samples = []
    dur = 0.6
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-6.0 * t)
        # Minor second dissonant brass stab (980Hz + 1040Hz)
        s = (math.sin(2 * math.pi * 980 * t) * 0.5 +
             math.sin(2 * math.pi * 1040 * t) * 0.5 +
             (random.random() * 2.0 - 1.0) * math.exp(-30.0 * t) * 0.3) * env * 0.8
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "spotted_sting.wav"), samples)

    # 12. lockdown_siren.wav (Two-tone siren loop)
    samples = []
    dur = 1.6
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        freq = 700 + math.sin(2 * math.pi * 1.5 * t) * 180
        s = math.sin(2 * math.pi * freq * t) * 0.45
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "lockdown_siren.wav"), samples)

    # 13. shutter_slam.wav (Heavy blast door slam)
    samples = []
    dur = 0.8
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Pre-slam mechanical hiss (0 - 0.2s)
        hiss = (random.random() * 2.0 - 1.0) * (0.2 - t) * 2.0 if t < 0.2 else 0.0
        # Impact at 0.2s
        impact = 0.0
        if t >= 0.2:
            dt = t - 0.2
            impact = (math.sin(2 * math.pi * 55 * dt) * 0.8 +
                      (random.random() * 2.0 - 1.0) * 0.5) * math.exp(-8.0 * dt)
        samples.append((hiss + impact) * 0.8)
    write_wav(os.path.join(SFX_DIR, "shutter_slam.wav"), samples)

    # 14. vent_open.wav (Light metal pop)
    samples = []
    dur = 0.25
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        s = math.sin(2 * math.pi * 520 * t) * math.exp(-20.0 * t) * 0.6
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "vent_open.wav"), samples)

    # 15. transponder_ping.wav (Sonar radar blip)
    samples = []
    dur = 0.7
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-7.0 * t)
        freq = 1500.0 * math.exp(-4.0 * t) + 800.0
        s = math.sin(2 * math.pi * freq * t) * env * 0.6
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "transponder_ping.wav"), samples)

    # 16. heartbeat_pulse.wav (Subwoofer thump lub-dub)
    samples = []
    dur = 0.6
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        s1 = math.sin(2 * math.pi * 65 * t) * math.exp(-25.0 * t) if t < 0.2 else 0.0
        s2 = math.sin(2 * math.pi * 55 * (t - 0.18)) * math.exp(-22.0 * (t - 0.18)) if t >= 0.18 else 0.0
        samples.append((s1 + s2) * 0.8)
    write_wav(os.path.join(SFX_DIR, "heartbeat_pulse.wav"), samples)

    # 17. player_caughtwhistle.wav
    samples = []
    dur = 0.5
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        freq = 2800 if (int(t * 12) % 2 == 0) else 3100
        env = math.sin(math.pi * (t / dur))
        s = math.sin(2 * math.pi * freq * t) * env * 0.6
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "player_caughtwhistle.wav"), samples)

    # 18. level_escape_fanfare.wav (Jazz brass victory)
    samples = []
    dur = 1.4
    n_samples = int(SAMPLE_RATE * dur)
    chords = [
        (0.0, 0.25, 587.33), # D5
        (0.25, 0.5, 739.99), # F#5
        (0.5, 0.75, 880.00), # A5
        (0.75, 1.4, 1174.66) # D6
    ]
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        for start, end, freq in chords:
            if start <= t < end:
                dt = t - start
                env = math.exp(-3.0 * dt)
                # Brass-like harmonic overtone
                val = (math.sin(2 * math.pi * freq * dt) * 0.6 +
                       math.sin(4 * math.pi * freq * dt) * 0.3) * env
        samples.append(val * 0.7)
    write_wav(os.path.join(SFX_DIR, "level_escape_fanfare.wav"), samples)

    # 19. ui_click.wav
    samples = []
    dur = 0.06
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        s = math.sin(2 * math.pi * 1200 * t) * math.exp(-60.0 * t) * 0.5
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "ui_click.wav"), samples)

    # 20. ui_hover.wav
    samples = []
    dur = 0.08
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        s = math.sin(2 * math.pi * 880 * t) * math.exp(-40.0 * t) * 0.35
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "ui_hover.wav"), samples)

    # 21. star_stamp.wav
    samples = []
    dur = 0.45
    n_samples = int(SAMPLE_RATE * dur)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        thump = math.sin(2 * math.pi * 80 * t) * math.exp(-15.0 * t) * 0.7
        shimmer = math.sin(2 * math.pi * 2100 * t) * math.exp(-8.0 * t) * 0.3
        samples.append((thump + shimmer) * 0.7)
    write_wav(os.path.join(SFX_DIR, "star_stamp.wav"), samples)

    print("Created all 21 sound effects in assets/audio/sfx/")

def generate_dual_stem_music():
    """
    Generates exact-length synchronized 116 BPM loops (16 bars):
      Length = 16 * 4 * (60.0 / 116.0) = 33.10344827586207 seconds.
      1. music_stem_explore.wav (Walking bass, soft finger snaps, sparse Rhodes chords)
      2. music_stem_lockdown.wav (Driving heist percussion, hi-hat clock ticks, tense synth stabs)
      3. music_menu_noir.wav (Mellow noir bass & Rhodes loop)
    """
    bpm = 116.0
    beat_sec = 60.0 / bpm
    total_beats = 64 # 16 bars of 4/4
    total_sec = total_beats * beat_sec
    total_samples = int(SAMPLE_RATE * total_sec)

    # Jazz Chord Progression in Dm (4 bars x 4):
    # Bars 1-4:   Dm9   | Dm9   | Gm7   | Gm7
    # Bars 5-8:   Bbmaj7| Em7b5 | A7alt | Dm9
    # Bars 9-12:  Dm9   | Gm7   | C9    | Fmaj7
    # Bars 13-16: Bbmaj7| A7alt | Dm9   | Dm9 (turnaround)

    # Fundamental frequencies:
    notes = {
        "D2": 73.42, "F2": 87.31, "G2": 98.00, "A2": 110.00, "Bb2": 116.54, "C3": 130.81,
        "D3": 146.83, "E3": 164.81, "F3": 174.61, "G3": 196.00, "A3": 220.00, "Bb3": 233.08,
        "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00
    }

    # 16-bar bassline notes (1 note per beat):
    bass_pattern = [
        # Bars 1-4
        "D2", "F2", "A2", "C3",  "D3", "C3", "A2", "F2",  "G2", "Bb2", "D3", "F3",  "G3", "F3", "D3", "Bb2",
        # Bars 5-8
        "Bb2", "D3", "F3", "A3", "E2", "G2", "Bb2", "D3", "A2", "C3", "E3", "G3",  "D2", "A2", "D3", "C3",
        # Bars 9-12
        "D2", "F2", "A2", "D3",  "G2", "Bb2", "D3", "G3", "C3", "E3", "G3", "Bb3", "F2", "A2", "C3", "E3",
        # Bars 13-16
        "Bb2", "D3", "F3", "A3", "A2", "C#3" if "C#3" in notes else "A2", "E3", "G3", "D2", "F2", "A2", "D3", "D2", "D2", "A2", "D3"
    ]

    # Initialize buffers
    buf_explore = [0.0] * total_samples
    buf_lockdown = [0.0] * total_samples
    buf_menu = [0.0] * total_samples

    # Helper: add bass note
    def add_bass(buf, start_time, dur, freq, vol=0.5):
        start_idx = int(start_time * SAMPLE_RATE)
        n_s = int(dur * SAMPLE_RATE)
        for i in range(n_s):
            idx = start_idx + i
            if idx >= len(buf): break
            t = i / SAMPLE_RATE
            # Upright bass tone (fundamental + gentle 2nd harmonic)
            env = math.exp(-3.5 * t)
            val = (math.sin(2 * math.pi * freq * t) * 0.7 +
                   math.sin(4 * math.pi * freq * t) * 0.3) * env * vol
            buf[idx] += val

    # Helper: add soft Rhodes chord
    def add_chord(buf, start_time, dur, freqs, vol=0.2):
        start_idx = int(start_time * SAMPLE_RATE)
        n_s = int(dur * SAMPLE_RATE)
        for i in range(n_s):
            idx = start_idx + i
            if idx >= len(buf): break
            t = i / SAMPLE_RATE
            env = math.exp(-2.2 * t)
            val = 0.0
            for f in freqs:
                val += math.sin(2 * math.pi * f * t)
            buf[idx] += val * env * (vol / len(freqs))

    # Helper: add snare / snap
    def add_snap(buf, start_time, vol=0.3):
        start_idx = int(start_time * SAMPLE_RATE)
        n_s = int(0.12 * SAMPLE_RATE)
        for i in range(n_s):
            idx = start_idx + i
            if idx >= len(buf): break
            t = i / SAMPLE_RATE
            env = math.exp(-35.0 * t)
            val = (random.random() * 2.0 - 1.0) * env * vol
            buf[idx] += val

    # Helper: add kick drum
    def add_kick(buf, start_time, vol=0.6):
        start_idx = int(start_time * SAMPLE_RATE)
        n_s = int(0.25 * SAMPLE_RATE)
        for i in range(n_s):
            idx = start_idx + i
            if idx >= len(buf): break
            t = i / SAMPLE_RATE
            freq = 110.0 * math.exp(-18.0 * t) + 40.0
            env = math.exp(-10.0 * t)
            val = math.sin(2 * math.pi * freq * t) * env * vol
            buf[idx] += val

    # Helper: add hi-hat tick
    def add_hihat(buf, start_time, vol=0.2):
        start_idx = int(start_time * SAMPLE_RATE)
        n_s = int(0.05 * SAMPLE_RATE)
        for i in range(n_s):
            idx = start_idx + i
            if idx >= len(buf): break
            t = i / SAMPLE_RATE
            env = math.exp(-80.0 * t)
            val = (random.random() * 2.0 - 1.0) * env * vol
            buf[idx] += val

    # Populate beats
    for beat in range(total_beats):
        b_time = beat * beat_sec
        note_name = bass_pattern[beat % len(bass_pattern)]
        freq = notes.get(note_name, 73.42)

        # Explore Bass + Menu Bass
        add_bass(buf_explore, b_time, beat_sec * 0.95, freq, vol=0.45)
        add_bass(buf_menu, b_time, beat_sec * 0.95, freq, vol=0.4)

        # Chords on bar downbeats (every 4 beats)
        if beat % 4 == 0:
            chord_freqs = [notes["D3"], notes["F3"], notes["A3"], notes["C4"]]
            if (beat // 4) in [2, 3, 9]:
                chord_freqs = [notes["G3"], notes["Bb3"], notes["D4"], notes["F4"]]
            elif (beat // 4) in [4, 12]:
                chord_freqs = [notes["Bb3"], notes["D4"], notes["F4"], notes["A4"]]
            add_chord(buf_explore, b_time, beat_sec * 3.8, chord_freqs, vol=0.25)
            add_chord(buf_menu, b_time, beat_sec * 3.8, chord_freqs, vol=0.3)

        # Explore: Finger snaps on beats 2 & 4
        if beat % 2 == 1:
            add_snap(buf_explore, b_time, vol=0.22)
            add_snap(buf_menu, b_time, vol=0.15)

        # Lockdown: High-tension percussion!
        # Kick on 1 and 3
        if beat % 2 == 0:
            add_kick(buf_lockdown, b_time, vol=0.55)
        # Snare on 2 and 4
        if beat % 2 == 1:
            add_snap(buf_lockdown, b_time, vol=0.45)

        # 16th-note ticking stopwatch hi-hats on Lockdown
        for step in range(4):
            add_hihat(buf_lockdown, b_time + step * (beat_sec / 4.0), vol=0.18 if step != 0 else 0.28)

        # Lockdown: Tense brass/synth stabs matching accents
        if beat % 4 == 0 or beat % 4 == 3:
            stab_freqs = [notes["D4"], notes["F4"], notes["A4"]]
            add_chord(buf_lockdown, b_time, beat_sec * 0.5, stab_freqs, vol=0.35)

    write_wav(os.path.join(AUDIO_DIR, "music_stem_explore.wav"), buf_explore)
    write_wav(os.path.join(AUDIO_DIR, "music_stem_lockdown.wav"), buf_lockdown)
    write_wav(os.path.join(AUDIO_DIR, "music_menu_noir.wav"), buf_menu)
    print("Created synchronized dual-stem music & menu music (.wav)")

if __name__ == "__main__":
    print("=== Generating Visual Assets ===")
    create_smooth_light_cone()
    create_soft_radial_light()
    create_bandit_sheet()
    create_loot_bags()
    create_guards()
    create_tileset_blueprint()
    create_interactive_props()
    create_ui_assets()

    print("=== Generating Audio Assets ===")
    generate_sound_effects()
    generate_dual_stem_music()

    print("=== ALL ASSETS GENERATED SUCCESSFULLY ===")
