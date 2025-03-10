# Copyright (C) 2014 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Unlock dex2oat threads
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.dex2oat-threads=8 \
    dalvik.vm.image-dex2oat-threads=8

# Platform specific default properties
PRODUCT_PROPERTY_OVERRIDES += \
    persist.data.qmi.adb_logmask=0

# Common property setup DS or SS devices.
ifeq ($(PRODUCT_DEVICE_DS),true)
PRODUCT_PROPERTY_OVERRIDES += \
    persist.vendor.radio.multisim.config=dsds
else
PRODUCT_PROPERTY_OVERRIDES += \
    ro.telephony.default_network=9
endif

# System props for the data modules
PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.use_data_netmgrd=true \
    persist.vendor.data.mode=concurrent \
    persist.data.netmgrd.qos.enable=true \
    ro.data.large_tcp_window_size=true

# Enable Power save functionality for modem
PRODUCT_PROPERTY_OVERRIDES += \
    persist.vendor.radio.add_power_save=1 \
    persist.vendor.radio.apm_sim_not_pwdn=1

# Enable advanced power saving for data connectivity
# DPM: Data Port Mapper, with TCM (TCP Connection Manager)
# CnE: Connectivity Engine
PRODUCT_PROPERTY_OVERRIDES += \
    persist.vendor.dpm.feature=1 \
    persist.vendor.dpm.tcm=1 \
    persist.vendor.cne.feature=1

# IMS
PRODUCT_PROPERTY_OVERRIDES += \
    persist.vendor.radio.vdp_on_ims_cap=1 \
    persist.vendor.radio.report_codec=1

# VoLTE / VT / WFC
# These properties will force availability of the VoLTE,
# VideoTelephony and Wi-Fi Call, without needing carrier
# services provisioning sites hooked up: simplifies it.
PRODUCT_PROPERTY_OVERRIDES += \
    persist.dbg.volte_avail_ovr=1 \
    persist.dbg.vt_avail_ovr=1  \
    persist.dbg.wfc_avail_ovr=1

# Modem properties
PRODUCT_PROPERTY_OVERRIDES += \
    persist.vendor.radio.wait_for_pbm=1 \
    persist.vendor.radio.mt_sms_ack=19 \
    persist.vendor.radio.enableadvancedscan=true \
    persist.vendor.radio.unicode_op_names=true \
    persist.vendor.radio.sib16_support=1 \
    persist.vendor.radio.oem_socket=true

# RemoteFS Storage
# This property is needed for rmt_storage to look for fsg
# in /vendor
PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.build.vendorprefix=/vendor

# Ringer
PRODUCT_PROPERTY_OVERRIDES += \
    ro.telephony.call_ring.multiple=false

# System props for telephony System prop to turn on CdmaLTEPhone always
PRODUCT_PROPERTY_OVERRIDES += \
    telephony.lteOnCdmaDevice=0

# debug.sf.latch_unsignaled
# - This causes SurfaceFlinger to latch
#   buffers even if their fences haven't signaled
PRODUCT_PROPERTY_OVERRIDES += \
    debug.sf.latch_unsignaled=1

# SurfaceFlinger
# Keep uppercase makevars like TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS
# in sync, use hardware/interfaces/configstore/1.1/default/surfaceflinger.mk
# as a reference
# ConfigStore is being deprecated and sf is moving to props, see
# frameworks/native/services/surfaceflinger/sysprop/SurfaceFlingerProperties.sysprop
PRODUCT_PROPERTY_OVERRIDES += \
    ro.surface_flinger.force_hwc_copy_for_virtual_displays=true

# Disable buffer age (b/74534157)
PRODUCT_PROPERTY_OVERRIDES += \
    debug.hwui.use_buffer_age=false

# Stagefright
PRODUCT_PROPERTY_OVERRIDES += \
    media.stagefright.thumbnail.prefer_hw_codecs=true

# Delay reduction
PRODUCT_PROPERTY_OVERRIDES += \
    sdm.debug.rotator_downscale=1

# DRM service
PRODUCT_PROPERTY_OVERRIDES += \
    drm.service.enabled=true

# VIDC: debug_levels 1:ERROR 2:HIGH 4:LOW 0:NOLOGS 7:AllLOGS
PRODUCT_PROPERTY_OVERRIDES += \
    vidc.debug.level=1

# Audio
PRODUCT_PROPERTY_OVERRIDES += \
    fmas.hdph_sgain=0 \
    media.aac_51_output_enabled=true \
    ro.config.media_vol_steps=25 \
    ro.config.vc_call_vol_steps=7

# Audio (newer CAF HALs)
PRODUCT_PROPERTY_OVERRIDES += \
    persist.vendor.audio.fluence.speaker=false \
    persist.vendor.audio.fluence.voicecall=true \
    persist.vendor.audio.fluence.voicecomm=true \
    persist.vendor.audio.fluence.voicerec=false \
    ro.vendor.audio.sdk.fluencetype=fluence \
    vendor.audio_hal.in_period_size=144 \
    vendor.audio_hal.period_multiplier=3 \
    vendor.audio_hal.period_size=192 \
    vendor.audio.offload.gapless.enabled=true \
    vendor.audio.offload.passthrough=false \
    vendor.audio.volume.headset.gain.depcal=true

# Audio Features
PRODUCT_PROPERTY_OVERRIDES += \
    vendor.audio.feature.afe_proxy.enable=true \
    vendor.audio.feature.anc_headset.enable=true \
    vendor.audio.feature.audiozoom.enable=false \
    vendor.audio.feature.battery_listener.enable=false \
    vendor.audio.feature.compr_cap.enable=false \
    vendor.audio.feature.compress_meta_data.enable=true \
    vendor.audio.feature.deepbuffer_as_primary.enable=false \
    vendor.audio.feature.dsm_feedback.enable=false \
    vendor.audio.feature.ext_hw_plugin.enable=false \
    vendor.audio.feature.external_dsp.enable=false \
    vendor.audio.feature.external_speaker_tfa.enable=false \
    vendor.audio.feature.external_speaker.enable=false \
    vendor.audio.feature.fluence.enable=true \
    vendor.audio.feature.fm.enable=true \
    vendor.audio.feature.hfp.enable=true \
    vendor.audio.feature.hifi_audio.enable=false \
    vendor.audio.feature.hwdep_cal.enable=false \
    vendor.audio.feature.incall_music.enable=false \
    vendor.audio.feature.keep_alive.enable=false \
    vendor.audio.feature.maxx_audio.enable=false \
    vendor.audio.feature.multi_voice_session.enable=true \
    vendor.audio.feature.ras.enable=true \
    vendor.audio.feature.record_play_concurency.enable=false \
    vendor.audio.feature.snd_mon.enable=true \
    vendor.audio.feature.spkr_prot.enable=true \
    vendor.audio.feature.src_trkn.enable=true \
    vendor.audio.feature.ssrec.enable=true \
    vendor.audio.feature.usb_offload_burst_mode.enable=false \
    vendor.audio.feature.usb_offload_sidetone_volume.enable=false \
    vendor.audio.feature.usb_offload.enable=true \
    vendor.audio.feature.vbat.enable=true \
    vendor.audio.feature.wsa.enable=false

# Enable stats logging in LMKD
TARGET_LMKD_STATS_LOG := true
PRODUCT_PROPERTY_OVERRIDES += \
    ro.lmk.log_stats=true

# Set lmkd options
PRODUCT_PROPERTY_OVERRIDES += \
    ro.lmk.low=1001 \
    ro.lmk.medium=800 \
    ro.lmk.critical=0 \
    ro.lmk.critical_upgrade=false \
    ro.lmk.upgrade_pressure=100 \
    ro.lmk.downgrade_pressure=100 \
    ro.lmk.kill_heaviest_task=true \
    ro.lmk.kill_timeout_ms=100 \
    ro.lmk.use_minfree_levels=true

# Property to enable user to access Google WFD settings.
PRODUCT_PROPERTY_OVERRIDES += \
    persist.debug.wfd.enable=0

# Property to choose between virtual/external wfd display
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.wfd.virtual=0

# Display properties
PRODUCT_PROPERTY_OVERRIDES += \
    persist.demo.hdmirotationlock=false \
    persist.sys.sf.color_saturation=1.0 \
    vendor.display.disable_inline_rotator=1 \
    vendor.display.enable_null_display=0 \
    vendor.display.disable_excl_rect=0 \
    vendor.display.comp_mask=0 \
    vendor.display.enable_default_color_mode=1 \
    vendor.display.enable_optimize_refresh=1 \
    vendor.display.disable_ui_3d_tonemap=1

# Wi-Fi interface name
PRODUCT_PROPERTY_OVERRIDES += \
    wifi.interface=wlan0

# RILD
PRODUCT_PROPERTY_OVERRIDES += \
    ril.subscription.types=NV,RUIM

# Priv-app permisisons
PRODUCT_PROPERTY_OVERRIDES += \
    ro.control_privapp_permissions=enforce

# Perform color transform on the client
PRODUCT_PROPERTY_OVERRIDES += \
    persist.hwc2.skip_client_color_transform=false

# Avoid Adoptable double encryption
PRODUCT_PROPERTY_OVERRIDES += \
    ro.crypto.allow_encrypt_override=true

# Reduce cost of scrypt for FBE CE decryption
PRODUCT_PROPERTY_OVERRIDES += \
    ro.crypto.scrypt_params=15:3:1

# Disable Compressed APEX on 4.14 kernel as Android 12 enforces it and our kernel is not compatible (yet)
ifeq ($(KERNEL_VERSION), 4.14)
OVERRIDE_PRODUCT_COMPRESSED_APEX := false
endif
