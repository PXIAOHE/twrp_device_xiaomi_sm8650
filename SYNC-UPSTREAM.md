# 同步上游（YARP / GUI2）标准流程

> 这份是给「上游又更新了，重新出包」用的固定流程。当前两台设备都已验证通过：
> manet（Redmi K70 Pro）与 8850（device-sm8850，产品名已正名）。

## 仓库角色

| 分支 | 内容 |
| :--- | :--- |
| `main` | manet（K70 Pro）设备树 + CI |
| `device-sm8850` | 8850 设备树 + CI（产品标识 `twrp_sm8850`） |
| `recovery-gui2-autodecrypt` | `bootable/recovery`：GUI2 主线 + 我们的自动解密（本文件所在分支） |
| `ci-logs` | 构建失败时 CI 自动推的日志（`.ci-logs/build.log`） |

上游（2026-10-29 起）是 **TWRP-Test/android_bootable_recovery 的 `twrp-16.0` 线**，
GUI2 已经并进这条主线（旧版 UI 已移除）。`lingqiqi5211` 的 `lvgl` 停在 10-23，
只剩历史价值，别再当上游。

## 一次完整同步

```bash
# 1) 取上游
git fetch https://github.com/TWRP-Test/android_bootable_recovery twrp-16.0:refs/remotes/tt/twrp16

# 2) 以新上游为基线，把我们的改动接上去（本仓库的 auto-on-twrp16 分支）
git checkout -B auto-on-twrp16 refs/remotes/tt/twrp16
git diff <旧上游 SHA>..origin/recovery-gui2-autodecrypt > /tmp/autodecrypt.patch
git apply -3 /tmp/autodecrypt.patch    # i18n 冲突时取上游，再把两项追加到结构体/语言包末尾

# 3) 我们的改动 = 9 个文件（backend/page_state/gui2/i18n×4/i18n.h 等）
#    做法：base=旧上游、ours=我们分支、theirs=新上游，做三方合并

# 4) 校验（必须全过再推）
#    a. 四份语言包语法：g++ -fsyntax-only -std=c++20 -I. gui2/i18n/{en,ru,zh_cn,zh_tw}.cpp
#       （a93a12ec 起上游用了 std::span，必须 C++20；c++17 会直接报错）
#    b. 探针：打印 swap_navigation / general_group_decrypt / general_remember_password，
#       四个语言包都必须有值（不能是 null）

# 5) 推（分支内容整体替换，用 --force）
git push --force ssh://git@ssh.github.com:443/PXIAOHE/twrp_device_xiaomi_sm8650.git \
    auto-on-twrp16:recovery-gui2-autodecrypt

# 6) 触发两个设备构建：改 .ci/rebuild.txt 里的 recovery-sha 并 push
#    main 与 device-sm8850 各一次（这个文件是真实改动，能触发 workflow）
```

## 踩过的坑（别再踩）

1. **空提交不触发构建**：workflow 带 `paths-ignore`，改动文件列表为空时 GitHub 直接跳过，
   连 check-run 都不产生。必须改真实文件 —— 用 `.ci/rebuild.txt`。
2. **`liblvgl_twrp` 只能按 shared 链**：`TWRP-Test/android_external_lvgl` 里它是
   `cc_library_shared`，写进 `static_libs` 会报
   `module recovery missing dependencies: liblvgl_twrp{...link:static}`。
   要改的是 `name: "recovery"` 那个 `cc_binary` 的 `shared_libs`（约 561 行），
   **别插进 `Android.bp` 里被注释掉的模板块**，否则 blueprint bootstrap 直接失败。
3. **i18n 新字段必须追加到 `language_pack` 末尾**，并且 `en/ru/zh_cn/zh_tw` 四份
   语言包各自在末尾补上同样两项；位置错位会报
   `excess elements in scalar initializer`，或让俄语下整行消失。
4. **保存密码尝试放在 `show_decrypt_page()` 末尾**（`build_decrypt_page()` 之后）：
   与 10-17 manet 那版一致，此时 weaver 已上电，第一次就能解。
5. **失败后不要提前清 `decrypt_used_saved`**：`decrypt_attempt()` 只异步 `start()`，
   不会切到 `DECRYPT_PROGRESS` 页；要用 `decrypt_prompt_ms` 判断 start 是否成功，
   否则失败分支进不去、weaver 轮询被跳过，用户就看到「凭证不对」。
6. **weaver 就绪轮询**：每 150ms 读 `init.svc.{vendor.,odm.}weaver*`，running 立刻重试；
   属性不存在则 1s 后直接试；上限 15s / 6 次。
7. **别把 GUI2 的 `bootable/recovery` 换成 TWRP-Test 的**：会丢掉导航栏手势交换、
   备份名修复、俄语等 GUI2 新功能。

## 出包后验证（不要只看 CI 绿灯）

```bash
magiskboot unpack TWRP-*.img
magiskboot cpio ramdisk.cpio "ls system/lib64" | grep liblvgl_twrp.so   # 必须在
magiskboot cpio ramdisk.cpio "extract system/bin/recovery rec"
grep -a tw_gui2_remember_pwd rec        # 记住解密密码
grep -a tw_gui2_swap_navigation rec     # 导航栏手势交换
grep -a "polling weaver" rec            # 失败重试兜底
```

刷机与回滚（manet，当前 slot `_b`）：

```bash
dd if=/dev/block/by-name/recovery_b of=/sdcard/recovery-backup.img bs=1M
dd if=TWRP-*.img of=/dev/block/by-name/recovery_b bs=1M conv=fsync
# 回滚：dd if=/sdcard/recovery-backup.img of=/dev/block/by-name/recovery_b bs=1M conv=fsync
```

## 同步记录

### 2026-11-07 · 基线 a93a12ec

上游从 `8a58fc3b` 走到 `a93a12ec`，共 9 个提交（含 PR #42 合并）。
重放照旧：`git diff 8a58fc3b..4215c1b4` 打到 `a93a12ec`，`git apply -3` **全部干净应用，零冲突**。

上游这轮改了什么（★ = 可能影响本分支或设备侧）：

- ★ `twrpminui: remove pixelflinger and legacy rendering paths`（6b9e73cb）
  删掉 pixelflinger、FreeType 文本与图片资源 API；截图改为直接从 framebuffer 编码，
  尊重 stride / 像素字节序 / 逻辑旋转，修掉旋转后 BGRA 直拷与后端通道交换。
- ★ `twrpminui: rebase graphics and input on current minui`（f2c636ba）
  surface / graphics / PNG / DRM-fbdev 对齐新 minui；触摸与键盘搬进 `twrp_input`，
  震动独立成 haptics；直接依赖 libdrm，删掉高通 overlay backend 与其内核头；
  输入改用 inotify 发现，不再在分区初始化后重启 input；GUI2 录音改用逻辑分辨率。
- ★ `gui2: install fonts through a dedicated prebuilt_res module`（a5d1b504）
  字体改由 `gui2_fonts` 预编译模块装到 `/res/fonts`，原来的 Soong LoadHook 删除。
  设备树不自带字体，无冲突。
- `gui2: Keep PIN entry compact and preserve the keyboard during decryption`（99fdb57e）
- `gui2: Run storage mounts off the UI thread and stabilize OTG targets`（0414f6fe）
- `recovery: Retry hotplug discovery until block nodes are ready`（9734c172）
- `recovery: Rescan removable partitions after block uevents`（833efa69）
- `recovery: Handle input discovery gaps and host test compatibility`（e2e566c7）
- `gui2: thicken settings sliders and keep card corners consistent`（8a58fc3b，旧基线）

本分支携带的改动（12 个文件、603 行）：

| 文件 | 内容 |
| :--- | :--- |
| `gui2/backend/twrp_decrypt_password.h` | 新增。AES-256-CBC 存取（key=SHA256(salt‖serial)）、`TWG2` 魔数、旧 XOR 0x5A 读兼容、崩溃哨兵，全部 inline，libgui2 与 recovery 二进制各内联一份 |
| `gui2/backend/twrp_decrypt_backend.{h,cpp}` | `load/store/clear_saved_crypto_password`、`load_otg_crypto_password`、哨兵 API |
| `gui2/gui2.cpp` | `tw_gui2_remember_pwd` 设置项；weaver 就绪轮询（150 ms / 上限 15 s / 最多 6 次）；失败静默重试；保存密码尝试挂在 `show_decrypt_page()` 末尾 |
| `gui2/i18n/*` | `language_pack` 末尾追加两项（数据解密 / 记住解密密码），四份语言包同步 |
| `gui2/Android.bp` | `libgui2` 的 `shared_libs` 加 `libcrypto` |
| `gui2/pages/page_state.h` | `decrypt_used_saved` / `decrypt_saved_from_otg` / `decrypt_saved_failures` |

顺手清掉 `show_decrypt_page()` 里 OTG 那段死代码（`from_otg` 恒为 false），保留注释说明为什么没接。

校验：

```text
g++ -fsyntax-only -std=c++20 -Wmissing-field-initializers gui2/i18n/{en,ru,zh_cn,zh_tw}.cpp  → 四份全过
language_pack 字段数 636，四份语言包 missing-field-initializers 警告 0（无错位、无漏项）
```
