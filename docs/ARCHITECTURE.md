# How GPT Voice works

GPT Voice is a native Swift app with AppKit windows and SwiftUI content.
It does not contain extracted ChatGPT application code or a local transcription model.
The implementation sends a request shaped like the transcription request observed in the ChatGPT desktop app.

1. A global shortcut starts AVFoundation audio capture.
2. The second press stops capture.
3. `DictationCore` sends the audio to ChatGPT over HTTPS.
4. The response becomes a transcript.
5. The app pastes it into the original app, or copies it for manual paste.

`Sources/DictationCore` owns credentials, request construction, token renewal and transcript handling.
`Sources/GPTVoice` owns recording, shortcuts, paste delivery, settings and the recording pill.
`Tests` covers request behavior, empty speech, shortcut ownership, practice mode and overlay lifecycle.

Sign-in and token renewal use the installed Codex CLI app-server protocol.
GPT Voice reads the resulting file-backed ChatGPT session. API-key authentication is not supported.
The current implementation does not read Codex sessions stored only in the macOS Keychain.

The service route is `https://chatgpt.com/backend-api/transcribe`.
It is private, undocumented for this use, and can change.
The project does not guarantee access on every plan or for every account.

The recording pill uses short fades and animated width changes.
Reduce Motion removes the blur and resize motion.
Result notices disappear automatically. Recovery actions stay in the menu bar.

## Local history

`TranscriptionHistory` publishes saved transcripts to the History page. It serializes commands and delegates file access to `HistoryRepository`.
The repository writes a versioned JSON document through a private temporary file and an atomic replacement.
Entries contain the exact text, completion time, and delivery result. They do not contain audio, window titles, document paths, or account data.
Normal dictation saves once after delivery. Practice, errors, and cancellation before a result do not create entries. Copying an old result does not duplicate it.
The app waits for pending delivery and history writes before normal quit.
