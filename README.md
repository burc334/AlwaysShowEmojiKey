<p align="center">
  <img src="docs/icon.png" width="160" alt="Always Show Emoji Key icon">
</p>

# Always Show Emoji Key

<p align="center"><strong>Always Show Emoji Key is a rootless iOS 18 jailbreak tweak that keeps the native emoji key visible and usable next to the spacebar.</strong></p>

- Package: `com.burc334.alwaysshowemojikey`
- Version: `1.0.1`
- Tested: iOS 18.4.1 (Dopamine 3, roothide) on iPhone 11 Pro Max
- Builds: rootless (`iphoneos-arm64`) and roothide (`iphoneos-arm64e`)
- License: MIT

## Compatibility

| Build | Architecture | Compatibility |
|---|---|---|
| roothide | `iphoneos-arm64e` | Tested on iOS 18.4.1 (Dopamine 3, roothide) |
| rootless | `iphoneos-arm64` | Expected to work on iOS 18+ rootless jailbreaks |

The tweak requires iOS 18.0 or later. The rootless build is available for iOS 18+ but was not independently tested.

## What it does

- Keeps the native emoji key between `123` and the spacebar.
- Lets the emoji key be tapped normally.
- Uses the native keyboard keyplane and key views.
- Does not use a custom key, overlay, or manual key placement.
- Does not change the keyboard language list or the Emoji keyboard setting.

## How it works

iOS 18 can merge the native international/emoji key into the `123` key. Always Show Emoji Key prevents that merge for the international key and lets the native keyplane lay out the keys separately. No preference pane is required.

## Install

### Sileo

Add `https://burc334.github.io/apt/` in Sileo, then install Always Show Emoji Key.

### Manual

1. Download the deb matching your jailbreak from the latest GitHub release:
   - roothide: `com.burc334.alwaysshowemojikey_1.0.1_iphoneos-arm64e.deb`
   - rootless: `com.burc334.alwaysshowemojikey_1.0.1_iphoneos-arm64.deb`
2. Install it with Sileo, Zebra, or Filza.
3. Respring if the keyboard does not reload automatically.

## Build

```sh
export THEOS=$HOME/theos
make clean package FINALPACKAGE=1
./tools/make-roothide.sh
```

The rootless deb is written to `packages/`. The roothide script converts the latest rootless package to `iphoneos-arm64e`.

## Verification

SHA-256 checksums are published in `SHA256SUMS.txt` with the GitHub release. Verify the downloaded deb before installing it.

## Support

Open an issue on the [GitHub repository](https://github.com/burc334/AlwaysShowEmojiKey/issues). Include your iOS version, jailbreak, device model, and Always Show Emoji Key version.

## License

MIT

AI-assisted development with DeepSeek-V4.1-Flash-1017.
