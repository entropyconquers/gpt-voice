# Troubleshooting

## Sign-in

Install [Codex CLI](https://developers.openai.com/codex/cli/) before starting browser sign-in.
GPT Voice checks `/opt/homebrew/bin`, `/usr/local/bin`, `~/.local/bin` and the app's PATH for `codex`.
If a custom installation is not found, place the executable in one of those locations, then reopen the app.

Select **Sign in with ChatGPT** in the app. The flow uses Codex CLI's browser login.
The current build reads file-backed sessions in `~/.codex/auth.json`, or the directory set by `CODEX_HOME`.
It does not read keychain-only sessions. Do not paste access tokens into issues or send them to the maintainer.

If an account request fails after sign-in, try signing in again.
The private transcription endpoint can reject accounts or change. A subscription does not guarantee access to this third-party client.

## Microphone

Open **System Settings → Privacy & Security → Microphone** and enable GPT Voice.
Return to the app to refresh its status.
If macOS did not yet list the app, select **Allow** inside GPT Voice to request access.

## Accessibility and paste

Accessibility is optional. Choose manual paste to copy text and paste it with Command–V.
For automatic paste, enable GPT Voice in **System Settings → Privacy & Security → Accessibility**.
Return to the app, or select its refresh button.
The status check also tries a read-only Accessibility request if macOS has not refreshed its trust flag.

A local rebuild can change an ad hoc signature. macOS can keep an old switch on while rejecting the new build.
In that case, remove the old GPT Voice entry from Accessibility and add the current app again.
Quit and reopen the app after macOS applies the change.
For repeated local builds, use the same valid signing certificate. An ad hoc signature changes with the executable.
Do not reset all privacy permissions or disable macOS protections.

Paste can fall back to copy if the destination app, focus, or clipboard changes during a recording.
This protects newer clipboard content and avoids sending text to the wrong app.
Use **Copy Last Transcript** from the menu bar to recover the last result.

## Shortcut

Use **Settings → Shortcut → Test** to check receipt without recording.
Command–Space often belongs to Spotlight or another app.
Change that competing shortcut, or select a different shortcut in GPT Voice.
The default is Control–Option–Space.

Hold one modifier key, such as Left Option, to record. Let go and the transcript is pasted.
A quick tap does nothing. The microphone opens after a brief hold, so Option can still be used with other keys.
That shortcut needs Input Monitoring. Enable GPT Voice in System Settings → Privacy & Security → Input Monitoring, then quit and reopen the app if the hold does not respond.

## Download and installation

Download the official GitHub release. Open the DMG and drag GPT Voice to Applications.
Eject the image, then open the installed copy.

If macOS shows a verification warning, ignore it and open **System Settings → Privacy & Security → Open Anyway**.
You can also [build from source](../README.md#build-from-source).

## Diagnostics

```sh
"/Applications/GPT Voice.app/Contents/MacOS/GPTVoice" --diagnose
```

Review the output before sharing it. It does not print account credentials.
A command launched from a terminal can have a different macOS privacy context from a Finder-launched app.
Check permission behavior in the actual installed app as well.

## History

Successful transcriptions appear in **Settings → History**, newest first.
Copy an entry, delete one entry, or use **Clear all**. Deletion requires confirmation.
The app saves local dates and times. It shows the destination name when paste keystrokes were sent to a known app.
A manual paste cannot be tracked.

If History reports a save error, keep GPT Voice open and select **Try again**.
An unreadable history file is kept intact. GPT Voice does not replace it with an empty history.
