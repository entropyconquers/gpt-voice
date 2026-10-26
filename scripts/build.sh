#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"
install_app=false
universal=false
for option in "$@"; do
  case "$option" in
    --install) install_app=true ;;
    --universal) universal=true ;;
    *) echo "Usage: $0 [--install] [--universal]" >&2; exit 2 ;;
  esac
done
app_version=$(cat VERSION)
build_number=$(cat BUILD_NUMBER)
[[ "$app_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid VERSION" >&2; exit 1; }
[[ "$build_number" =~ ^[0-9]+$ ]] || { echo "Invalid BUILD_NUMBER" >&2; exit 1; }
check_launch() {
  python3 - "$1/Contents/MacOS/GPTVoice" <<'PYTHON'
import json, subprocess, sys
try:
    result = subprocess.run([sys.argv[1], "--diagnose"], capture_output=True, timeout=8, check=True)
    json.loads(result.stdout)
except (subprocess.SubprocessError, ValueError) as error:
    sys.exit(f"The new app did not pass its launch check. Existing apps were kept. {error}")
PYTHON
}
if $universal; then
  swift build -c release --arch arm64 --scratch-path .build/release-arm64
  swift build -c release --arch x86_64 --scratch-path .build/release-x86_64
  binary_dir=$(swift build -c release --arch arm64 --scratch-path .build/release-arm64 --show-bin-path)
  intel_binary_dir=$(swift build -c release --arch x86_64 --scratch-path .build/release-x86_64 --show-bin-path)
else
  swift build -c release
  binary_dir=$(swift build -c release --show-bin-path)
fi
build_staging_dir=$(mktemp -d "$project_dir/.build/gpt-voice-bundle.XXXXXX")
trap 'rm -rf "$build_staging_dir"' EXIT
app_dir="$build_staging_dir/GPT Voice.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
if $universal; then
  lipo -create "$binary_dir/GPTVoice" "$intel_binary_dir/GPTVoice" -output "$app_dir/Contents/MacOS/GPTVoice"
  architectures=$(lipo -archs "$app_dir/Contents/MacOS/GPTVoice")
  [[ " $architectures " == *" arm64 "* && " $architectures " == *" x86_64 "* ]] \
    || { echo "The universal app is missing an architecture." >&2; exit 1; }
else
  cp "$binary_dir/GPTVoice" "$app_dir/Contents/MacOS/GPTVoice"
fi
resource_bundle="$binary_dir/GPTVoice_GPTVoice.bundle"
if [[ -d "$resource_bundle" ]]; then
  rm -rf "$app_dir/Contents/Resources/GPTVoice_GPTVoice.bundle"
  ditto "$resource_bundle" "$app_dir/Contents/Resources/GPTVoice_GPTVoice.bundle"
fi
icon_dir="$project_dir/.build/AppIcon.iconset"
mkdir -p "$icon_dir"
swift scripts/generate-icon.swift "$icon_dir/icon_512x512@2x.png" 1024
for icon_size in 16 32 128 256 512; do
  sips -z "$icon_size" "$icon_size" "$icon_dir/icon_512x512@2x.png" --out "$icon_dir/icon_${icon_size}x${icon_size}.png" >/dev/null
  retina_size=$((icon_size * 2))
  if [[ "$retina_size" != "1024" ]]; then
    sips -z "$retina_size" "$retina_size" "$icon_dir/icon_512x512@2x.png" --out "$icon_dir/icon_${icon_size}x${icon_size}@2x.png" >/dev/null
  fi
done
iconutil -c icns "$icon_dir" -o "$app_dir/Contents/Resources/AppIcon.icns"
cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>GPTVoice</string>
<key>CFBundleIdentifier</key><string>com.vishesh.codex-dictation</string>
<key>CFBundleName</key><string>GPT Voice</string>
<key>CFBundleDisplayName</key><string>GPT Voice</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.0.0</string>
<key>CFBundleVersion</key><string>0</string>
<key>CFBundleIconFile</key><string>AppIcon.icns</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSMicrophoneUsageDescription</key><string>Record your voice when you start dictation. Audio is sent to ChatGPT to convert speech to text.</string>
<key>NSInputMonitoringUsageDescription</key><string>Detect when you hold the dictation shortcut, including Option by itself. Typed characters are not recorded or stored.</string>
</dict></plist>
PLIST
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $app_version" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set CFBundleVersion $build_number" "$app_dir/Contents/Info.plist"
signing_identity="${GPT_VOICE_SIGNING_IDENTITY:-${CODEX_DICTATION_SIGNING_IDENTITY:-}}"
if [[ -z "$signing_identity" && -f "$project_dir/.local-signing-identity" ]]; then
  IFS= read -r signing_identity < "$project_dir/.local-signing-identity"
fi
signing_identity="${signing_identity:--}"
sign_app() {
  if [[ "$signing_identity" == "-" ]]; then
    codesign --force --sign - --timestamp=none --identifier com.vishesh.codex-dictation "$1"
  else
    codesign --force --sign "$signing_identity" --options runtime --timestamp \
      --entitlements "$project_dir/packaging/GPTVoice.entitlements" \
      --identifier com.vishesh.codex-dictation "$1"
  fi
  codesign --verify --strict "$1"
}
sign_app "$app_dir"
codesign --verify --strict "$app_dir"
check_launch "$app_dir"
release_app="$project_dir/dist/GPT Voice.app"
mkdir -p "$project_dir/dist"
if [[ -e "$release_app" ]]; then
  mv "$release_app" "$build_staging_dir/Previous GPT Voice.app"
fi
mv "$app_dir" "$release_app"
app_dir="$release_app"
if $install_app; then
  destination="$HOME/Applications/GPT Voice.app"
  if [[ -e "$destination" ]]; then
    previous_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$destination/Contents/Info.plist")
    [[ "$previous_id" == "com.vishesh.codex-dictation" ]] || { echo "Another app uses this destination." >&2; exit 1; }
  fi
  mkdir -p "$HOME/Applications"
  install_staging_dir=$(mktemp -d "$project_dir/.build/gpt-voice-install.XXXXXX")
  ditto "$app_dir" "$install_staging_dir/GPT Voice.app"
  sign_app "$install_staging_dir/GPT Voice.app"
  check_launch "$install_staging_dir/GPT Voice.app"
  if [[ -e "$destination" ]]; then
    mkdir -p "$project_dir/.build/installed-app-backups"
    ditto -c -k --sequesterRsrc --keepParent "$destination" \
      "$project_dir/.build/installed-app-backups/GPT-Voice-$(date +%Y%m%dT%H%M%S)-$$.app.zip"
    mv "$destination" "$build_staging_dir/Previous Installed GPT Voice.app"
  fi
  mv "$install_staging_dir/GPT Voice.app" "$destination"
  rmdir "$install_staging_dir"
  codesign --verify --strict "$destination"
  legacy_destination="$HOME/Applications/Codex Dictation.app"
  if [[ -d "$legacy_destination" ]]; then
    legacy_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$legacy_destination/Contents/Info.plist")
    if [[ "$legacy_id" == "com.vishesh.codex-dictation" ]]; then
      backup_dir="$project_dir/.build/installed-app-backups"
      mkdir -p "$backup_dir"
      backup_path="$backup_dir/Codex-Dictation-$(date +%Y%m%dT%H%M%S)-$$.app.zip"
      ditto -c -k --sequesterRsrc --keepParent "$legacy_destination" "$backup_path"
      rm -rf "$legacy_destination"
      echo "Previous app saved: $backup_path"
    fi
  fi
  echo "Installed: $destination"
else
  echo "Built: $app_dir"
fi
