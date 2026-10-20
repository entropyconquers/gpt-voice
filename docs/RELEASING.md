# Releasing GPT Voice

A notarized direct-download release uses **Developer ID Application** signing and Apple notarization.
See the unnotarized release section below for the disclosed v0.1.4 exception.
An App Store Connect app record, TestFlight build and App Store listing are not required.

## Build

1. Update `VERSION` and increase `BUILD_NUMBER`.
2. Run `swift test`.
3. Set `GPT_VOICE_SIGNING_IDENTITY` to the intended Developer ID Application identity.
4. Run `./scripts/build.sh --universal`.

The result is `dist/GPT Voice.app`, with Apple Silicon and Intel executable slices.
The build enables the hardened runtime for certificate-signed builds and includes the microphone entitlement.
It keeps the original bundle identifier for existing settings.

## Notarize the app

Submit a ZIP of the signed app to Apple using your existing notarization credentials.
Wait for an **Accepted** result before proceeding.
Staple the ticket to the app and check it:

```sh
xcrun stapler staple "dist/GPT Voice.app"
xcrun stapler validate "dist/GPT Voice.app"
spctl --assess --type execute --verbose=2 "dist/GPT Voice.app"
```

## Package the installer

Use a separate Python environment for packaging:

```sh
python3 -m venv .local/release-tools
.local/release-tools/bin/pip install dmgbuild==1.6.7
.local/release-tools/bin/python scripts/package-dmg.py
```

The script requires a valid Developer ID signature, a stapled ticket and a passing Gatekeeper assessment.
It creates the themed Finder disk image with an Applications link.
It mounts the result and checks every architecture signature and executable before marking the package ready.
Do not add Finder metadata to the app after signing. In particular, hiding its filename extension can invalidate strict signature checks.
`--preview` permits an explicitly unnotarized local preview. It does not mark the result as verified.

Sign the DMG with Developer ID, submit it for notarization, and staple the accepted ticket.
Run `xcrun stapler validate dist/GPT-Voice.dmg` before release.
Check it with `hdiutil verify` and `spctl --assess --type open --context context:primary-signature --verbose=2`.

## Check the download experience

- Mount the final DMG and inspect its icon layout and instruction text.
- Copy the app to Applications. Eject the DMG before launching the installed copy.
- Test onboarding, sign-in, permissions, a recording, paste and cancel.
- Check light and dark mode and Reduce Motion.
- Download the uploaded asset through its public release URL and compare its SHA-256 checksum.
- Check Gatekeeper with quarantine on the downloaded copy. Do not disable security checks.
- Prefer a separate Mac with no earlier GPT Voice grants for a final first-install check.

Notarization verifies Apple's scan and signing requirements. It does not prove transcription access for every ChatGPT plan.
An Intel slice can be built on Apple Silicon, but Intel execution requires a separate check.

## Publish

Attach `GPT-Voice.dmg`, an app ZIP, checksums, release notes and the promo MP4 to the matching GitHub release.
The website's download link must point to the uploaded release asset.
Update the README, website and launch drafts to the same version and verified release status.
Keep signing keys, credentials and local capture logs out of Git.

## Explicitly disclosed unnotarized releases

The v0.1.4 public download is authorized as an unnotarized build while Developer ID access is unavailable.
It has a valid, stable Apple Development signature. It is not a notarized or Gatekeeper-approved release.

Use `scripts/package-dmg.py --unnotarized` only when the website, README, and release notes state this limit.
This mode requires a certificate signature and records `notarized_app_verified: false` in the packaging report.
Do not label it verified or advise users to disable Gatekeeper.
The normal packaging mode continues to require Developer ID signing, a stapled ticket, and Gatekeeper acceptance.
