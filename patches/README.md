# Device-tree patches for the GUI2 recovery fork

These patches are applied by CI **after** fetching the recovery fork
(`lingqiqi5211/android_bootable_recovery`, branch `taro-lvgl`, pinned by
`RECOVERY_FORK_SHA` in `.github/workflows/build.yml`).

## Rules

- Files are applied in **glob (lexicographic) order** — prefix new patches so
  the order stays obvious.
- Each patch is **one self-contained feature** so that a conflict in one can be
  fixed (or temporarily skipped) without touching the others.
- The CI first tries a clean `git apply`; if the pinned upstream commit has
  moved past the patch base, it retries with `git apply -3` (3-way merge).
  A conflict that survives both is a hard failure with the diff in the log.

## Current patches

| Patch | Purpose | Base |
|---|---|---|
| `gui2_auto_decrypt.patch` | Saved lock password: General-Settings switch, OTG key (`/usb_otg*/TWRP/`), device-bound AES-256-CBC storage in `/persist/TWRP/.twrp_crypto_pwd`; failure self-clears. 8 files. | taro-lvgl@3b77055 |
| `zz_diag_probe.patch` | **Temporary** startup diagnostic probe (traces PARTITIONS/STORAGE chain to `/persist/twrp_diag.log`). Remove after the first-boot-hang investigation closes. | taro-lvgl@3b77055 |

## Syncing to a newer upstream

1. Pick the new `taro-lvgl` commit, update `RECOVERY_FORK_SHA` (one line).
2. Rebuild. If the apply step fails with a real conflict, replay the failing
   hunk by hand (patches were generated from anchor-based edits, so the
   changes are small and localized), regenerate the patch, and push.
