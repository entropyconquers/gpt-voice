/* releaseReady: true when a public DMG is published. Download buttons then go to dmgUrl and release
 * links to releaseUrl. When false, download buttons go to the install section and release links to the repo's releases page. */
window.GPTV_CONFIG = {
  releaseReady: true,

  version: "0.1.4",

  repoUrl: "https://github.com/entropyconquers/gpt-voice",
  releaseUrl: "https://github.com/entropyconquers/gpt-voice/releases/latest",
  dmgUrl: "https://github.com/entropyconquers/gpt-voice/releases/download/v0.1.4/GPT-Voice-0.1.4-universal.dmg",

  video: {
    src: "assets/gpt-voice-promo.mp4",
    poster: "assets/promo-poster.jpg",
  },
};
