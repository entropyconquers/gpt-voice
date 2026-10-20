# GPT Voice website

Static site, no build step. Everything that gets hosted is in `dist/`.

- `dist/index.html`: the page (inline icon sprite).
- `dist/styles.css`: page styles.
- `dist/app.js`: link and release-state wiring, scroll reveals, the film player, the scripted hero demo and the accent swatches in the features grid. The demo does not access the microphone or clipboard.
- `dist/config.js`: the only file to edit for a release (`releaseReady`, `version`, URLs, video paths).
- `dist/CREDITS.txt`: icon and media credits.

Preview locally:

    cd website/dist && python3 -m http.server 4173
    # open http://localhost:4173

Freeze the hero preview in one state for screenshots: `?demo=recording`, `transcribing`, `pasted`, `copied`, `notice`, `nospeech` or `settings`.

The promo and poster are in `dist/assets/`.

The live site is https://entropyconquers.github.io/gpt-voice/.
Changes to `website/dist/` on `main` deploy through `.github/workflows/pages.yml`.
