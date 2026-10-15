#
# Copyright (C) 2023 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/aurora

# Inherit from device.mk configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

# Release name
PRODUCT_RELEASE_NAME := aurora

## Device identifier
PRODUCT_DEVICE := aurora
PRODUCT_NAME := twrp_aurora
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := 24030PN60G
PRODUCT_MANUFACTURER := Xiaomi

# Assert
TARGET_OTA_ASSERT_DEVICE := $(PRODUCT_RELEASE_NAME)

# Theme
TW_STATUS_ICONS_ALIGN := center
TW_Y_OFFSET := 105
TW_H_OFFSET := -105
