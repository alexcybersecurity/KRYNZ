# KRYNZ
Source files for KRYNZ: A custom 16-bit bootloader Tetris environment and MBR overwriter payload. Provided as raw source code for educational compilation and emulation research.
|
|
|
|
An advanced low-level programming experiment combining a bare-metal 16-bit x86 operating environment, a fully functional Tetris game engine written in Assembly, and a user-triggered Master Boot Record (MBR) overwriting payload written in C++. 
|
|
|
|
Inspired by legacy internet history malware aesthetics (like MEMZ and WannaCry), this project serves as an educational dive into legacy hardware orchestration, real-mode interruption vectors, and sector-zero volatility.

---

## CRITICAL WARNING & DISCLAIMER
**THIS REPOSITORY CONTAINS SOURCE CODE DESIGNED TO OPERATE DIRECTLY ON SYSTEM BOOT SECTORS. RUNNING THE COMPILED ARTIFACTS NATIVELY ON PHYSICAL HARDWARE WILL OVERWRITE YOUR PARTITION TABLE, DESTROY THE VOLUME BOOT RECORD, AND PREVENT YOUR OPERATING SYSTEM FROM BOOTING.**

* This project is hosted **strictly for educational research, historical documentation, and emulation analysis**.
* The author assumes absolutely no liability for data loss, hardware damage, or system instability caused by improper compilation or execution of this code.
* **DO NOT RUN THE COMPILED INSTALLER ON YOUR MAIN MACHINE.** Testing must be conducted exclusively within sandboxed, virtualized environments (e.g., QEMU, VirtualBox, VMware) or on dedicated, non-critical test rigs.

---

## Project Architecture & Technical Specs

The system is split into two independent domains: the **Host Installer (C++)** which stages the payload, and the **Bare-Metal Game Environment (16-bit Assembly)** which executes upon machine reboot.

### 1. The Bare-Metal Environment (16-Bit x86 Assembly)
Operating entirely outside the boundaries of modern operating systems, KRYNZ runs inside the x86 Real Mode architecture, inheriting the classic 1MB memory limitation and interacting directly with legacy hardware interfaces.

* **Stage 1 Bootloader (`boot.asm`):** Constrained to the strict 512-byte MBR limit and ending with the `0xAA55` signature. It initializes the stack pointer at `0x7C00`, clears registers, and boots directly into standard **BIOS Text Mode (80x25, 16 colors)** via `INT 10h / AX=0003h`. It triggers a dual-colored screen matrix (Black/Red split) and orchestrates a custom timed typing intro animation. Finally, it toggles **VGA Mode 13h**, invokes `INT 13h / AH=02h` to read 10 subsequent game sectors from the drive into memory location `0x0000:0x7E00`, and executes a long jump to start the game loop.
  
* **Graphics Architecture & Double Buffering:** The game utilizes a high-performance rendering pipeline to avoid raster tearing. Instead of writing directly to the active VGA frame buffer (`0xA000:0000`), the engine establishes a custom **backbuffer** at segment `0x9000`. All drawing routines (grid manipulation, falling shapes, background clearing) render to this scratchpad space. Once the vertical blanking period is detected via hardware port `0x3DA`, a fast string transfer operation (`rep movsd`) dumps the off-screen buffer directly into video memory.

* **Game Engine, Timing, & Audio Tracker:** Tetris grid allocation uses a sequential 640-byte flat matrix array mapped in RAM to track static block states. Player inputs are queried via non-blocking keyboard polling (`INT 16h / AH=01h`). Sound rendering utilizes a custom interrupt service routine hooked into **System Timer Interrupt 8h** (`0x0020`), driving the programmable interval timer (PIT) chip via IO ports `0x43` and `0x42` to synthesize a continuous multi-phrase musical score through the PC Speaker.

* **The Hardware Termination Hook:** Upon triggering the `game_over_flag`, the engine detaches the custom interrupt vectors, mutes the sound hardware, and fires a visual high-frequency dual-color screen flashing routine using a localized delay loop. After displaying a centralized `GAME OVER` string, it triggers a system reset by jumping straight to the BIOS initialization vector at `0xFFFF:0x0000`.

### 2. The Payload Installer (C++)
The Visual Studio component acts as the staging mechanism that simulates a malicious sector corruption.

* **Low-Level Disk Access:** It utilizes the Windows API function `CreateFileW` with `GENERIC_WRITE` and `FILE_SHARE_READ | FILE_SHARE_WRITE` access rights, targeting the raw device path `\\\\.\\PhysicalDrive0`.
  
* **Sector Manipulation:** By invoking `WriteFile`, the compiled binary bypasses standard user-space filesystem abstractions (like NTFS) and forces the underlying storage controller to replace the active Master Boot Record (Sector 0) with the custom `KRYNZ` boot image binary.

---

## Repository Contents
* `main.cpp` - The raw Visual Studio C++ host component for staging and raw sector writing.
* `boot.asm` - Stage 1 x86 assembly bootloader code (Initializes registers and reads Stage 2).
* `game.asm` - Stage 2 x86 assembly code housing the full Tetris game loop, rendering pipelines, and custom glitch animations.
* `krynz_boot.img` - Pre-assembled, raw binary image containing the combined execution pipeline for safe loading inside emulators.

---

## 🚀 How to Safe-Test (Emulation Guide)

If you wish to test the 16-bit Assembly Tetris OS safely without compiling the dangerous C++ installer or risking your actual physical drives, you can build and boot the environment via **QEMU**:

### Prerequisites
Ensure you have `NASM` (Netwide Assembler) and `QEMU` installed on your machine (or within WSL/Linux).

### Compilation & Execution Steps:

1. **Assemble Stage 1 and Stage 2:**
   ```bash
   nasm -f bin boot.asm -o boot.bin
   nasm -f bin game.asm -o game.bin

2. **Stitch the binaries into a unified bootable image:**
   ```bash
   cat boot.bin game.bin > krynz_payload.bin

3. **Generate a standardized raw disk image layout:**
   ```bash
   dd if=/dev/zero of=krynz_test.img bs=512 count=2880
   dd if=krynz_payload.bin of=krynz_test.img conv=notrunc

4. **Boot safely inside the QEMU emulator:**
   ```bash
   qemu-system-i386 -drive format=raw,file=krynz_test.img

License:
This project is open-sourced under the MIT License. The software is provided "as is", without warranty of any kind, express or implied.

## Connect & Support
If you enjoy low-level programming experiments, OS dev, and cybersecurity projects, make sure to follow for updates, behind-the-scenes content, and upcoming releases:

* **Follow Alex Cybersecurity for updates and more!**
* **YouTube:** [Alex Cybersecurity](https://youtube.com/@alex.cybersecurity)
