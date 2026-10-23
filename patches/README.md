# patches/

按 GUI2 来源分两个目录，CI 按 `RECOVERY_SOURCE` 自动选：

| 目录 | 用在 | 基线 |
| :--- | :--- | :--- |
| `upstream/` | `RECOVERY_SOURCE=upstream`（默认） | TWRP-Test `android_bootable_recovery` `twrp-16.0`（2026-10-23 起自带 GUI2/LVGL #37） |
| `fork/` | `RECOVERY_SOURCE=fork` | lingqiqi5211 `android_bootable_recovery`，manet 用 `taro-lvgl@3b77055` |

两边代码不同，同一份 patch 不可能同时干净应用，所以分开存。
