/* releaseReady: a public DMG is published. This preview is development-signed and not notarized,
 * and the site says so beside every download. When false, download buttons point to the install section. */
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
