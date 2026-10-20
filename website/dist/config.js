/* Enable releaseReady only after the signed, notarized DMG is published.
 * Pending download buttons point to the install section. */
window.GPTV_CONFIG = {
  releaseReady: false,

  // Leave empty until a public binary release is ready.
  version: "",

  repoUrl: "https://github.com/entropyconquers/gpt-voice",
  releaseUrl: "https://github.com/entropyconquers/gpt-voice/releases/latest",
  dmgUrl: "https://github.com/entropyconquers/gpt-voice/releases/latest/download/GPT-Voice.dmg",

  video: {
    src: "assets/gpt-voice-promo.mp4",
    poster: "assets/promo-poster.jpg",
  },
};
