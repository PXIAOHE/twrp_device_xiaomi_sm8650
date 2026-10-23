# patches/

按 GUI2 来源分两个目录，CI 会按 `RECOVERY_SOURCE` 自动选：

| 目录 | 用在 | 基线 |
| :--- | :--- | :--- |
| `upstream/` | `RECOVERY_SOURCE=upstream`（默认） | TWRP-Test `android_bootable_recovery` `twrp-16.0`（2026-10-23 起自带 GUI2/LVGL #37） |
| `fork/` | `RECOVERY_SOURCE=fork` | lingqiqi5211 `android_bootable_recovery`，sm8750 用 `lvgl@c6eedad`，manet 用 `taro-lvgl@3b77055` |

两边代码不同，同一份 patch 不可能同时干净应用，所以分开存。
上游合并（#37）后 `gui2_fix_lvgl_build.patch` 已不需要：`twrp_flags.go` 自己给了
`TW_DEFAULT_LANGUAGE` / `TW_DEVICE_VERSION` / `TW_GIT_REVISION` 的兜底。

改功能时：先改 fork 基线，再把同一个改动 rebase 到 upstream 基线，两边各出一份 patch。
