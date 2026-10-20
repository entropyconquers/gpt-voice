#!/usr/bin/env python3
"""Create a Finder disk image. Install dmgbuild==1.6.7 in a build environment."""
import argparse
import hashlib
import json
import plistlib
import subprocess
from pathlib import Path


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=Path, default=Path('dist/GPT Voice.app'))
    parser.add_argument('--output', type=Path, default=Path('dist/GPT-Voice.dmg'))
    parser.add_argument('--preview', action='store_true', help='Allow an unnotarized preview. Never marks it verified.')
    args = parser.parse_args()
    app = args.app.resolve()
    output = args.output.resolve()
    root = Path(__file__).resolve().parents[1]
    background = root / 'docs/installer/background.png'
    if not app.is_dir() or not background.is_file():
        parser.error('Build the app and installer background first.')
    subprocess.run(['codesign', '--verify', '--strict', str(app)], check=True)
    signature = subprocess.run(['codesign', '-dvv', str(app)], capture_output=True, text=True, check=True).stderr
    developer_id = 'Authority=Developer ID Application:' in signature
    if not args.preview:
        if not developer_id:
            parser.error('A public release requires Developer ID signing. Use --preview only for an explicitly labeled preview.')
        subprocess.run(['xcrun', 'stapler', 'validate', str(app)], check=True)
        subprocess.run(['spctl', '--assess', '--type', 'execute', '--verbose=2', str(app)], check=True)
    import dmgbuild
    output.parent.mkdir(parents=True, exist_ok=True)
    dmgbuild.build_dmg(str(output), 'GPT Voice', settings={
        'format': 'UDZO', 'compression_level': 9, 'filesystem': 'HFS+',
        'files': [str(app)], 'symlinks': {'Applications': '/Applications'},
        'background': str(background),
        'badge_icon': str(app / 'Contents/Resources/AppIcon.icns'),
        'icon_locations': {'GPT Voice.app': (210, 255), 'Applications': (550, 255)},
        'window_rect': ((160, 120), (760, 560)), 'icon_size': 112, 'text_size': 13,
        'show_toolbar': False, 'show_status_bar': False, 'show_pathbar': False,
        'show_sidebar': False, 'default_view': 'icon-view', 'include_icon_view_settings': True,
        'hide_extensions': ['GPT Voice.app'], 'applications_menu': False,
    })
    subprocess.run(['hdiutil', 'verify', str(output)], check=True)
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    report = {'file': output.name, 'version': info['CFBundleShortVersionString'],
              'architectures': run('lipo', '-archs', str(app / 'Contents/MacOS/GPTVoice')).strip(),
              'preview': args.preview, 'developer_id': developer_id,
              'notarized_app_verified': not args.preview,
              'sha256': hashlib.sha256(output.read_bytes()).hexdigest()}
    output.with_suffix('.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
