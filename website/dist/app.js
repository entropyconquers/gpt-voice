/* GPT Voice website. Plain script, no dependencies.
 * The hero demo is scripted: no microphone, no clipboard, no network. */
(function () {
  "use strict";

  var cfg = window.GPTV_CONFIG || {};
  var $ = function (sel, root) { return (root || document).querySelector(sel); };
  var $$ = function (sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); };
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

  /* ---------- Config: links and release state ---------- */

  function applyConfig() {
    var ready = cfg.releaseReady === true;
    // No public release until signing is done: Download stays on this page (#install),
    // which says so and links to building from source.
    var hrefs = {
      download: ready ? cfg.dmgUrl : "#install",
      repo: cfg.repoUrl,
      release: ready ? cfg.releaseUrl : cfg.repoUrl + "/releases",
      source: cfg.repoUrl + "#build-from-source",
    };
    $$("[data-link]").forEach(function (a) {
      var href = hrefs[a.getAttribute("data-link")];
      if (href) a.setAttribute("href", href);
    });
    $$("[data-when]").forEach(function (el) {
      el.hidden = el.getAttribute("data-when") !== (ready ? "ready" : "pending");
    });
    $$("[data-version]").forEach(function (el) {
      el.textContent = ready && cfg.version ? "Version " + cfg.version + " · " : "";
    });
  }

  /* ---------- Header border on scroll ---------- */

  function initHeader() {
    var header = $(".site-header");
    if (!header) return;
    var onScroll = function () { header.classList.toggle("is-scrolled", window.scrollY > 4); };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
  }

  /* ---------- Reveal on scroll (once) ---------- */

  function initReveal() {
    var items = $$(".reveal");
    if (!("IntersectionObserver" in window)) {
      items.forEach(function (el) { el.classList.add("is-in"); });
      return;
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-in");
          io.unobserve(entry.target);
        }
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
    items.forEach(function (el) { io.observe(el); });
  }

  /* ---------- Film ---------- */

  function initFilm() {
    var frame = $("#film-frame");
    var video = $("#film-video");
    var play = $("#film-play");
    var missing = $("#film-missing");
    if (!frame || !video) return;
    var source = $("source[data-video-src]", video);
    var v = cfg.video || {};
    if (v.poster) video.setAttribute("poster", v.poster);
    if (v.src && source) {
      source.setAttribute("src", v.src);
      video.load();
    }

    function showMissing() {
      if (missing) missing.hidden = false;
      if (play) play.hidden = true;
    }
    if (!v.src) { showMissing(); return; }

    if (source) source.addEventListener("error", showMissing);
    // Over http, check the file exists so the play button never leads nowhere.
    if (/^https?:/.test(location.protocol) && window.fetch) {
      fetch(v.src, { method: "HEAD" }).then(function (r) { if (!r.ok) showMissing(); }).catch(function () {});
    }

    if (play) {
      play.addEventListener("click", function () {
        frame.classList.add("is-playing");
        var p = video.play();
        if (p && p.catch) p.catch(function () { frame.classList.remove("is-playing"); });
        video.focus({ preventScroll: true });
      });
    }
    video.addEventListener("play", function () { frame.classList.add("is-playing"); });
    video.addEventListener("ended", function () { frame.classList.remove("is-playing"); });
  }

  /* ---------- Radio groups (roving focus) ---------- */

  function radioGroup(group, onChange) {
    var radios = $$('[role="radio"]', group);
    function select(r, focus) {
      radios.forEach(function (x) {
        var on = x === r;
        x.setAttribute("aria-checked", on ? "true" : "false");
        x.tabIndex = on ? 0 : -1;
      });
      if (focus) r.focus();
      onChange(r);
    }
    radios.forEach(function (r) {
      r.tabIndex = r.getAttribute("aria-checked") === "true" ? 0 : -1;
      r.addEventListener("click", function () { select(r, false); });
      r.addEventListener("keydown", function (e) {
        var i = radios.indexOf(r);
        var next = null;
        if (e.key === "ArrowRight" || e.key === "ArrowDown") next = radios[(i + 1) % radios.length];
        if (e.key === "ArrowLeft" || e.key === "ArrowUp") next = radios[(i - 1 + radios.length) % radios.length];
        if (next) { e.preventDefault(); select(next, true); }
      });
    });
    return {
      set: function (value, attr) {
        var r = radios.filter(function (x) { return x.getAttribute(attr) === value; })[0];
        if (r) select(r, false);
      },
    };
  }

  /* ---------- Hero preview ---------- */

  // What the "voice" says. Deliberately full of the jargon people dictate into coding tools.
  var SAMPLES = [
    "Rename fetchSessionToken to refreshAccessToken, and make the retry backoff exponential with jitter. Leave the Keychain code alone.",
    "Add a Vitest case for the no-speech path in useDictation, and mock MediaRecorder so CI stays green.",
    "Write a migration that backfills user_id on the events table in batches of five thousand. Keep it idempotent.",
  ];

  var ICON = {
    x: '<svg class="i" aria-hidden="true"><use href="#i-regular-x"/></svg>',
    stop: '<svg class="i" aria-hidden="true"><use href="#i-fill-stop"/></svg>',
    ok: '<svg class="i ok" aria-hidden="true"><use href="#i-fill-check-circle"/></svg>',
    clip: '<svg class="i muted-icon" aria-hidden="true"><use href="#i-regular-clipboard-text"/></svg>',
    silent: '<svg class="i muted-icon" aria-hidden="true"><use href="#i-regular-waveform-slash"/></svg>',
  };
  var WEIGHTS = [0.55, 0.8, 1, 0.8, 0.55]; // same bar shape as the app's level meter

  function initDemo() {
    var demo = $("#demo");
    if (!demo) return;

    var el = {
      pill: $("#pill"),
      inner: $("#pill-inner"),
      keys: $("#keys"),
      keysHint: $("#keys-hint"),
      voice: $("#voice-text"),
      composer: $("#composer-text"),
      pasteBtn: $("#paste-btn"),
      live: $("#demo-live"),
      settingsBtn: $("#demo-settings-btn"),
      settings: $("#demo-settings"),
      reset: $("#demo-reset"),
      pasteSwitch: $("#paste-switch"),
    };

    var DEFAULTS = { scenario: "talk", autoPaste: true, theme: "system", accent: "graphite" };
    var s = {}; // runtime state, filled by reset()
    var timers = [];
    var ticker = null;

    // Idle invitation on the keycaps (CSS: .is-inviting). It runs only while the demo is on
    // screen and the tab is visible, stops at the first recording, and comes back after Reset.
    var invite = { wanted: true, inView: false };
    function updateInvite() {
      demo.classList.toggle("is-inviting",
        invite.wanted && invite.inView && !document.hidden && !reduceMotion.matches);
    }

    function later(fn, ms) { var t = setTimeout(fn, ms); timers.push(t); return t; }
    function clearTimers() {
      timers.forEach(clearTimeout); timers = [];
      if (ticker) { clearInterval(ticker); ticker = null; }
    }

    function announce(text) {
      el.live.textContent = "";
      requestAnimationFrame(function () { el.live.textContent = text; });
    }

    function setState(name) {
      s.state = name;
      demo.setAttribute("data-state", name);
      var recording = name === "recording";
      el.keys.setAttribute("aria-label", recording
        ? "Stop and transcribe (Control Option Space)"
        : "Start dictation (Control Option Space)");
      el.keysHint.textContent = recording ? "Press again" : "Try it";
    }

    /* Pill: one surface that resizes between states, like the app's overlay. */
    function renderPill(html, opts) {
      opts = opts || {};
      var pill = el.pill, inner = el.inner;
      // Visibility is class-based (.is-hidden) so the fade-out can run. Clear any stray hidden
      // attribute first: display:none would also make the measurements below read zero.
      pill.hidden = false;
      var wasHidden = pill.classList.contains("is-hidden");
      var from = pill.getBoundingClientRect();
      inner.className = "pill-inner" + (opts.card ? " notice" : "");
      inner.innerHTML = html;
      pill.classList.toggle("is-card", !!opts.card);
      var toW = inner.offsetWidth + 2;
      var toH = inner.offsetHeight + 2;
      if (wasHidden || reduceMotion.matches) {
        pill.style.width = toW + "px";
        pill.style.height = toH + "px";
      } else {
        pill.style.width = from.width + "px";
        pill.style.height = from.height + "px";
        void pill.offsetWidth; // commit the start size before animating
        pill.style.width = toW + "px";
        pill.style.height = toH + "px";
      }
      inner.classList.remove("enter");
      void inner.offsetWidth;
      if (!wasHidden) inner.classList.add("enter");
      pill.classList.remove("is-hidden");
    }
    function hidePill() { el.pill.classList.add("is-hidden"); }

    function fmt(sec) {
      sec = Math.floor(sec);
      return Math.floor(sec / 60) + ":" + (sec % 60 < 10 ? "0" : "") + (sec % 60);
    }

    function meterHTML() {
      return '<span class="meter" aria-hidden="true">' + WEIGHTS.map(function () { return "<i></i>"; }).join("") + "</span>";
    }

    function renderRecording() {
      renderPill(
        '<span class="rec-dot" role="img" aria-label="Recording"></span>' +
        meterHTML() +
        '<span class="time">0:00</span>' +
        '<button type="button" class="p-btn" data-act="cancel" aria-label="Cancel dictation">' + ICON.x + "</button>" +
        '<button type="button" class="p-btn p-btn-stop" data-act="stop" aria-label="Stop and transcribe">' + ICON.stop + "</button>"
      );
    }

    function renderWorking(label, cancellable) {
      renderPill(
        '<span class="spinner" aria-hidden="true"></span>' +
        '<span class="label label-min">' + label + "</span>" +
        (cancellable
          ? '<button type="button" class="p-btn" data-act="cancel" aria-label="Cancel dictation">' + ICON.x + "</button>"
          : '<span style="width:6px"></span>')
      );
    }

    function renderMessage(icon, label) {
      renderPill(icon + '<span class="label" style="padding-right:8px">' + label + "</span>");
    }

    function renderNotice() {
      renderPill(
        ICON.clip +
        "<strong>Copied to clipboard</strong>" +
        "<span>Press ⌘V to paste.</span>",
        { card: true }
      );
    }

    // Level meter and timer. Levels are scripted: they follow the simulated words, not a microphone.
    function setLevels(levels) {
      var bars = $$(".meter i", el.inner);
      bars.forEach(function (b, i) { b.style.setProperty("--h", String(levels[i])); });
    }
    function tick() {
      var t = (performance.now() - s.t0) / 1000;
      var time = $(".time", el.inner);
      if (time) time.textContent = fmt(t);
      var talking = s.scenario === "talk" && s.spoken < s.words.length && s.spoken > 0;
      var base = talking ? 0.35 + 0.6 * Math.abs(Math.sin(t * 7.3) * Math.sin(t * 2.3 + s.spoken)) : 0.06;
      setLevels(WEIGHTS.map(function (w, i) {
        var jitter = talking ? 0.12 * Math.sin(t * 11 + i * 1.7) : 0;
        return Math.max(0.12, Math.min(1, w * (base + jitter)));
      }));
      if (t > 30) stop(); // safety cap for a forgotten preview
    }

    function renderComposer() {
      var c = el.composer;
      c.textContent = "";
      if (!s.segments.length) {
        c.insertAdjacentHTML("beforeend", '<span class="caret" aria-hidden="true"></span><span class="placeholder">Ask anything</span>');
        return;
      }
      s.segments.forEach(function (seg, i) {
        if (i > 0) c.appendChild(document.createTextNode(" "));
        var span = document.createElement("span");
        span.textContent = seg.text;
        if (seg.fresh) { span.className = "pasted"; seg.fresh = false; }
        c.appendChild(span);
      });
      c.insertAdjacentHTML("beforeend", '<span class="caret" aria-hidden="true"></span>');
      c.scrollTop = c.scrollHeight;
    }

    function insertText(text) {
      s.segments.push({ text: text, fresh: true });
      renderComposer();
    }

    function showPasteButton(on) { el.pasteBtn.hidden = !on; }

    /* Flow */

    function start() {
      invite.wanted = false;
      updateInvite();
      clearTimers();
      setState("recording");
      s.words = SAMPLES[s.run % SAMPLES.length].split(" ");
      s.spoken = 0;
      s.t0 = performance.now();
      el.voice.textContent = "";
      renderRecording();
      announce("Recording");
      ticker = setInterval(tick, reduceMotion.matches ? 250 : 80);
      tick();

      if (s.scenario === "silent") {
        el.voice.textContent = "…";
        return;
      }
      var at = 450;
      s.words.forEach(function (word) {
        later(function () {
          s.spoken += 1;
          var span = document.createElement("span");
          span.className = "w";
          span.textContent = (s.spoken > 1 ? " " : "") + word;
          el.voice.appendChild(span);
        }, at);
        at += 300 + (/[,.]$/.test(word) ? 260 : 0);
      });
    }

    function stop() {
      if (s.state !== "recording") return;
      clearTimers();
      var text = s.scenario === "talk" ? s.words.slice(0, s.spoken).join(" ") : "";
      setState("transcribing");
      renderWorking("Transcribing", true);
      announce("Transcribing");
      later(function () {
        if (!text) {
          setState("nospeech");
          renderMessage(ICON.silent, "No speech found");
          announce("No speech found");
          later(finish, 2600);
          return;
        }
        s.run += 1;
        if (s.autoPaste) {
          setState("pasting");
          renderWorking("Pasting", false);
          later(function () {
            insertText(text);
            setState("pasted");
            renderMessage(ICON.ok, "Pasted");
            announce("Pasted into the demo workspace. Not sent.");
            later(finish, 1800);
          }, 380);
        } else {
          s.clipboard = text;
          showPasteButton(true);
          setState("copied");
          // First time: the help card stays longer. After that, the short message hides after 3s, like the app.
          var firstHelp = !s.helpShown;
          if (firstHelp) {
            s.helpShown = true;
            renderNotice();
          } else {
            renderMessage(ICON.clip, "Press ⌘V to paste");
          }
          announce("Copied to clipboard. Press Command V, or use the Paste button, to paste.");
          later(finish, firstHelp ? 9000 : 3000);
        }
      }, 1050);
    }

    function cancel() {
      if (s.state !== "recording" && s.state !== "transcribing") return;
      clearTimers();
      el.voice.textContent = "";
      setState("idle");
      hidePill();
      announce("Dictation cancelled");
    }

    function finish() {
      setState("idle");
      hidePill();
    }

    function toggle() {
      if (s.state === "recording") stop();
      else if (s.state === "transcribing" || s.state === "pasting") return;
      else start();
    }

    function manualPaste() {
      if (!s.clipboard) return false;
      insertText(s.clipboard);
      s.clipboard = null;
      showPasteButton(false);
      if (s.state === "copied") { clearTimers(); finish(); }
      announce("Pasted into the demo workspace. Not sent.");
      return true;
    }

    /* Settings */

    var scenarioGroup = radioGroup($('[aria-labelledby="lbl-scenario"]', demo), function (r) {
      s.scenario = r.getAttribute("data-scenario");
    });
    var themeGroup = radioGroup($('[aria-labelledby="lbl-theme"]', demo), function (r) {
      s.theme = r.getAttribute("data-theme-choice");
      demo.setAttribute("data-theme", s.theme);
    });
    var accentGroup = radioGroup($('[aria-labelledby="lbl-accent"]', demo), function (r) {
      s.accent = r.getAttribute("data-accent-choice");
      document.documentElement.setAttribute("data-accent", s.accent);
      $$("[data-accent-try]").forEach(function (b) {
        b.setAttribute("aria-pressed", b.getAttribute("data-accent-try") === s.accent ? "true" : "false");
      });
    });
    $$("[data-accent-try]").forEach(function (b) {
      b.addEventListener("click", function () { accentGroup.set(b.getAttribute("data-accent-try"), "data-accent-choice"); });
    });

    function setAutoPaste(on) {
      s.autoPaste = on;
      el.pasteSwitch.setAttribute("aria-checked", on ? "true" : "false");
    }
    el.pasteSwitch.addEventListener("click", function () { setAutoPaste(!s.autoPaste); });

    function setSettingsOpen(open) {
      el.settings.hidden = !open;
      el.settingsBtn.setAttribute("aria-expanded", open ? "true" : "false");
    }
    el.settingsBtn.addEventListener("click", function () { setSettingsOpen(el.settings.hidden); });
    document.addEventListener("click", function (e) {
      if (el.settings.hidden) return;
      if (el.settings.contains(e.target) || el.settingsBtn.contains(e.target)) return;
      setSettingsOpen(false);
    });

    function reset(quiet) {
      clearTimers();
      s = { state: "idle", run: 0, segments: [], clipboard: null, helpShown: false, words: [], spoken: 0, t0: 0 };
      scenarioGroup.set(DEFAULTS.scenario, "data-scenario");
      themeGroup.set(DEFAULTS.theme, "data-theme-choice");
      accentGroup.set(DEFAULTS.accent, "data-accent-choice");
      setAutoPaste(DEFAULTS.autoPaste);
      setSettingsOpen(false);
      el.voice.textContent = "";
      showPasteButton(false);
      setState("idle");
      hidePill();
      renderComposer();
      invite.wanted = true;
      updateInvite();
      if (!quiet) announce("Preview reset");
    }
    el.reset.addEventListener("click", function () { reset(false); });

    /* Input */

    el.keys.addEventListener("click", toggle);
    el.pasteBtn.addEventListener("click", manualPaste);
    el.pill.addEventListener("click", function (e) {
      var b = e.target.closest("[data-act]");
      if (!b) return;
      if (b.getAttribute("data-act") === "stop") stop();
      if (b.getAttribute("data-act") === "cancel") cancel();
    });

    function isTextInput(t) {
      return t && (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName));
    }

    document.addEventListener("keydown", function (e) {
      if (e.ctrlKey && e.altKey && !e.metaKey && e.code === "Space") {
        e.preventDefault();
        if (!e.repeat) { el.keys.classList.add("is-down"); toggle(); }
        return;
      }
      if (e.key === "Escape") {
        if (!el.settings.hidden) { setSettingsOpen(false); el.settingsBtn.focus(); return; }
        if (s.state === "recording" || s.state === "transcribing") { e.preventDefault(); cancel(); }
        return;
      }
      if ((e.metaKey || e.ctrlKey) && !e.altKey && (e.key === "v" || e.key === "V") && s.clipboard && !isTextInput(e.target)) {
        e.preventDefault();
        manualPaste();
      }
    });
    document.addEventListener("keyup", function (e) {
      if (e.code === "Space" || e.key === "Control" || e.key === "Alt") el.keys.classList.remove("is-down");
    });
    window.addEventListener("blur", function () { el.keys.classList.remove("is-down"); });

    reset(true);

    if ("IntersectionObserver" in window) {
      new IntersectionObserver(function (entries) {
        invite.inView = entries[entries.length - 1].isIntersecting;
        updateInvite();
      }, { threshold: 0.35 }).observe(demo);
    } else {
      invite.inView = true;
      updateInvite();
    }
    document.addEventListener("visibilitychange", updateInvite);
    if (reduceMotion.addEventListener) reduceMotion.addEventListener("change", updateInvite);
    else if (reduceMotion.addListener) reduceMotion.addListener(updateInvite);

    /* ?demo=recording|transcribing|pasted|copied|notice|nospeech|settings freezes a state for screenshots and QA. */
    var freeze = new URLSearchParams(location.search).get("demo");
    if (freeze) freezeState(freeze);

    function freezeState(name) {
      var words = SAMPLES[0].split(" ");
      invite.wanted = false;
      updateInvite();
      if (name === "settings") { setSettingsOpen(true); return; }
      if (name === "recording") {
        setState("recording");
        renderRecording();
        el.voice.textContent = words.slice(0, 9).join(" ");
        $(".time", el.inner).textContent = "0:04";
        setLevels([0.5, 0.75, 0.95, 0.7, 0.45]);
      } else if (name === "transcribing") {
        setState("transcribing");
        renderWorking("Transcribing", true);
      } else if (name === "pasted") {
        s.segments.push({ text: SAMPLES[0], fresh: false });
        renderComposer();
        setState("pasted");
        renderMessage(ICON.ok, "Pasted");
      } else if (name === "copied") {
        s.clipboard = SAMPLES[0]; s.helpShown = true;
        showPasteButton(true);
        setState("copied");
        renderMessage(ICON.clip, "Press ⌘V to paste");
      } else if (name === "notice") {
        s.clipboard = SAMPLES[0]; s.helpShown = true;
        showPasteButton(true);
        setState("copied");
        renderNotice();
      } else if (name === "nospeech") {
        setState("nospeech");
        renderMessage(ICON.silent, "No speech found");
      }
    }
  }

  /* ---------- Boot ---------- */

  applyConfig();
  initHeader();
  initReveal();
  initFilm();
  initDemo();
})();
