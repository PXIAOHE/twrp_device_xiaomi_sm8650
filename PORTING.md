# Porting this tree to another Xiaomi device (manet / zorn / vermeer lineage)

Distilled from the manet (K70 Pro) and zorn (K80) bring-ups; vermeer (K70) follows the same recipe.

## 0. Layout

One repo, one branch per device: `main` = manet, `device-<codename>` = others.
Pushing to a `device-*` branch builds that device automatically —
`DEVICE_NAME` / `DEVICE_PATH` / `LUNCH_TARGET` are derived from the branch name.

## 1. Assemble the device tree

Clone this tree, then swap the device-specific parts:

| Part | Source |
| --- | --- |
| `BoardConfig.mk` | platform values from the device's stock/reference tree (super size, partition list, brightness, vendor module list) |
| `twrp_<codename>.mk`, `AndroidProducts.mk`, `device.mk` | codename / product name / model |
| `recovery.fstab` + `recovery/root/system/etc/twrp.flags` | stock recovery env or a community tree |
| `recovery/root/{vendor,system}` payload | stock HyperOS recovery environment (qseecomd, keymint/weaver, touch, vibrator ...) |
| `recovery/root/vendor/lib/modules` | that device's stock kernel modules |
| `prebuilt/kernel` | **a real kernel Image** — build-time VINTF checks only, never included in the image (recovery is kernel-less) |
| `prebuilt/lib/firmware` | device firmware needed inside recovery (touch / haptics) |
| `system.prop` | device props **plus `vendor.display.enable_spr=1`** |
| `recovery/root/twres` | keep the GUI2 overlay (portrait.xml / zh_CN.xml) |

## 2. Known gotchas (each cost one failed CI run)

1. **`mi_ext` in `BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST`** — soong fsgen
   rejects it ("not a super image supported partition"). Use the platform-standard
   list: `system system_ext product vendor vendor_dlkm odm system_dlkm`.
2. **Empty kernel placeholder** — `check_vintf` cannot extract kernel configs
   ("Cannot extract kernel configs in out/.../kernel"). Provide a real kernel Image.
3. **Display color order** — twrpminui programs `SDE_SPR_INIT_CFG` from
   `vendor.display.enable_spr` (GetIntProperty, default 0). Without it the panel
   scans out with B/R swapped (blue renders pink) while screenshots stay correct.
   Set `vendor.display.enable_spr=1` in `system.prop`; the bypass value is
   per device (see the variant-script examples upstream).
4. `BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true` keeps the output kernel-less
   (the running kernel comes from `boot`).

## 3. Verify the image before flashing

    magiskboot unpack TWRP-*.img      # expect HEADER_VER 4, KERNEL_SZ 0, lz4_legacy
    magiskboot cpio ramdisk.cpio extract
    grep enable_spr prop.default      # must be present
    ls vendor/lib/modules | wc -l     # module count
    md5sum twres/portrait.xml         # 9ecfc7ca2c1079f14b17b5edad421176

## 4. On-device checklist

Color order (look at the real screen — screenshots are always "correct"),
touch, vibration, decryption, MTP, OTG, slot menu, screenshot/recording, fastbootd.
Collect `/sdcard/recovery.log` (GUI2 "Copy Log") plus a photo of the screen.

## 5. Multi-device notes

- One image per device: payload, fstab and modules are device-specific.
- Same-generation devices can share one tree via `odm/variant/<sku>/` +
  `variant-script.sh` (see the upstream sm8850 tree). Different super sizes or
  payload makeups make branch-per-device cleaner.
