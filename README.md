# TWRP device tree for Xiaomi zorn (Redmi K80 / POCO F7 Pro, SM8650 / pineapple)

TWRP 16 device tree for the Redmi K80 (`zorn`), built on the manet
(`twrp_device_xiaomi_sm8650`) framework:

- **Build skeleton + CI**: TWRP 16.0 platform + parameterised GitHub Actions
  builder (`TWRP 16 Builder`, device-* branch auto-detection).
- **GUI2 (LVGL)**: same lingqiqi lvgl recovery source + deps as manet.
- **Runtime payload + kernel modules + fstab/flags**: taken from the community
  tree LstTy712/device_xiaomi_zorn_TWRP (stock HyperOS environment).
- **Display**: vendor.display.enable_spr=1 (same SPR color-order requirement
  as manet; without it the panel scans out with B/R swapped).

## Build (GitHub Actions)

Push to a `device-*` branch of this repo (e.g. `device-zorn`); the workflow
resolves device path/name/lunch from the branch. Or manual dispatch with:
device path `xiaomi/zorn`, name `zorn`, lunch `twrp_zorn`.

Output: `TWRP-3.7.1-16-zorn-<date>.img` — ramdisk-only recovery image
(kernel-less; the running kernel comes from `boot`; 100 MB partition).

## Device notes

- A/B device, virtual A/B. Flash to the `recovery` partition of your slot.
- Modules: full vendor module set shipped in the ramdisk (vendor/lib/modules,
  318 .ko); loader list in TW_LOAD_VENDOR_MODULES.
- FBE decryption: wrappedkey_v0, keydirectory /metadata/vold/metadata_encryption
  — bring-up in progress (community builds have no decryption yet).
- Boot HAL packages (bootctrl / boot@1.2-impl-qti) not bundled in v1.

## Status

- 2026-10-15: initial tree assembled from the manet framework + zorn payload.
