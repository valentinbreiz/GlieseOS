
<img width="480" height="270" alt="image" src="https://github.com/user-attachments/assets/5fc26838-6fca-48cc-9190-2849c6cd99f2" />

# GlieseOS

A simple Pixel Watch OS made with [Cosmos](https://github.com/valentinbreiz/nativeaot-patcher).

---

## Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- `aarch64-elf-gcc` (ARM64 cross-compiler)
- `adb` and `fastboot`
- Pixel Watch 3 **charging cradle** (the one that shipped with the watch — required for USB connectivity)
- UEFI image for your watch from [mu_seluna_platforms releases](https://github.com/WOA-Project/mu_seluna_platforms/releases/latest)
  - Use **Selene** for the Pixel Watch 3 41mm, **Luna** for the 45mm
- [Limine](https://github.com/limine-bootloader/limine) bootloader (`BOOTAA64.EFI`)

---

## Build

```bash
git clone https://github.com/valentinbreiz/GlieseOS
cd GlieseOS
dotnet build
```

Output:
- ISO: `bin/Debug/net10.0/linux-arm64/cosmos/GlieseOS.iso`
- Kernel ELF: `bin/Debug/net10.0/linux-arm64/GlieseOS.elf`

---

## Deploy to Pixel Watch 3

### 1. Unlock the bootloader (one-time)

```bash
# On the watch: Settings > About > tap Build Number 7 times
# Then: Settings > For Developers > Enable ADB USB Debugging + OEM Unlock
adb reboot bootloader
fastboot flashing unlock
```

> **Note:** `fastboot flashing unlock` will **wipe the watch**. After it reboots, go back into Settings and re-enable ADB USB Debugging, then run `adb reboot bootloader` again before continuing.

### 2. Get into mass storage

Flash the boot menu package to the **inactive** modem slot, then boot UEFI:

```bash
adb reboot bootloader
fastboot getvar current-slot   # note the result: a or b

# If current slot is a, flash to b — and vice versa
fastboot flash modem_b bootpkg.bin   # or modem_a
fastboot boot uefi.img
```

On the watch, press the **digital crown** to select **Mass Storage**. The watch now appears as a block device on your host.

### 3. Mount the EFI partition

```bash
lsblk                                  # identify the watch block device, e.g. /dev/sdX
sudo mkdir -p /mnt/watch
sudo mount /dev/sdX<N> /mnt/watch      # mount the FAT32 EFI partition
```

### 4. Copy GlieseOS to the watch

```bash
# Install Limine UEFI binary
sudo mkdir -p /mnt/watch/EFI/BOOT
sudo cp /path/to/limine/BOOTAA64.EFI /mnt/watch/EFI/BOOT/

# Copy kernel and bootloader config
sudo mkdir -p /mnt/watch/boot
sudo cp bin/Debug/net10.0/linux-arm64/GlieseOS.elf /mnt/watch/boot/GlieseOS.elf
sudo cp Bootloader/limine.conf /mnt/watch/boot/limine.conf
sudo cp Bootloader/limine.conf /mnt/watch/

sudo umount /mnt/watch
```

### 5. Boot GlieseOS

```bash
adb reboot bootloader

# Erase the modem slot to restore the normal boot path
fastboot erase modem_b   # or modem_a — whichever you flashed in step 2

fastboot boot uefi.img
```

The UEFI will find `BOOTAA64.EFI` (Limine), which loads `GlieseOS.elf` from the EFI partition. The watch face renders via the UEFI GOP framebuffer.
