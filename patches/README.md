# Device-tree patches for the GUI2 (LVGL) recovery fork

Applied by CI **after** the fork is fetched, in glob order.

| Patch | Purpose |
|---|---|
| `gui2_auto_decrypt.patch` | Saved lock password: General-Settings switch, OTG key (`/usb_otg*/TWRP/`), device-bound AES-256-CBC storage in `/persist/TWRP/.twrp_crypto_pwd`; retried up to 3 times before self-clearing. Hooked in `show_decrypt_page()` so both the startup path and the manual button reach it. |

## Why the hook lives in `show_decrypt_page()`

Startup and the manual button take different routes to the decrypt page:

```
poll_startup → enter_startup_pause(DECRYPT) → navigate_to → show_decrypt_page()
home_notice_event_cb → enter_decrypt_flow()  → navigate_to → show_decrypt_page()
```

`enter_decrypt_flow()` is only reached from the "Decrypt Data" button. Putting
the saved-password attempt there means a boot-time decrypt never runs it: the
file is written correctly after the first manual unlock and then never read
again, so the UI falls straight through to the manual prompt with no error
anywhere. `show_decrypt_page()` is the only function both routes pass through.

Guards on the hook: `decrypt->is_encrypted()`, `kind() != DEFAULT`, and
`!page_state.decrypt_failed && !page_state.decrypt_used_saved` (the page is
rebuilt often; without the last one it retries forever). If
`decrypt_attempt()` refuses before navigating, the code falls through to the
normal prompt instead of leaving a blank screen.

## Diagnostics

Every step logs; `grep -a saved-password /tmp/recovery.log`:

| Log line | Meaning |
|---|---|
| `stored N bytes to ...` | write succeeded |
| `load ... exists=0` | file missing — check the persist mount and the store path |
| `load result len=0` + `does not decrypt` | key derivation mismatch (serial changed or unreadable) |
| `open ... failed (errno=)` | write failed, errno says why |

`/mnt/vendor/persist/TWRP` is a **subdirectory**, not a mount point, so
`PartitionManager.Is_Mounted_By_Path()` always returns false for it. Check
`/mnt/vendor/persist` (or `/persist`) when testing whether persist is mounted.

## Failure handling

A single failure does not delete the file. Early-startup attempts can fail
because the TEE is not ready yet; only 3 consecutive failures clear the device
copy, and a successful unlock resets the counter. A copy the user placed on a
USB stick is never deleted by the loader.

## Theme overlay

`recovery/root/twres/` carries `portrait.xml` (slot A/B buttons go through the
swipe-confirm page) and `languages/zh_CN.xml` (`switch_slot_confirm`).
