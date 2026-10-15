# TWRP 3.7.1 / Android 16 device tree — Xiaomi 14 Ultra (aurora)

SM8650 (pineapple) · TWRP-16 · GUI2 (LVGL) front-end

## 来源 / provenance

| 部分 | 来源 |
|------|------|
| 基础设备树 | `lolipuru` TWRP tree for aurora（payload / vendor 库 / keymint-strongbox 服务 / fstab / flags） |
| 构建框架 | `PXIAOHE/twrp_device_xiaomi_sm8650`（manet）— CI workflow、GUI2 集成、滑动确认主题 overlay、SPR 色彩修正 |
| 预编译 kernel | SM8650 6.1.138 Image，**仅用于 build-time vintf 检查**，`BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE=true` 不进镜像 |

## 相对上游的改动

1. `TARGET_PREBUILT_KERNEL` → `prebuilt/kernel`（真 Image），修复 `check_vintf_all` 因空 kernel 失败（同 zorn 修法）
2. `TARGET_CPU_VARIANT` kryo → generic（TWRP-16 平台 soong 兼容）
3. `PLATFORM_VERSION` 14 → 99.87.36（与平台/TWRP 版本一致）
4. 移除 `ENABLE_CPUSETS` / `ENABLE_SCHEDBOOST` / `BOARD_BUILD_SYSTEM_ROOT_IMAGE`（Android 16 已废弃）
5. 动态分区表补 `system_dlkm`
6. 加 `TARGET_SYSTEM_PROP`（启用 `vendor.display.enable_spr=1`，防 GUI2 蓝/粉反色）
7. 加 `recovery/root/twres/{portrait.xml,languages/zh_CN.xml}` 主题 overlay（中文 + 滑动确认）
8. CI：`.github/workflows/build.yml`（`device-*` 分支自动识别机型，push 即出包）

## 已知限制

- Xiaomi 14 系列使用 Keymint 3.0 Strongbox 加密；上游 README 指出 userdata 解密需要
  `android.se.omapi.ISecureElementService` 的 TWRP 侧替代实现。本树包含
  `android.hardware.secure_element-service.qti` / `strongbox-nxp` / `weaver.nxp` 等服务，
  实际解密能力待真机验证。
- 触摸：synaptics（`synaptics_tcm2.ko` + `synaptics_spi_aurora.img`）

## 构建

push 到 `device-aurora` 分支即触发 GitHub Actions：

```
lunch twrp_aurora
m installclean
m recoveryimage
```

产物：`TWRP-3.7.1-16-aurora-<date>.img`（100 MiB，header v4，纯 ramdisk + LZ4）
