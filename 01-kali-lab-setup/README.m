# Project 1: Setting Up a Kali Linux Attack VM on Apple Silicon

## Objective
Build a Kali Linux virtual machine to serve as the "attacker" box in a home 
cybersecurity lab, running on a 2022 MacBook Air (M2).

## Environment
- Host: MacBook Air M2, macOS
- Hypervisor: UTM (QEMU-based, ARM64)
- Guest OS: Kali Linux 2026.2 (ARM64 installer)
- Allocated resources: 4GB RAM, 2 CPU cores

## Steps
1. Installed UTM via Homebrew (`brew install --cask utm`)
2. Downloaded the Kali Linux ARM64 installer ISO from kali.org
3. Created a new VM in UTM (Virtualize > Linux)
4. Booted the installer

## Problems Encountered
The installer window displayed a blank/black screen ("Display output is not 
active") regardless of boot method (Graphical Install vs text Install).

Troubleshooting attempted:
- Tried both Graphical Install and text-based Install — same result
- Checked UEFI Boot setting in QEMU config — enabled, made no difference
- Switched Emulated Display Card between `virtio-gpu-pci` and `virtio-ramfb`
- Attempted using Apple Virtualization instead of QEMU — hit a separate 
  "Invalid virtual machine configuration" error due to ISO attachment issues
- Confirmed UEFI Boot disabled — still no display output

**Root cause / fix:** UTM has a known display bug with the Kali ARM64 
installer on some Apple Silicon configurations. The fix was to remove the 
graphical Display device entirely and add a Serial device instead, which 
routes the installer through a text-based console. This bypassed the broken 
graphical framebuffer completely and allowed the installer to run normally.

After installation completed, a second issue arose: rebooting looped back 
into the installer instead of booting the installed system, because the 
installer ISO was still attached as a boot device. Fixed by manually 
clearing the ISO path from the virtual CD/DVD drive in UTM's drive settings 
before rebooting.

## What I Learned
- How UTM/QEMU virtual display devices work, and that display card type 
  (virtio-gpu-pci vs virtio-ramfb) can cause silent boot failures
- The difference between UEFI and legacy BIOS boot in a VM context
- How to use a serial console as a fallback when a graphical console fails
- The importance of detaching installation media before rebooting a VM
- Persistence in troubleshooting: working through multiple hypotheses 
  (UEFI, display driver, virtualization backend) before finding the actual 
  documented fix
