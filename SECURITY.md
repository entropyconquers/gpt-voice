# Security

Do not include account tokens, audio, transcripts, or `~/.codex/auth.json` in an issue.
Use [GitHub private vulnerability reporting](https://github.com/entropyconquers/gpt-voice/security/advisories/new) for a security report.

GPT Voice reads the ChatGPT session that Codex CLI stores on your Mac.
It sends audio only to `https://chatgpt.com/backend-api/transcribe`.
The HTTP client rejects redirects so credentials do not follow another host.
The app does not receive your ChatGPT password.

Accessibility is optional. It permits the app to send Command–V to the selected app.
GPT Voice does not press Return or submit your text.
Review the transcript before you submit it.

The transcription endpoint is private and unsupported for this third-party app.
Access or behavior can change without notice.
