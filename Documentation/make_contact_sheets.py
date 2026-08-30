from pathlib import Path
from PIL import Image, ImageDraw

src = Path("Documentation/.interim_qa/render6")
out = Path("Documentation/.interim_qa/contact6")
out.mkdir(parents=True, exist_ok=True)
pages = sorted(src.glob("page-*.png"), key=lambda p: int(p.stem.split("-")[-1]))

thumb_w, thumb_h = 620, 877
gap, label_h = 24, 34
for start in range(0, len(pages), 4):
    batch = pages[start:start + 4]
    sheet = Image.new("RGB", (thumb_w * 2 + gap * 3, (thumb_h + label_h) * 2 + gap * 3), "#D8DEE3")
    draw = ImageDraw.Draw(sheet)
    for pos, page in enumerate(batch):
        image = Image.open(page).convert("RGB")
        image.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        row, col = divmod(pos, 2)
        x = gap + col * (thumb_w + gap)
        y = gap + row * (thumb_h + label_h + gap)
        sheet.paste(image, (x + (thumb_w - image.width) // 2, y + label_h))
        page_no = int(page.stem.split("-")[-1])
        draw.text((x + 8, y + 7), f"PAGE {page_no}", fill="#172B3A")
    sheet.save(out / f"contact-{start // 4 + 1:02d}.png")
print(f"{len(pages)} pages -> {len(list(out.glob('contact-*.png')))} contact sheets")
