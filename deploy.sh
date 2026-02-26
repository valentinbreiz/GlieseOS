#!/usr/bin/env bash
set -euo pipefail

# ── Configuration (edit these) ─────────────────────────────────────────────────
UEFI_IMG=""       # Path to uefi-selene.img (Selene=41mm) or uefi-luna.img (Luna=45mm)
LIMINE_EFI=""     # Path to BOOTAA64.EFI from Limine
MOUNT_POINT="/mnt/watch"
# ───────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTPKG="$SCRIPT_DIR/../PixelWatch-Guides/bootpkg.bin"
KERNEL_ELF="$SCRIPT_DIR/bin/Debug/net10.0/linux-arm64/GlieseOS.elf"
LIMINE_CONF="$SCRIPT_DIR/Bootloader/limine.conf"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
die()   { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

# ── Validate config ────────────────────────────────────────────────────────────
[[ -z "$UEFI_IMG"    ]] && die "UEFI_IMG is not set. Edit deploy.sh and set the path to your uefi-selene.img / uefi-luna.img."
[[ -z "$LIMINE_EFI"  ]] && die "LIMINE_EFI is not set. Edit deploy.sh and set the path to BOOTAA64.EFI."
[[ -f "$UEFI_IMG"    ]] || die "UEFI image not found: $UEFI_IMG"
[[ -f "$LIMINE_EFI"  ]] || die "Limine EFI binary not found: $LIMINE_EFI"
[[ -f "$BOOTPKG"     ]] || die "bootpkg.bin not found: $BOOTPKG"
[[ -f "$LIMINE_CONF" ]] || die "limine.conf not found: $LIMINE_CONF"
command -v adb      >/dev/null || die "adb not found"
command -v fastboot >/dev/null || die "fastboot not found"

# ── Build ──────────────────────────────────────────────────────────────────────
info "Building GlieseOS..."
dotnet build "$SCRIPT_DIR" -c Debug
[[ -f "$KERNEL_ELF" ]] || die "Build succeeded but kernel ELF not found: $KERNEL_ELF"
info "Kernel ELF: $KERNEL_ELF"

# ── USB connection prompt ──────────────────────────────────────────────────────
echo ""
warn "Connect your Pixel Watch 3 to your computer using the charging cradle that shipped with it."
read -rp "    Press Enter once the watch is connected..."
adb devices | grep -v "List of" | grep -q "device$" || die "No ADB device found. Make sure the watch is connected, ADB USB Debugging is enabled, and the connection is authorised on the watch."

# ── Reboot to bootloader ───────────────────────────────────────────────────────
info "Rebooting watch to bootloader..."
adb reboot bootloader
sleep 3

# ── Detect current slot ────────────────────────────────────────────────────────
CURRENT_SLOT=$(fastboot getvar current-slot 2>&1 | grep "current-slot:" | awk '{print $2}')
[[ "$CURRENT_SLOT" == "a" || "$CURRENT_SLOT" == "b" ]] || die "Could not detect current slot (got: '$CURRENT_SLOT')"
info "Current slot: $CURRENT_SLOT"

if [[ "$CURRENT_SLOT" == "a" ]]; then
    INACTIVE_SLOT="b"
else
    INACTIVE_SLOT="a"
fi
info "Flashing bootpkg.bin to inactive slot: modem_$INACTIVE_SLOT"
fastboot flash "modem_$INACTIVE_SLOT" "$BOOTPKG"

# ── Boot UEFI and enter mass storage ──────────────────────────────────────────
info "Booting UEFI..."
fastboot boot "$UEFI_IMG"

echo ""
warn "On the watch: press the digital crown to select 'Mass Storage'."
read -rp "    Press Enter once the watch is in mass storage mode..."

# ── Detect block device ────────────────────────────────────────────────────────
echo ""
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL
echo ""
read -rp "[?] Enter the watch block device (e.g. sdb, NOT sdb1): " WATCH_DEV
WATCH_DEV="${WATCH_DEV#/dev/}"   # strip /dev/ prefix if user included it
[[ -b "/dev/$WATCH_DEV" ]] || die "Block device /dev/$WATCH_DEV not found"

# Find the FAT32 EFI partition
EFI_PART=$(lsblk -o NAME,FSTYPE -r "/dev/$WATCH_DEV" | awk '$2=="vfat" {print "/dev/"$1}' | head -1)
[[ -n "$EFI_PART" ]] || die "No FAT32 partition found on /dev/$WATCH_DEV"
info "EFI partition: $EFI_PART"

# ── Mount and copy ─────────────────────────────────────────────────────────────
sudo mkdir -p "$MOUNT_POINT"
sudo mount "$EFI_PART" "$MOUNT_POINT"
info "Mounted $EFI_PART at $MOUNT_POINT"

info "Installing Limine UEFI binary..."
sudo mkdir -p "$MOUNT_POINT/EFI/BOOT"
sudo cp "$LIMINE_EFI" "$MOUNT_POINT/EFI/BOOT/BOOTAA64.EFI"

info "Copying GlieseOS kernel and config..."
sudo mkdir -p "$MOUNT_POINT/boot"
sudo cp "$KERNEL_ELF"   "$MOUNT_POINT/boot/GlieseOS.elf"
sudo cp "$LIMINE_CONF"  "$MOUNT_POINT/boot/limine.conf"
sudo cp "$LIMINE_CONF"  "$MOUNT_POINT/limine.conf"

info "Unmounting..."
sudo umount "$MOUNT_POINT"

# ── Reboot and boot GlieseOS ───────────────────────────────────────────────────
info "Rebooting to bootloader..."
adb reboot bootloader
sleep 3

info "Erasing modem_$INACTIVE_SLOT to restore normal boot path..."
fastboot erase "modem_$INACTIVE_SLOT"

info "Booting UEFI → Limine → GlieseOS..."
fastboot boot "$UEFI_IMG"

echo ""
info "Done! The watch should now display the GlieseOS watch face."
