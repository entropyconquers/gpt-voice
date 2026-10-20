# Privacy

GPT Voice has no developer-operated server, analytics, or account database.
Transcription requires an internet connection and sends recorded audio to ChatGPT.
It does not run an offline speech model.

| Data | Where it goes |
| --- | --- |
| Audio | A private temporary folder on your Mac, then ChatGPT for transcription |
| ChatGPT session | The existing Codex CLI configuration on your Mac |
| Transcript | The selected text field, or your clipboard for manual paste |
| Last transcript | App memory until you quit |
| Preferences | macOS preferences on your Mac |

The app removes owned audio files after successful transcription, cancellation, and normal cleanup.
A failed request can keep its audio for Retry until another recording starts or the app quits.
A crash can leave temporary files until macOS removes them.
The app does not save transcript history.
ChatGPT's handling of uploaded audio is subject to your account settings and OpenAI's policies.

Microphone access permits recording after you start dictation.
Accessibility access permits automatic paste. You can decline it and paste with Command–V instead.
The app rechecks permissions when you return from System Settings.

The website's interactive preview runs in your browser with fixed sample text.
It does not record or upload audio. Its video is a staged demonstration, not an accuracy benchmark.
