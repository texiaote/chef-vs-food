#!/usr/bin/env python3
"""Generate 32px-scale placeholder sprites for Chef vs Food v0.1.

Final art replaces these PNGs in a later pass. Each entity resource points at
exactly one of these files (plus an optional effect texture for projectiles).
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEX = os.path.join(ROOT, "assets", "textures")


def new(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def px(img: Image.Image, x: int, y: int, color: tuple) -> None:
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)


def ellipse(img: Image.Image, box, color) -> None:
    ImageDraw.Draw(img).ellipse(box, fill=color)


def rect(img: Image.Image, box, color) -> None:
    ImageDraw.Draw(img).rectangle(box, fill=color)


def shadow(img: Image.Image, box) -> None:
    ellipse(img, box, (20, 40, 20, 70))


def outline(img: Image.Image, color=(18, 28, 18, 255)) -> None:
    src = img.copy()
    sp = src.load()
    dp = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            if sp[x, y][3] > 200:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and sp[nx, ny][3] > 200:
                    dp[x, y] = color
                    break


def angry_face(img: Image.Image, cx: int, cy: int, scale: int = 1, mouth: bool = True) -> None:
    s = scale
    white = (255, 248, 240, 255)
    black = (30, 18, 22, 255)
    for side in (-1, 1):
        ex = cx + side * 4 * s
        ey = cy
        rect(img, [ex - s, ey - s, ex + s, ey + s], white)
        px(img, ex + side * max(0, s - 1), ey, black)
        if s > 1:
            px(img, ex + side * max(0, s - 1), ey + 1, black)
        # Inward-slanted brow.
        for i in range(3 * s):
            px(img, ex - side * i, ey - 2 * s - (i // max(1, s)), black)
    if mouth:
        for i in range(-2 * s, 2 * s + 1):
            px(img, cx + i, cy + 4 * s + abs(i) // max(1, 2 * s), black)
            if s > 1 and abs(i) < 2 * s:
                px(img, cx + i, cy + 5 * s, (90, 20, 24, 255))


def save(img: Image.Image, *parts: str, do_outline: bool = True) -> None:
    if do_outline:
        outline(img)
    path = os.path.join(TEX, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)


def chef() -> None:
    img = new(48, 48)
    shadow(img, [10, 40, 38, 46])
    # Feet.
    ellipse(img, [14, 38, 22, 46], (92, 58, 36, 255))
    ellipse(img, [26, 38, 34, 46], (92, 58, 36, 255))
    # Arms.
    ellipse(img, [4, 26, 14, 36], (245, 220, 190, 255))
    ellipse(img, [34, 26, 44, 36], (245, 220, 190, 255))
    # Body.
    ellipse(img, [8, 18, 40, 44], (250, 228, 200, 255))
    ellipse(img, [16, 26, 32, 40], (255, 240, 220, 255))
    # Cheeks.
    ellipse(img, [11, 28, 17, 33], (240, 150, 140, 255))
    ellipse(img, [31, 28, 37, 33], (240, 150, 140, 255))
    # Eyes and mustache.
    rect(img, [17, 25, 20, 28], (40, 24, 28, 255))
    rect(img, [28, 25, 31, 28], (40, 24, 28, 255))
    ellipse(img, [15, 29, 33, 36], (110, 64, 36, 255))
    rect(img, [22, 31, 26, 33], (250, 220, 190, 255))
    # Hat.
    rect(img, [18, 4, 30, 14], (255, 255, 255, 255))
    rect(img, [16, 2, 32, 8], (255, 255, 255, 255))
    rect(img, [11, 13, 37, 18], (255, 255, 255, 255))
    rect(img, [18, 11, 30, 14], (70, 70, 78, 255))
    save(img, "chef.png")
    # Window / project icon, nearest-neighbor upscale.
    icon = img.resize((128, 128), Image.NEAREST)
    icon.save(os.path.join(ROOT, "icon.png"))


def face_enemy(img: Image.Image, cx: int, cy: int) -> None:
    angry_face(img, cx, cy, 1, True)


def broccoli() -> None:
    img = new(32, 32)
    shadow(img, [8, 26, 24, 31])
    rect(img, [14, 16, 18, 28], (70, 140, 50, 255))
    ellipse(img, [4, 6, 16, 18], (40, 150, 46, 255))
    ellipse(img, [16, 6, 28, 18], (52, 170, 58, 255))
    ellipse(img, [9, 2, 23, 16], (70, 190, 64, 255))
    ellipse(img, [12, 5, 18, 10], (150, 220, 120, 255))
    face_enemy(img, 16, 12)
    save(img, "enemies", "broccoli.png")


def chili() -> None:
    img = new(32, 32)
    shadow(img, [8, 26, 26, 31])
    d = ImageDraw.Draw(img)
    # Curved body built from overlapping blobs so it stays pixel-crisp.
    for i in range(16):
        t = i / 15.0
        x = 7 + t * 16
        y = 22 - math.sin(t * math.pi) * 12
        r = 5 - t * 2.2
        d.ellipse([x - r, y - r, x + r, y + r], fill=(196, 32, 36, 255))
    d.ellipse([20, 6, 28, 14], fill=(220, 48, 40, 255))
    rect(img, [22, 3, 25, 8], (40, 140, 48, 255))
    face_enemy(img, 14, 16)
    save(img, "enemies", "chili.png")


def potato() -> None:
    img = new(32, 32)
    shadow(img, [6, 26, 26, 31])
    ellipse(img, [4, 8, 28, 28], (176, 124, 64, 255))
    ellipse(img, [8, 11, 22, 22], (206, 156, 90, 255))
    px(img, 10, 18, (120, 78, 40, 255))
    px(img, 22, 14, (120, 78, 40, 255))
    px(img, 20, 22, (120, 78, 40, 255))
    face_enemy(img, 16, 16)
    save(img, "enemies", "potato.png")


def onion(small: bool = False) -> None:
    img = new(32, 32)
    shadow(img, [8, 26, 24, 31])
    if small:
        ellipse(img, [8, 10, 24, 28], (150, 70, 170, 255))
        ellipse(img, [11, 13, 21, 24], (190, 120, 200, 255))
        rect(img, [15, 6, 18, 12], (60, 150, 60, 255))
        angry_face(img, 16, 18, 1, True)
        save(img, "enemies", "onion_small.png")
        return
    ellipse(img, [5, 8, 27, 29], (128, 48, 150, 255))
    ellipse(img, [9, 12, 23, 26], (186, 96, 196, 255))
    ellipse(img, [12, 15, 20, 23], (220, 170, 220, 255))
    rect(img, [14, 2, 18, 10], (48, 140, 56, 255))
    rect(img, [12, 3, 15, 6], (48, 140, 56, 255))
    rect(img, [17, 3, 21, 7], (48, 140, 56, 255))
    face_enemy(img, 16, 18)
    save(img, "enemies", "onion.png")


def corn() -> None:
    img = new(32, 32)
    shadow(img, [8, 27, 24, 31])
    # Husk.
    ellipse(img, [4, 10, 14, 28], (48, 140, 52, 255))
    ellipse(img, [18, 10, 28, 28], (48, 140, 52, 255))
    rect(img, [10, 6, 22, 28], (244, 206, 64, 255))
    for y in range(8, 26, 3):
        for x in range(12, 21, 3):
            px(img, x, y, (210, 150, 30, 255))
    rect(img, [14, 2, 18, 8], (70, 160, 60, 255))
    face_enemy(img, 16, 14)
    save(img, "enemies", "corn.png")


def popcorn() -> None:
    img = new(16, 16)
    ellipse(img, [2, 3, 10, 12], (255, 248, 230, 255))
    ellipse(img, [6, 2, 14, 11], (255, 236, 180, 255))
    ellipse(img, [4, 6, 12, 14], (250, 220, 140, 255))
    px(img, 6, 6, (255, 255, 255, 255))
    save(img, "enemies", "popcorn.png", do_outline=True)


def cake_small() -> None:
    img = new(32, 32)
    shadow(img, [6, 26, 26, 31])
    rect(img, [6, 18, 26, 28], (240, 120, 160, 255))
    rect(img, [4, 16, 28, 20], (255, 245, 250, 255))
    rect(img, [9, 10, 23, 18], (250, 150, 180, 255))
    rect(img, [8, 8, 24, 12], (255, 245, 250, 255))
    px(img, 16, 5, (255, 80, 80, 255))
    rect(img, [15, 6, 17, 9], (80, 180, 255, 255))
    face_enemy(img, 16, 14)
    save(img, "enemies", "cake_small.png")


def cake_boss() -> None:
    img = new(96, 96)
    shadow(img, [14, 80, 82, 92])
    # Tiers, bottom to top.
    rect(img, [10, 62, 86, 84], (236, 120, 156, 255))
    rect(img, [8, 58, 88, 66], (255, 246, 250, 255))
    for x in range(14, 84, 8):
        ellipse(img, [x, 56, x + 6, 64], (255, 250, 252, 255))
    rect(img, [20, 40, 76, 62], (244, 140, 170, 255))
    rect(img, [18, 36, 78, 44], (255, 246, 250, 255))
    rect(img, [30, 18, 66, 40], (250, 160, 186, 255))
    rect(img, [28, 14, 68, 22], (255, 246, 250, 255))
    # Cherries.
    ellipse(img, [22, 60, 30, 68], (210, 30, 48, 255))
    ellipse(img, [66, 60, 74, 68], (210, 30, 48, 255))
    # Candles.
    for cx in (36, 48, 60):
        rect(img, [cx - 1, 6, cx + 1, 16], (80, 170, 255, 255))
        ellipse(img, [cx - 2, 2, cx + 2, 8], (255, 210, 60, 255))
    angry_face(img, 48, 28, 2, True)
    save(img, "enemies", "cake.png")


def knife() -> None:
    img = new(32, 32)
    rect(img, [4, 14, 14, 19], (110, 70, 40, 255))
    rect(img, [12, 13, 16, 20], (80, 80, 88, 255))
    # Blade pointing right.
    d = ImageDraw.Draw(img)
    d.polygon([(14, 12), (28, 15), (14, 20)], fill=(220, 230, 236, 255))
    rect(img, [16, 15, 26, 16], (255, 255, 255, 255))
    save(img, "weapons", "knife.png")


def knife_rain() -> None:
    img = new(32, 32)
    d = ImageDraw.Draw(img)
    cx = cy = 15
    for i in range(8):
        ang = math.tau * i / 8.0
        x = cx + math.cos(ang) * 6
        y = cy + math.sin(ang) * 6
        x2 = cx + math.cos(ang) * 13
        y2 = cy + math.sin(ang) * 13
        d.line([(x, y), (x2, y2)], fill=(230, 236, 240, 255), width=2)
        px(img, int(x2), int(y2), (255, 255, 255, 255))
    ellipse(img, [12, 12, 18, 18], (180, 190, 200, 255))
    save(img, "weapons", "knife_rain.png")


def spatula() -> None:
    img = new(32, 32)
    rect(img, [15, 8, 19, 28], (120, 78, 44, 255))
    rect(img, [8, 4, 26, 14], (190, 198, 206, 255))
    rect(img, [10, 6, 24, 8], (230, 236, 240, 255))
    save(img, "weapons", "spatula.png")


def pan(hot: bool = False) -> None:
    img = new(32, 32)
    ellipse(img, [4, 6, 24, 26], (70, 74, 80, 255))
    ellipse(img, [7, 9, 21, 23], (40, 42, 48, 255))
    if hot:
        ellipse(img, [9, 11, 19, 21], (230, 120, 30, 255))
        ellipse(img, [12, 13, 16, 17], (255, 210, 80, 255))
    else:
        ellipse(img, [9, 11, 16, 16], (130, 136, 144, 255))
    rect(img, [20, 14, 30, 18], (90, 94, 100, 255))
    save(img, "weapons", "hot_pan.png" if hot else "pan.png")


def pepper() -> None:
    img = new(32, 32)
    rect(img, [12, 10, 22, 26], (92, 56, 36, 255))
    rect(img, [13, 12, 21, 16], (140, 90, 50, 255))
    ellipse(img, [11, 6, 23, 13], (70, 42, 28, 255))
    for x in (15, 18, 21):
        px(img, x, 9, (30, 20, 16, 255))
    # A puff above the shaker.
    ellipse(img, [6, 2, 16, 10], (190, 170, 130, 180))
    ellipse(img, [12, 0, 22, 8], (210, 190, 150, 160))
    save(img, "weapons", "pepper.png")


def pepper_cloud() -> None:
    img = new(32, 32)
    ellipse(img, [2, 10, 18, 26], (170, 140, 90, 150))
    ellipse(img, [10, 4, 28, 20], (200, 170, 110, 160))
    ellipse(img, [8, 12, 24, 28], (140, 110, 70, 140))
    ellipse(img, [14, 8, 22, 16], (230, 210, 160, 180))
    save(img, "weapons", "pepper_cloud.png", do_outline=False)


def rolling_pin() -> None:
    img = new(32, 32)
    rect(img, [2, 14, 8, 20], (150, 90, 48, 255))
    rect(img, [24, 14, 30, 20], (150, 90, 48, 255))
    rect(img, [6, 12, 26, 22], (196, 130, 64, 255))
    rect(img, [8, 13, 24, 15], (230, 180, 110, 255))
    save(img, "weapons", "rolling_pin.png")


def apron() -> None:
    img = new(32, 32)
    rect(img, [6, 4, 26, 8], (230, 230, 236, 255))
    rect(img, [8, 8, 12, 14], (230, 230, 236, 255))
    rect(img, [20, 8, 24, 14], (230, 230, 236, 255))
    ellipse(img, [7, 12, 25, 28], (245, 245, 248, 255))
    rect(img, [14, 16, 18, 26], (180, 40, 48, 255))
    save(img, "passives", "apron.png")


def sneakers() -> None:
    img = new(32, 32)
    ellipse(img, [4, 14, 26, 24], (240, 80, 70, 255))
    ellipse(img, [16, 16, 30, 26], (250, 250, 255, 255))
    rect(img, [8, 12, 18, 16], (40, 40, 48, 255))
    rect(img, [6, 18, 22, 20], (255, 255, 255, 255))
    save(img, "passives", "sneakers.png")


def ladle() -> None:
    img = new(32, 32)
    rect(img, [18, 6, 22, 24], (200, 204, 210, 255))
    ellipse(img, [4, 14, 18, 28], (176, 182, 190, 255))
    ellipse(img, [7, 17, 15, 25], (40, 44, 50, 255))
    save(img, "passives", "ladle.png")


def sauce() -> None:
    img = new(32, 32)
    rect(img, [12, 8, 22, 26], (150, 36, 40, 255))
    rect(img, [14, 4, 20, 10], (90, 24, 28, 255))
    ellipse(img, [13, 14, 21, 22], (220, 70, 60, 255))
    rect(img, [15, 16, 19, 20], (255, 220, 80, 255))
    save(img, "passives", "sauce.png")


def timer() -> None:
    img = new(32, 32)
    ellipse(img, [6, 6, 26, 26], (240, 240, 245, 255))
    ellipse(img, [9, 9, 23, 23], (40, 48, 60, 255))
    rect(img, [14, 4, 18, 8], (200, 60, 60, 255))
    rect(img, [15, 15, 17, 22], (255, 80, 80, 255))
    rect(img, [15, 14, 21, 16], (255, 220, 80, 255))
    save(img, "passives", "timer.png")


def gem() -> None:
    img = new(16, 16)
    d = ImageDraw.Draw(img)
    d.polygon([(8, 1), (14, 8), (8, 15), (2, 8)], fill=(70, 190, 255, 255))
    d.polygon([(8, 3), (11, 8), (8, 12), (6, 8)], fill=(180, 240, 255, 255))
    save(img, "gem.png")


def skull() -> None:
    img = new(16, 16)
    ellipse(img, [3, 2, 13, 12], (240, 240, 240, 255))
    rect(img, [5, 10, 11, 14], (240, 240, 240, 255))
    rect(img, [5, 6, 7, 8], (30, 30, 36, 255))
    rect(img, [9, 6, 11, 8], (30, 30, 36, 255))
    px(img, 8, 9, (30, 30, 36, 255))
    px(img, 6, 12, (30, 30, 36, 255))
    px(img, 8, 12, (30, 30, 36, 255))
    px(img, 10, 12, (30, 30, 36, 255))
    save(img, "skull.png")


def ground() -> None:
    size = 128
    step = 8
    grid = size // step

    def hash2(ix: int, iy: int) -> float:
        ix %= grid
        iy %= grid
        n = (ix * 374761393 + iy * 668265263 + 911 * 1440662683) & 0xFFFFFFFF
        n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
        return (n & 255) / 255.0

    def smooth(t: float) -> float:
        return t * t * (3.0 - 2.0 * t)

    def lerp(a: float, b: float, t: float) -> float:
        return a + (b - a) * t

    def cell_hash(x: int, y: int) -> int:
        n = (x * 198491317 + y * 6542989 + 4241) & 0xFFFFFFFF
        n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
        return n

    img = new(size, size)
    pix = img.load()
    for y in range(size):
        for x in range(size):
            gx = x / step
            gy = y / step
            x0 = int(math.floor(gx))
            y0 = int(math.floor(gy))
            tx = smooth(gx - x0)
            ty = smooth(gy - y0)
            v = lerp(
                lerp(hash2(x0, y0), hash2(x0 + 1, y0), tx),
                lerp(hash2(x0, y0 + 1), hash2(x0 + 1, y0 + 1), tx),
                ty,
            )
            if v < 0.35:
                col = (36, 92, 34, 255)
            elif v < 0.6:
                col = (48, 122, 42, 255)
            else:
                col = (70, 150, 54, 255)
            h = cell_hash(x, y)
            if h % 17 == 0:
                col = (30, 78, 30, 255)
            elif h % 29 == 0:
                col = (96, 168, 70, 255)
            pix[x, y] = col
    # Tiny wrapped flowers and sprouts so the tile stays seamless.
    for y in range(0, size, 1):
        for x in range(0, size, 1):
            h = cell_hash(x + 3, y + 9)
            if h % 211 == 0:
                pix[x, y] = (250, 245, 230, 255)
                pix[(x + 1) % size, y] = (250, 210, 70, 255)
            elif h % 173 == 0:
                pix[x, y] = (240, 80, 90, 255)
            elif h % 97 == 0:
                pix[x, y] = (20, 90, 30, 255)
                pix[x, (y - 1) % size] = (30, 120, 40, 255)
    save(img, "ground.png", do_outline=False)


def main() -> None:
    chef()
    broccoli()
    chili()
    potato()
    onion(False)
    onion(True)
    corn()
    popcorn()
    cake_small()
    cake_boss()
    knife()
    knife_rain()
    spatula()
    pan(False)
    pan(True)
    pepper()
    pepper_cloud()
    rolling_pin()
    apron()
    sneakers()
    ladle()
    sauce()
    timer()
    gem()
    skull()
    ground()
    print("sprites ok", TEX)


if __name__ == "__main__":
    main()
