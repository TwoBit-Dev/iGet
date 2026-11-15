import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "readme"
WIDTH, HEIGHT = 1120, 600
parser = argparse.ArgumentParser(description="Render the README's illustrated desktop animation.")
parser.add_argument("--font", default="/System/Library/Fonts/Supplemental/Arial.ttf")
parser.add_argument("--bold-font", default="/System/Library/Fonts/Supplemental/Arial Bold.ttf")
args = parser.parse_args()
fonts = {}


def font(size, bold=False):
    key = (size, bold)
    if key not in fonts:
        fonts[key] = ImageFont.truetype(args.bold_font if bold else args.font, size)
    return fonts[key]


def text(draw, xy, value, size=16, fill="#EFEAF8", bold=False):
    draw.text(xy, value, font=font(size, bold), fill=fill, stroke_width=0)


def rounded(draw, box, fill, radius=22, outline=None):
    draw.rounded_rectangle(box, radius, fill=fill, outline=outline, width=1)


def tile(image, xy, size, color, label, phase, offset=0):
    x, y = xy
    y += round(4 * math.sin(phase + offset))
    w, h = size
    draw = ImageDraw.Draw(image)
    rounded(draw, (x + 1, y + 10, x + w + 1, y + h + 10), "#10101B")
    rounded(draw, (x, y, x + w, y + h), color)
    text(draw, (x + 20, y + 18), label, 11, "#5E506B", True)
    return draw, x, y


def scene(index, phase):
    image = Image.new("RGB", (WIDTH, HEIGHT), "#14121E")
    draw = ImageDraw.Draw(image)
    for y in range(HEIGHT):
        shade = round(5 * (1 - y / HEIGHT))
        draw.line((0, y, WIDTH, y), fill=(20 + shade, 18 + shade, 30 + shade))
    for x in range(570, 1100, 24):
        for y in range(92, 500, 24):
            draw.point((x, y), fill="#383244")
    draw.ellipse((635, 86, 1105, 556), outline="#302A40", width=1)
    draw.ellipse((687, 138, 1053, 504), outline="#302A40", width=1)
    rounded(draw, (48, 42, 144, 74), "#30273F", 16)
    text(draw, (65, 49), "iGet", 18, "#E6D9FF", True)
    text(draw, (161, 51), "A HOME FOR YOUR WIDGETS", 11, "#A89DBB", True)
    text(draw, (48, 156), "Your desktop.", 59, bold=True)
    text(draw, (48, 222), "Your rhythm.", 59, "#C6AFF5", True)
    text(draw, (51, 322), "Little tools for the way you work,", 20, "#B5ADC3")
    text(draw, (51, 352), "focus, and make space for yourself.", 20, "#B5ADC3")
    rounded(draw, (50, 418, 270, 456), "#C8B5F3", 19)
    text(draw, (69, 429), "NATIVE TO YOUR MAC", 12, "#251D34", True)
    text(draw, (50, 531), "21 WIDGETS", 11, "#BFB4D0", True)
    text(draw, (167, 531), "/", 12, "#655A79")
    text(draw, (191, 531), "8 PALETTES", 11, "#BFB4D0", True)
    text(draw, (305, 531), "/", 12, "#655A79")
    text(draw, (329, 531), "ENDLESSLY YOURS", 11, "#BFB4D0", True)
    if index == 0:
        d, x, y = tile(image, (575, 142), (224, 178), "#E4F6ED", "LOCAL TIME", phase)
        text(d, (x + 18, y + 55), "09:41", 50, "#1C271E", True)
        text(d, (x + 20, y + 127), "A little room to think.", 14, "#526755")
        d, x, y = tile(image, (820, 118), (244, 202), "#FFF3DF", "FOCUS SESSION", phase, 1.3)
        text(d, (x + 20, y + 56), "24:0" + str(9 - int(phase / (2 * math.pi) * 2) % 3), 51, "#2E251E", True)
        rounded(d, (x + 20, y + 131, x + 224, y + 139), "#E4D7C4", 4)
        rounded(d, (x + 20, y + 131, x + 154, y + 139), "#8C7962", 4)
        text(d, (x + 20, y + 159), "One thing at a time.", 14, "#6E5E53")
        d, x, y = tile(image, (590, 345), (270, 142), "#EDE6FF", "TODAY'S LITTLE WINS", phase, 2.3)
        for row, label in enumerate(["Make a little progress", "Take a proper break"]):
            cy = y + 62 + row * 35
            d.ellipse((x + 20, cy, x + 35, cy + 15), fill="#6D5582" if row == 0 else None, outline="#6D5582")
            if row == 0:
                d.line((x + 24, cy + 8, x + 27, cy + 11, x + 32, cy + 5), fill="#FFFFFF", width=2)
            text(d, (x + 46, cy), label, 14, "#5E506B")
        d, x, y = tile(image, (880, 345), (184, 142), "#E8EEF8", "COUNTDOWN", phase, 3.4)
        text(d, (x + 20, y + 52), "12", 48, "#1B2329", True)
        text(d, (x + 83, y + 79), "days", 18, "#4E5C67")
        text(d, (x + 20, y + 111), "Until the next thing.", 13, "#4E5C67")
    elif index == 1:
        d, x, y = tile(image, (575, 142), (224, 178), "#E8EEF8", "SYSTEM MONITOR", phase)
        text(d, (x + 20, y + 53), "CPU", 15, "#4E5C67")
        text(d, (x + 20, y + 75), "18%", 38, "#1B2329", True)
        points = [(x + 20 + i * 7, y + 150 - round(12 + 15 * math.sin(i * .8 + phase) ** 2)) for i in range(27)]
        d.line(points, fill="#637D95", width=3)
        d, x, y = tile(image, (820, 118), (244, 202), "#FFF3DF", "A NOTE TO SELF", phase, 1.3)
        text(d, (x + 20, y + 61), "Small ideas.", 26, "#2E251E", True)
        text(d, (x + 20, y + 96), "Good things to build.", 17, "#6E5E53")
        for i, length in enumerate([165, 183, 121]):
            rounded(d, (x + 20, y + 137 + i * 15, x + 20 + length, y + 141 + i * 15), "#DCCDB7", 2)
        d, x, y = tile(image, (590, 345), (474, 142), "#EDE6FF", "YOUR SHORTCUTS, ONE CLICK AWAY", phase, 2.3)
        for i, name in enumerate(["Editor", "Terminal", "Browser", "Files"]):
            cx = x + 20 + i * 113
            rounded(d, (cx, y + 54, cx + 95, y + 117), "#DFD4F4", 13)
            text(d, (cx + 12, y + 77), name, 15, "#5E506B", True)
    else:
        d, x, y = tile(image, (575, 142), (224, 178), "#FFF3DF", "NOVEMBER", phase)
        text(d, (x + 20, y + 52), "15", 55, "#2E251E", True)
        text(d, (x + 20, y + 128), "A fresh start, every day.", 14, "#6E5E53")
        d, x, y = tile(image, (820, 118), (244, 202), "#E2F2FF", "WEATHER / ISTANBUL", phase, 1.3)
        text(d, (x + 20, y + 57), "14°", 58, "#223E57", True)
        d.ellipse((x + 165, y + 64, x + 207, y + 106), fill="#E6B86B")
        text(d, (x + 20, y + 153), "A bright little outlook.", 15, "#527A99")
        d, x, y = tile(image, (590, 345), (270, 142), "#FFEBDD", "HABITS", phase, 2.3)
        text(d, (x + 20, y + 51), "Keep showing up.", 23, "#57382C", True)
        for i in range(7):
            d.ellipse((x + 20 + i * 32, y + 96, x + 38 + i * 32, y + 114), fill="#C86C47" if i < 4 else "#E8CCBB")
        d, x, y = tile(image, (880, 345), (184, 142), "#E4F6ED", "BATTERY", phase, 3.4)
        text(d, (x + 20, y + 51), "82%", 39, "#1C271E", True)
        rounded(d, (x + 20, y + 109, x + 164, y + 117), "#C0D7C6", 4)
        rounded(d, (x + 20, y + 109, x + 138, y + 117), "#2F7B60", 4)
    draw = ImageDraw.Draw(image)
    for i, name in enumerate(["Study", "Developer", "Daily"]):
        x = 628 + i * 139
        rounded(draw, (x, 516, x + 127, 552), "#C8B5F3" if i == index else "#272131", 18)
        box = draw.textbbox((0, 0), name, font=font(14, True))
        text(draw, (x + (127 - box[2]) / 2, 526), name, 14, "#251D34" if i == index else "#AFA2C3", True)
    return image


def render():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    frames = []
    for frame in range(72):
        index, local = divmod(frame, 24)
        phase = frame / 72 * 2 * math.pi
        image = scene(index, phase)
        if local >= 21:
            image = Image.blend(image, scene((index + 1) % 3, phase), (local - 20) / 4)
        frames.append(image.quantize(colors=128, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE))
    scene(0, 0).save(OUTPUT / "hero.png", optimize=True)
    frames[0].save(OUTPUT / "hero.gif", save_all=True, append_images=frames[1:], duration=120, loop=0, optimize=True, disposal=1)
    print(f"Rendered {len(frames)} frames to {OUTPUT}")


if __name__ == "__main__":
    render()
