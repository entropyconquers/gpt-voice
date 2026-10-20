# Contributing

Start an issue for a new feature or a change to sign-in or audio handling.
Small fixes can go directly to a pull request.

## Local setup

1. Install Xcode Command Line Tools and Python 3 on macOS 13 or later.
2. Clone this repository.
3. Run `swift test`.
4. Run `./scripts/build.sh` to create `dist/GPT Voice.app`.

Use `./scripts/build.sh --install` to install your build in `~/Applications`.
A local build uses ad hoc signing unless you select a certificate.
Changing its signature can require new microphone and Accessibility grants.

Use the same signing identity across local builds when possible.
Set `GPT_VOICE_SIGNING_IDENTITY` or put the identity in `.local-signing-identity`.
Do not commit certificates, keys, or credentials.

## Checks

- Run `swift test` after a behavior change.
- Check the actual app in light and dark mode after a UI change.
- Keep temporary capture files and account data out of tests and issues.
- Explain what changed, why, and how you checked it in your pull request.

The website is a static site in `website/dist`.
Serve it with `python3 -m http.server 4173 --directory website/dist`.
Its interactive preview uses scripted sample text. It does not access the microphone or ChatGPT.

Your contribution uses the project's MIT license. Third-party assets retain their own licenses.
