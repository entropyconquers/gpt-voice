"""Builds the README hero and the repository social preview as standalone SVGs.

Text is set in FT Regola Neue with HarfBuzz shaping and converted to outlines, so the
SVGs render identically on GitHub and anywhere else (no font loading needed).

    python3 -m venv /tmp/gv-venv && /tmp/gv-venv/bin/pip install fonttools brotli uharfbuzz resvg-py
    /tmp/gv-venv/bin/python docs/assets/src/build-graphics.py

Writes docs/assets/*.svg, PNG renders next to them (when resvg-py is installed), and a
copy of the social preview PNG to website/dist/assets/social-preview.png.
"""
import pathlib
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

ROOT = pathlib.Path(__file__).resolve().parents[3]
FONTS = ROOT / "website" / "dist" / "fonts"
OUT = ROOT / "docs" / "assets"


class Face:
    def __init__(self, path):
        self.tt = TTFont(path)
        self.tt.flavor = None
        import io
        buf = io.BytesIO(); self.tt.save(buf)  # plain sfnt bytes for HarfBuzz
        self.hb_font = hb.Font(hb.Face(hb.Blob(buf.getvalue())))
        self.upm = self.tt["head"].unitsPerEm
        self.glyphs = self.tt.getGlyphSet()
        self.order = self.tt.getGlyphOrder()

    def shape(self, text, tracking=0.0):
        buf = hb.Buffer(); buf.add_str(text); buf.guess_segment_properties()
        hb.shape(self.hb_font, buf, {"kern": True, "liga": True, "tnum": True})
        out, x = [], 0
        for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
            out.append((self.order[info.codepoint], x + pos.x_offset))
            x += pos.x_advance + tracking * self.upm
        return out, x - tracking * self.upm

    def width(self, text, size, tracking=0.0):
        return self.shape(text, tracking)[1] * size / self.upm

    def path(self, text, x, y, size, tracking=0.0, anchor="start"):
        glyphs, adv = self.shape(text, tracking)
        s = size / self.upm
        if anchor == "middle": x -= adv * s / 2
        if anchor == "end": x -= adv * s
        pen = SVGPathPen(self.glyphs)
        for name, gx in glyphs:
            self.glyphs[name].draw(TransformPen(pen, (s, 0, 0, -s, x + gx * s, y)))
        return pen.getCommands()


REG = Face(FONTS / "FTRegolaNeue-Regular.woff2")
MED = Face(FONTS / "FTRegolaNeue-Medium.woff2")

BARS = [(18.3, 39.8, 20.3), (32.3, 30.5, 39.0), (46.4, 22.7, 54.7), (60.4, 32.8, 34.5), (74.3, 41.4, 17.2)]


def app_icon(x, y, size, uid):
    k = size / 100
    bars = "".join(f'<rect x="{x + bx * k:.2f}" y="{y + by * k:.2f}" width="{7.45 * k:.2f}" height="{bh * k:.2f}" rx="{3.72 * k:.2f}"/>' for bx, by, bh in BARS)
    return (f'<defs><linearGradient id="ig{uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2B2B2D"/><stop offset="1" stop-color="#1D1D1F"/></linearGradient></defs>'
            f'<rect x="{x}" y="{y}" width="{size}" height="{size}" rx="{22.6 * k:.2f}" fill="url(#ig{uid})"/>'
            f'<g fill="#EBEBEB">{bars}</g>')


def pill(cx, cy, scale, theme):
    """The app's recording bar, drawn at 40pt height times scale, centred on (cx, cy)."""
    dark = theme == "dark"
    surface, ink, ink2 = ("#252527", "#ECECEC", "#A1A1A6") if dark else ("#FFFFFF", "#1C1C1E", "#5E5E63")
    rec = "#FF6A50" if dark else "#D5432B"
    accent, on_accent = ("#ECECEC", "#1C1C1E") if dark else ("#1C1C1E", "#FFFFFF")
    stroke = "rgba(236,236,236,0.12)" if dark else "rgba(28,28,30,0.12)"
    s = scale
    w, h = 182 * s, 40 * s
    x0, y0 = cx - w / 2, cy - h / 2
    parts = [
        f'<rect x="{x0 - 2 * s:.1f}" y="{y0 + 6 * s:.1f}" width="{w + 4 * s:.1f}" height="{h:.1f}" rx="{h / 2:.1f}" fill="#000" opacity="{0.28 if dark else 0.10}" filter="url(#blur)"/>',
        f'<rect x="{x0:.1f}" y="{y0:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{h / 2:.1f}" fill="{surface}" stroke="{stroke}" stroke-width="{s:.2f}"/>',
        f'<circle cx="{x0 + 17.5 * s:.1f}" cy="{cy:.1f}" r="{3.5 * s:.1f}" fill="{rec}"/>',
    ]
    weights, level = [0.55, 0.8, 1, 0.8, 0.55], [0.62, 0.86, 0.95, 0.7, 0.5]
    bx = x0 + 31 * s
    for i, wgt in enumerate(weights):
        bh = max(3, 18 * wgt * level[i] / max(level) * 1.0) * s
        parts.append(f'<rect x="{bx + i * 6 * s:.1f}" y="{cy - bh / 2:.1f}" width="{3 * s:.1f}" height="{bh:.1f}" rx="{1.5 * s:.1f}" fill="{accent}"/>')
    parts.append(f'<path d="{REG.path("0:07", x0 + 71 * s, cy + 4.6 * s, 13 * s)}" fill="{ink2}"/>')
    c1, c2 = x0 + 128 * s, x0 + 162 * s
    parts.append(f'<circle cx="{c1:.1f}" cy="{cy:.1f}" r="{12 * s:.1f}" fill="{ink}" opacity="0.10"/>')
    d = 3.2 * s
    parts.append(f'<path d="M{c1 - d:.1f} {cy - d:.1f}L{c1 + d:.1f} {cy + d:.1f}M{c1 + d:.1f} {cy - d:.1f}L{c1 - d:.1f} {cy + d:.1f}" stroke="{ink}" stroke-width="{1.6 * s:.2f}" stroke-linecap="round"/>')
    parts.append(f'<circle cx="{c2:.1f}" cy="{cy:.1f}" r="{12 * s:.1f}" fill="{accent}"/>')
    parts.append(f'<rect x="{c2 - 4 * s:.1f}" y="{cy - 4 * s:.1f}" width="{8 * s:.1f}" height="{8 * s:.1f}" rx="{1.4 * s:.1f}" fill="{on_accent}"/>')
    return "".join(parts)


def field(x, y, w, theme, text_lines, size):
    """A plain text field holding just-pasted words, with a caret."""
    dark = theme == "dark"
    surface, stroke, ink, hl = (("#1C1C1E", "rgba(255,255,255,0.10)", "#ECECEC", "rgba(236,236,236,0.14)") if dark
                                else ("#FFFFFF", "rgba(0,0,0,0.10)", "#1C1C1E", "rgba(28,28,30,0.08)"))
    lh = size * 1.45
    h = 30 + lh * len(text_lines)
    parts = [f'<rect x="{x}" y="{y}" width="{w}" height="{h:.1f}" rx="14" fill="{surface}" stroke="{stroke}"/>']
    ty = y + 15 + size * 1.02
    for i, line in enumerate(text_lines):
        lw = REG.width(line, size)
        parts.append(f'<rect x="{x + 18:.1f}" y="{ty - size * 0.98:.1f}" width="{lw + 6:.1f}" height="{size * 1.32:.1f}" rx="4" fill="{hl}"/>')
        parts.append(f'<path d="{REG.path(line, x + 21, ty, size)}" fill="{ink}"/>')
        if i == len(text_lines) - 1:
            parts.append(f'<rect x="{x + 24 + lw:.1f}" y="{ty - size * 0.92:.1f}" width="2" height="{size * 1.18:.1f}" rx="1" fill="{ink}"/>')
        ty += lh
    return "".join(parts), h


def svg(w, h, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            '<defs><filter id="blur" x="-20%" y="-50%" width="140%" height="200%"><feGaussianBlur stdDeviation="9"/></filter></defs>'
            f'{body}</svg>\n')


def social():
    W, H = 1280, 640
    bg, ink, ink2, ink3 = "#F4F4F3", "#1C1C1E", "#5E5E63", "#75757A"
    b = [f'<rect width="{W}" height="{H}" fill="{bg}"/>']
    # Left: identity and the one claim.
    b.append(app_icon(88, 104, 96, "s"))
    b.append(f'<path d="{MED.path("GPT Voice", 84, 316, 92, tracking=-0.02)}" fill="{ink}"/>')
    b.append(f'<path d="{REG.path("Dictate into any app", 88, 386, 40, tracking=-0.01)}" fill="{ink2}"/>')
    b.append(f'<path d="{REG.path("on your Mac.", 88, 436, 40, tracking=-0.01)}" fill="{ink2}"/>')
    b.append(f'<path d="{REG.path("Free and open source  ·  macOS 13+", 88, 548, 22)}" fill="{ink3}"/>')
    # Right: a text field receiving the words, and the recording bar under it.
    f, fh = field(700, 196, 492, "light", ["Make the retry backoff", "exponential, with jitter."], 30)
    b.append(f)
    b.append(pill(946, 196 + fh + 76, 1.7, "light"))
    return svg(W, H, "".join(b))


def hero(theme):
    W, H = 1280, 520
    dark = theme == "dark"
    bg, ink, ink2 = ("#111112", "#ECECEC", "#A1A1A6") if dark else ("#FFFFFF", "#1C1C1E", "#5E5E63")
    b = [f'<rect width="{W}" height="{H}" rx="24" fill="{bg}"/>']
    if not dark:
        b.append(f'<rect x="0.5" y="0.5" width="{W - 1}" height="{H - 1}" rx="23.5" fill="none" stroke="rgba(0,0,0,0.08)"/>')
    title = "GPT Voice"
    tw = MED.width(title, 84, tracking=-0.02)
    icon = 84
    gap = 28
    x0 = (W - (icon + gap + tw)) / 2
    b.append(app_icon(x0, 108, icon, theme[0]))
    b.append(f'<path d="{MED.path(title, x0 + icon + gap, 178, 84, tracking=-0.02)}" fill="{ink}"/>')
    b.append(f'<path d="{REG.path("Dictate into any app on your Mac.", W / 2, 262, 38, tracking=-0.01, anchor="middle")}" fill="{ink2}"/>')
    b.append(pill(W / 2, 382, 1.9, theme))
    return svg(W, H, "".join(b))


def main():
    outputs = {
        "social-preview.svg": social(),
        "readme-hero-light.svg": hero("light"),
        "readme-hero-dark.svg": hero("dark"),
    }
    for name, data in outputs.items():
        (OUT / name).write_text(data)
        print("wrote", OUT / name)
    try:
        import resvg_py
    except ImportError:
        print("resvg-py not installed; skipped PNG renders")
        return
    for name, scale in (("social-preview.svg", 1), ("readme-hero-light.svg", 2), ("readme-hero-dark.svg", 2)):
        png = resvg_py.svg_to_bytes(svg_string=outputs[name], zoom=scale)
        data = bytes(png)
        target = OUT / name.replace(".svg", ".png")
        target.write_bytes(data)
        print("wrote", target)
        if name == "social-preview.svg":
            (ROOT / "website" / "dist" / "assets" / "social-preview.png").write_bytes(data)


if __name__ == "__main__":
    main()
