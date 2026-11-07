## Build 1.0.0 — final rebuilt release

**Built:** 2026-11-07
**Install:** final package not installed yet; device verification pending.

**Builds:**
- `builds/com.burc334.alwaysshowemojikey_1.0.0_iphoneos-arm64.deb`
  SHA-256: `21b797488337dc873366f7e0f190c0a8fa338755c0ef249d5b27b77357e1b12d`
- `builds/com.burc334.alwaysshowemojikey_1.0.0_iphoneos-arm64e.deb`
  SHA-256: `e52a83fea5101281252cdb723b5feee132beaca33d81821c22bec647a48352cc`

### Result

Final 1.0.0 package built with the new icon, package identity, and
documentation. Device install and visual verification remain pending.

# Testing

## Target environment

- Device: iPhone 11 Pro Max
- iOS: 18.4.1
- Jailbreak: Dopamine 3 + RootHide
- Build under test: RootHide `iphoneos-arm64e`

## Acceptance criteria

- The native emoji key appears between `123` and the spacebar.
- The emoji key does not overlap the `123` key.
- Tapping the emoji key opens the emoji keyboard.
- The `123` key remains tappable and opens the number/symbol plane.
- Disabling Emoji in Settings removes the extra key.
- Secure text entry does not show the key.
- The keyboard remains usable with English and Turkish keyboards enabled.
- DockX Dock Mode `None` and Skip Emoji ON remain usable.

## Final artifact verification

The implementation was tested on the RootHide build during development. The final release debs include metadata-only changes (`Depiction` and `SileoDepiction`) and must be installed and retested before publication.

- [ ] Install final rootless `iphoneos-arm64` deb on a rootless device.
- [ ] Install final RootHide `iphoneos-arm64e` deb on the target device.
- [ ] Re-run the acceptance criteria on the final RootHide artifact.
- [ ] Confirm no crash report is generated.
- [ ] Confirm the final package hashes match `SHA256SUMS.txt`.
