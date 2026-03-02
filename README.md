# GlieseOS

A simple Pixel Watch OS made with [Cosmos](https://github.com/valentinbreiz/nativeaot-patcher).

https://github.com/user-attachments/assets/8584ebbb-62d6-49ec-b24a-c1fa0925c170

## Boot chain

A concise sequence of what runs and who loads what when deploying and booting GlieseOS:

1. Android bootloader -> mu UEFI firmware (`mu_seluna_platforms`) 

2. UEFI firmware -> Limine (`BOOTAA64.EFI`): the UEFI firmware on the device enumerates the EFI partition and finds `BOOTAA64.EFI` (the Limine EFI binary). The firmware executes that EFI application as the bootloader.

3. Limine -> `GlieseOS.elf`: Limine acts as a UEFI bootloader. It locates `GlieseOS.elf` on the EFI filesystem, loads the ELF image into memory, and transfers control to Cosmos.

---

## Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- [CosmosOS gen3](https://github.com/valentinbreiz/nativeaot-patcher)
- `adb` and `fastboot`
- UEFI image for your watch from [mu_seluna_platforms releases](https://github.com/WOA-Project/mu_seluna_platforms/releases/latest)
  - Use **Selene** for the Pixel Watch 3 41mm, **Luna** for the 45mm
- [Limine](https://github.com/limine-bootloader/limine) bootloader (`BOOTAA64.EFI`)
- Pixel Watch 3 **charging cradle** (the one that shipped with the watch — required for USB connectivity)

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
# Then: Settings > For Developers > Enable ADB Debugging + Enable OEM Unlock
adb reboot bootloader
fastboot flashing unlock
```

> **Note:** `fastboot flashing unlock` will **wipe the watch**. The watch will reboot into a fastboot menu showing options like **Start**, Recovery Mode, Reboot Bootloader, Power Off, etc. Press the digital crown to select **Start** and let the watch boot normally. Go through the initial setup, then go back into Settings and re-enable ADB USB Debugging. Once done, run `adb reboot bootloader` again before continuing.

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
