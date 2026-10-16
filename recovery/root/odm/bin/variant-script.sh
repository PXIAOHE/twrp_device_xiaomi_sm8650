#!/system/bin/sh
#=================================================
# Device identity + service handoff (vermeer)
#=================================================
set -e

variant="vermeer"
model="Redmi K70"
log_file="/tmp/recovery.log"

log() {
    echo "variant-script.sh: $1" | tee -a "$log_file"
}

#-------------------------------------------------
# Helper: set multiple vibrator-related properties
#-------------------------------------------------
set_vibrator_props() {
    resetprop ro.odm.mm.vibrator.audio_haptic_support "true"
    resetprop ro.odm.mm.vibrator.lowPowerMode "true"
    resetprop ro.odm.mm.vibrator.resonant_frequency "$1"
    resetprop ro.odm.mm.vibrator.slide_effect_protect_time "$2"
    resetprop ro.odm.mm.vibrator.sys_path "$3"
    resetprop ro.odm.mm.vibrator.device_type "$4"
    resetprop ro.vendor.mm.vibrator.sys_path "/sys/class/qcom-haptics"
}

# Tuning mirrors the manet branch defaults; adjust here if feedback differs.
resetprop ro.twrp.device_version "Redmi_K70"
resetprop ro.twrp.weaver "nxp"
set_vibrator_props "170" "35" "/sys/class/qcom-haptics" "ff"

# Shown as the USB gadget product string while in recovery.
echo "$model" >/config/usb_gadget/g1/strings/0x409/product
resetprop vendor.usb.product_string "$model"
mkdir -p /usbotg

#-------------------------------------------------
# Set product & model properties
#-------------------------------------------------
device_props=(
    ro.build.product
    ro.product.device
    ro.product.odm.device
    ro.product.vendor.device
    ro.product.product.device
    ro.product.system_ext.device
    ro.product.system.device
    ro.product.bootimage.device
    ro.product.name
    ro.product.odm.name
    ro.product.vendor.name
    ro.product.product.name
    ro.product.system_ext.name
    ro.product.system.name
)

model_props=(
    ro.product.model
    ro.product.odm.model
    ro.product.vendor.model
    ro.product.product.model
    ro.product.system_ext.model
    ro.product.system.model
)

for prop in "${device_props[@]}"; do
    resetprop "$prop" "$variant"
done

for prop in "${model_props[@]}"; do
    resetprop "$prop" "$model"
done

#-------------------------------------------------
# Hand off to the recovery services
#-------------------------------------------------
# No SKU overlays on vermeer: the base odm payload is already the right one.
# This prop is what init.recovery.qcom.rc waits for before starting the
# weaver / haptics / touch services.
setprop twrp.variant.files_copied "1"

log "Applied variant props for: $model ($variant)"
exit 0
