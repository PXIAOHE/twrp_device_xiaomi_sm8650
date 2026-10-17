#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# Rules
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

# Bootloader
PRODUCT_PLATFORM := kalama
TARGET_BOOTLOADER_BOARD_NAME := $(PRODUCT_PLATFORM)
TARGET_NO_BOOTLOADER := true

# Platform
TARGET_BOARD_PLATFORM := xiaomi_sm8550
TARGET_BOARD_PLATFORM_GPU := qcom-adreno740
QCOM_BOARD_PLATFORMS += xiaomi_sm8550

# Kernel
BOARD_KERNEL_IMAGE_NAME       := Image
BOARD_BOOT_HEADER_VERSION     := 4
BOARD_KERNEL_PAGESIZE         := 4096
TARGET_KERNEL_CLANG_COMPILE   := true
TARGET_PREBUILT_KERNEL        := $(DEVICE_PATH)/prebuilt/kernel
BOARD_MKBOOTIMG_ARGS          += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS          += --pagesize $(BOARD_KERNEL_PAGESIZE)

# Ramdisk use lz4
BOARD_RAMDISK_USE_LZ4 := true

# A/B
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true

AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    init_boot \
    vendor_boot \
    dtbo \
    vbmeta \
    vbmeta_system \
    odm \
    product \
    system \
    system_ext \
    system_dlkm \
    vendor \
    vendor_dlkm

# Verified Boot
BOARD_AVB_ENABLE := true

# Partitions
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true

# Workaround for error copying vendor files to recovery ramdisk
TARGET_COPY_OUT_VENDOR := vendor

TARGET_COPY_OUT_ODM := odm
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USES_VENDOR_DLKMIMAGE := true
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4

BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600

# Dynamic Partition
BOARD_SUPER_PARTITION_SIZE := 9663676416
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 9659482112 # (BOARD_SUPER_PARTITION_SIZE - 4 MiB)
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor vendor_dlkm odm system_dlkm

# System as root
BOARD_ROOT_EXTRA_FOLDERS := bluetooth dsp firmware persist soccp

# File systems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Extras
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab

# Crypto
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
BOARD_USES_METADATA_PARTITION := true
TW_INCLUDE_OMAPI := true
TW_USE_FSCRYPT_POLICY := 2
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# Tool
TW_INCLUDE_7ZA := true
TW_INCLUDE_ZSTD := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_ENABLE_ALL_PARTITION_TOOLS := true

# Debug
TARGET_USES_LOGD := true
TWRP_INCLUDE_LOGCAT := true
TARGET_RECOVERY_DEVICE_MODULES += debuggerd
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/debuggerd
TARGET_RECOVERY_DEVICE_MODULES += strace
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/strace
TARGET_RECOVERY_DEVICE_MODULES += prebuilt

# Fastbootd
TW_INCLUDE_FASTBOOTD := true

# Other TWRP Configurations
TW_THEME := portrait_hdpi
TW_FRAMERATE := 120
RECOVERY_SDCARD_ON_DATA := true
TARGET_RECOVERY_QCOM_RTC_FIX := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_INCLUDE_NTFS_3G := true
TW_USE_DMCTL := true
TW_USE_TOOLBOX := true
TARGET_USES_MKE2FS := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_MAX_BRIGHTNESS := 2047
TW_EXTRA_LANGUAGES := true
TW_DEFAULT_BRIGHTNESS := 200
TW_EXCLUDE_APEX := true
TW_STATUS_ICONS_ALIGN := center
TW_SUPPORT_INPUT_AIDL_HAPTICS := true
TW_SUPPORT_INPUT_AIDL_HAPTICS_FIX_OFF := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
# K70 (vermeer): goodix touch, qcom PMIC haptics and charger readout at boot.
TW_LOAD_VENDOR_MODULES := "miev.ko qcom_wdt_core.ko gh_virt_wdt.ko qcom_cpu_vendor_hooks.ko clk-rpmh.ko gcc-kalama.ko icc-rpmh.ko camcc-kalama.ko qcom_ipcc.ko qcom_ipc_logging.ko qcom-pdc.ko thermal_minidump.ko qcom_tsens.ko rpmh-regulator.ko bwmon.ko qcom-cpufreq-hw.ko sched-walt.ko thermal_pause.ko cpu_hotplug.ko clk-dummy.ko clk-qcom.ko cmd-db.ko cqhci.ko crypto-qti-common.ko crypto-qti-hwkm.ko dcc_v2.ko dcvs_fp.ko debug-regulator.ko dispcc-kalama.ko tcsrcc-kalama.ko videocc-kalama.ko gdsc-regulator.ko gh_arm_drv.ko gh_ctrl.ko gh_dbl.ko gh_msgq.ko gh_rm_drv.ko gunyah.ko mdt_loader.ko hwkm.ko icc-bcm-voter.ko icc-debug.ko iommu-logger.ko llcc-qcom.ko mem-hooks.ko mem_buf_dev.ko mem_buf_msgq.ko mem_buf.ko memory_dump_v2.ko minidump.ko msm_dma_iommu_mapping.ko pinctrl-crow.ko pinctrl-kalama.ko qnoc-kalama.ko qnoc-crow.ko ns.ko nvmem_qcom-spmi-sdam.ko phy-qcom-ufs.ko phy-qcom-ufs-qmp-v4-kalama.ko phy-qcom-ufs-qrbtc-sdm845.ko pinctrl-msm.ko proxy-consumer.ko qcom-dcvs.ko qcom-dload-mode.ko qcom_dma_heaps.ko qcom_hwspinlock.ko debug_symbol.ko qcom_logbuf_vh.ko qcom_iommu_util.ko qcom_llcc_pmu.ko qcom-pmu-lib.ko pmu_vendor.ko pmu_scmi.ko qcom-spmi-pmic.ko spmi-pmic-arb.ko qcom-reboot-reason.ko qcom_rpmh.ko qcom-scm.ko qnoc-qos.ko qrtr.ko qti-regmap-debugfs.ko regmap-spmi.ko rtc-pm8xxx.ko secure_buffer.ko smem.ko socinfo.ko stub-regulator.ko qcom_aoss.ko msm_qmp.ko tmecom-intf.ko ufs_qcom.ko ufshcd-crypto-qti.ko arm_smmu.ko mem-offline.ko sdhci-msm.ko qcom_rimps.ko c1dcvs_vendor.ko c1dcvs_scmi.ko hwid.ko bcl_pmic5.ko nvme-core.ko nvme.ko mi_memory.ko mi_schedule.ko metis.ko mi_power.ko zram.ko zsmalloc.ko dump_display.ko low_free_memory_kill.ko wl2868c.ko mpbe.ko msm_sysstats.ko cpq.ko msm_show_resume_irq.ko mhi.ko mhi_cntrl_qcom.ko mhi_dev_uci.ko mhi_dev_netdev.ko mhi_dev_dtr.ko mhi_dev_satellite.ko phy-qcom-ufs-qmp-v4-waipio.ko phy-qcom-ufs-qmp-v4.ko phy-qcom-ufs-qmp-v4-khaje.ko phy-qcom-ufs-qmp-v4-lahaina.ko phy-qcom-ufs-qmp-v4-kona.ko pinctrl-spmi-gpio.ko pinctrl-spmi-mpp.ko pwm-qti-lpg.ko pci-msm-drv.ko debugcc-kalama.ko gpucc-kalama.ko bam_dma.ko msm_gpi.ko qcom_cpuss_sleep_stats.ko pdr_interface.ko qmi_helpers.ko heap_mem_ext_v01.ko msm_memshare.ko smp2p.ko smp2p_sleepstate.ko qsee_ipc_irq_bridge.ko glink_probe.ko glink_pkt.ko pmic_glink.ko qti_battery_debug.ko charger-ulog-glink.ko altmode-glink.ko soc_sleep_stats.ko cdsprm.ko sysmon_subsystem_stats.ko subsystem_sleep_stats.ko adsp_sleepmon.ko eud.ko microdump_collector.ko llcc_perfmon.ko cdsp-loader.ko pmic-pon-log.ko boot_stats.ko rq_stats.ko core_hang_detect.ko usb_bam.ko memlat.ko memlat_scmi.ko cpufreq_stats_scmi.ko rimps_log.ko qcom_ramdump.ko panel_event_notifier.ko dmesg_dumper.ko sys_pm_vx.ko qdss_bridge.ko fsa4480-i2c.ko msm_show_epoch.ko gh_tlmm_vm_mem_access.ko sps_drv.ko msm_performance.ko qcom_va_minidump.ko qbt_handler.ko hung_task_enh.ko qti-fixed-regulator.ko qti-ocp-notifier.ko wl2866d.ko hvc_gunyah.ko msm_geni_serial.ko frpc-adsprpc.ko rdbg.ko xlogchar.ko lt9611uxc.ko perf_helper.ko qseecom_proxy.ko sg.ko spi-msm-geni.ko spmi-pmic-arb-debug.ko msm_sharedmem.ko phy-generic.ko phy-qcom-emu.ko phy-msm-ssusb-qmp.ko phy-msm-snps-eusb2.ko phy-msm-m31-eusb2.ko dwc3-msm.ko ehset.ko f_fs_ipc_log.ko usb_f_cdev.ko usb_f_ccid.ko usb_f_qdss.ko usb_f_gsi.ko usb_f_diag.ko ucsi_glink.ko usbmon.ko repeater.ko repeater-qti-pmic-eusb2.ko repeater-i2c-eusb2.ko redriver.ko nb7vpq904m.ko pm8941-pwrkey.ko qcom-hv-haptics.ko goodix_fod.ko fpc1555.ko i2c-msm-geni.ko i3c-master-msm-geni.ko ir-spi.ko qcom_ipc_lite.ko synx-driver.ko qcom-pon.ko reboot-mode.ko qti_battery_charger.ko xm_power.ko qcom-spmi-temp-alarm.ko bcl_soc.ko cpu_voltage_cooling.ko ddr_cdev.ko max31760_fan.ko msm_lmh_dcvs.ko policy_engine.ko qti_qmi_cdev.ko qti_qmi_sensor_v2.ko qti_cpufreq_cdev.ko qti_devfreq_cdev.ko qti_userspace_cdev.ko sdpm_clk.ko mi_thermal_interface.ko qcom_edac.ko qcom_lpm.ko leds-qti-flash.ko leds-qti-tri-led.ko memlat_vendor.ko cpufreq_stats_vendor.ko mi_mempool.ko binder_prio.ko mi_log.ko mi_exception_log.ko ipa_fmwk.ko qcom_pil_info.ko rproc_qcom_common.ko qcom_q6v5.ko qcom_q6v5_pas.ko qcom_esoc.ko qcom_sysmon.ko qcom_glink.ko qcom_glink_smem.ko qcom_smd.ko gh_irq_lend.ko gh_mem_notifier.ko qcom-spmi-adc5-gen3.ko qcom-vadc-common.ko industrialio-buffer-cb.ko nvmem_qfprom.ko icc-test.ko perfmgr.ko mi_freqwdg.ko ofpart.ko chipreg.ko block2mtd.ko mtd.ko mtd_blkdevs.ko mtdblock.ko mtdoops.ko slimbus.ko slim-qcom-ngd-ctrl.ko coresight.ko coresight-tmc.ko coresight-funnel.ko coresight-replicator.ko coresight-stm.ko coresight-cti.ko coresight-tpda.ko coresight-tpdm.ko coresight-csr.ko coresight-dummy.ko coresight-remote-etm.ko coresight-tgu.ko coresight-hwevent.ko stm_core.ko stm_p_basic.ko stm_p_ost.ko stm_console.ko stm_ftrace.ko snd-usb-audio-qmi.ko snd-soc-hdmi-codec.ko qrtr-smd.ko qrtr-mhi.ko qrtr-gunyah.ko kunit.ko hdcp_qseecom_dlkm.ko smcinvoke_dlkm.ko bootinfo.ko debug_ext.ko msm_drm.ko msm_ext_display.ko sync_fence.ko msm_hw_fence.ko msm-mmrm.ko swinfo.ko adsp_loader_dlkm.ko goodix_core.ko"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone35/temp"
TW_BACKUP_EXCLUSIONS := /data/fonts,/data/adb/ap,/data/adb/ksu
