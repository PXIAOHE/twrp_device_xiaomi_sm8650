# TWRP device tree for Xiaomi manet (Redmi K70 Pro, SM8650 / pineapple)

TWRP 16 device tree for the Redmi K70 Pro (`manet`), assembled from:

- **Build skeleton + CI**: [YuKongA/twrp_device_xiaomi_sm8850](https://github.com/YuKongA/twrp_device_xiaomi_sm8850) — TWRP 16.0 platform + parameterised GitHub Actions builder (`TWRP 16 Builder`).
- **Runtime payload**: manet-specific `recovery/root/{odm,vendor,system}` + fstab/flags/init rc, taken from the stock HyperOS 3.0.306 recovery environment (qseecomd / gatekeeper / keymint / weaver / vibratorfeature / goodix touch stack).

## Build (GitHub Actions)

Builds run **automatically on every push to `main`** (docs-only changes are skipped).
Manual trigger: Actions → **TWRP 16 Builder** → *Run workflow*. Defaults are pre-set for this repo:

| Input | Default |
| --- | --- |
| TWRP manifest | `TWRP-Test/platform_manifest_twrp_aosp` @ `twrp-16.0` |
| Device tree | this repo @ `main` |
| Device path | `xiaomi/sm8650` |
| Device name | `manet` |

Output: `TWRP-3.7.1-16-manet-<date>.img` — a **ramdisk-only** recovery image
(kernel-less, matching the stock manet recovery layout; the running kernel comes from `boot`).
Flash it to the `recovery` partition of the active slot.

## Device notes

- manet: A/B device, only the **b** slot is provisioned — never flash the `a` slot.
- `recovery` partition: 100 MB, ramdisk-only (boot header v4, lz4_legacy ramdisk).
- Decryption: FBE `wrappedkey_v0`, keydirectory `/metadata/vold/metadata_encryption`.
- USB-OTG: static entry in `twrp.flags`; plug the drive, then tap *USB-OTG* once under Mount.
- `variant-script.sh` falls back to the `manet` branch for unknown SKUs.

## Status

- 2026-10-14: first assembly of this tree — not yet through a full CI build.
