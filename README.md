# TWRP device tree for Xiaomi vermeer (Redmi K70 / POCO F6 Pro, SM8550 / kalama)

TWRP 16 device tree for Redmi K70 (`vermeer`), assembled from:

- **Build skeleton + CI**: the manet (K70 Pro) tree, itself based on
  [YuKongA/twrp_device_xiaomi_sm8850](https://github.com/YuKongA/twrp_device_xiaomi_sm8850) —
  TWRP 16.0 platform + parameterised GitHub Actions builder (`TWRP 16 Builder`).
- **Board values + touch payload**: community vermeer trees
  (keosh1/device_xiaomi_vermeer-TWRP, ByteWave1014/device_xiaomi_vermeer-TWRP).
- **Runtime payload**: adapted from the manet stock recovery environment
  (qseecomd / gatekeeper / keymint / weaver / vibratorfeature), with the
  vermeer goodix touch firmware (`/vendor/firmware/` and `/lib/firmware/`).
- **UI fork**: the GUI2/YARP fork, pinned in CI (`lingqiqi5211`, `taro-lvgl` @ `3b77055`).

## Build (GitHub Actions)

Push to the `device-vermeer` branch builds automatically (TWRP 16 Builder workflow).
Manual trigger: Actions -> **TWRP 16 Builder** -> *Run workflow* (branch defaults are
overridden by the branch resolution step for `device-*` branches).

Output: `TWRP-3.7.1-16-vermeer-<date>.img` — a **ramdisk-only** recovery image
(kernel-less, matching the stock vermeer recovery layout; the running kernel comes from
`boot`). Flash it to the `recovery` partition of the active slot.

## Flash

- bootloader: `fastboot flash recovery TWRP-3.7.1-16-vermeer-*.img`
- existing recovery/root shell: `dd if=TWRP-*.img of=/dev/block/by-name/recovery_<a|b> bs=1M`

## Status

- 2026-10-17: first assembly — not yet through a CI build, **untested on hardware**
  (no device on hand).
- On-device checklist for testers (see `PORTING.md` section 4): colour order (real
  screen, not screenshots), touch, vibration, decryption, MTP, OTG, slot menu,
  screenshot/recording, fastbootd. Collect `/sdcard/recovery.log` plus a photo.
- Known unknowns: weaver backend (`ro.twrp.weaver=nxp` is a guess; see
  `recovery/root/odm/bin/variant-script.sh`), haptics tuning values, SPR bypass.
