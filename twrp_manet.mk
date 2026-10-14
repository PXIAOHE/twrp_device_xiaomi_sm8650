#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/manet

# Inherit from device.mk configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

## Device identifier
PRODUCT_DEVICE := manet
PRODUCT_NAME := twrp_manet
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := Redmi K70 Pro
PRODUCT_MANUFACTURER := Xiaomi
