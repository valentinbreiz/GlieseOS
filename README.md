
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

### 2. Run the deploy script

Edit `deploy.sh` and set the two variables at the top:

```bash
UEFI_IMG="/path/to/uefi-selene.img"    # or uefi-luna.img for the 45mm
LIMINE_EFI="/path/to/BOOTAA64.EFI"
```

Then run:

```bash
./deploy.sh
```

The script will build GlieseOS, flash `bootpkg.bin` to the inactive modem slot, boot the UEFI, guide you through mass storage, copy Limine + the kernel to the EFI partition, and boot GlieseOS automatically.

The UEFI will find `BOOTAA64.EFI` (Limine), which loads `GlieseOS.elf` from the EFI partition. The watch face renders via the UEFI GOP framebuffer.
