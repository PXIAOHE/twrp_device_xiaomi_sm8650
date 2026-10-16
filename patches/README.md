# Device-tree patches for the GUI2 (LVGL) recovery fork

Applied by CI **after** the fork is fetched, in glob order.

| Patch | Purpose |
|---|---|
| `gui2_auto_decrypt.patch` | Saved lock password: General-Settings switch, OTG key (`/usb_otg*/TWRP/`), device-bound AES-256-CBC storage in `/persist/TWRP/.twrp_crypto_pwd`; failure self-clears. Ported to the `lvgl` branch layout (enter_decrypt_flow + refresh_decrypt_progress). |

## Theme overlay

`recovery/root/twres/` carries `portrait.xml` (slot A/B buttons go through the
swipe-confirm page) and `languages/zh_CN.xml` (`switch_slot_confirm`).
