# DMG window background

A standard Finder drag-to-install window. Finder draws the icons and labels; the image leaves that area empty.

| File | Pixels | DPI | Use |
| --- | --- | --- | --- |
| `background.png` | 760 x 500 | 72 | 1x |
| `background@2x.png` | 1520 x 1000 | 144 | Retina |
| `background.tiff` | both, multi-resolution | 72 / 144 | single file for dmgbuild `background` |
| `render-background.swift` | | | source renderer |

Layout, in Finder points with the origin at the top left:

- Window 760 x 500; toolbar, sidebar and status bar hidden.
- App icon center (210, 255) and Applications link center (550, 255); icon size 112, labels at the bottom.
- WaveMark and "GPT Voice" wordmark centered at y 76; "Drag to Applications" at y 106–124.
- Arrow from x 306 to 454 at y 255, 40 points clear of each icon.
- Footnote "Then open GPT Voice from your Applications folder." at y 446.
- Empty from y 190 to 430 apart from the arrow, for icons and labels.

Colors come from the app's light palette: paper #F6F6F5 to #EFEFEE, ink #1C1C1E, secondary #6E6E73, tertiary #8E8E93.
The background is light in both system appearances, because Finder does not swap background images. Finder's default dark label text stays legible on it.

## Regenerate

```sh
swift docs/installer/render-background.swift Sources/GPTVoice/Resources/Fonts docs/installer
tiffutil -cathidpicheck docs/installer/background.png docs/installer/background@2x.png -out docs/installer/background.tiff
```

The WaveMark and arrow use original vector paths drawn by the renderer.
