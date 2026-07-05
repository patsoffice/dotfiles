# Hardware configuration for arcade
# Filesystem mounts are managed by disko.nix — do not add fileSystems here.
# Regenerate on actual hardware with: nixos-generate-config --no-filesystems
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  # Early KMS for the AMD iGPU so the console/compositor come up cleanly.
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # AMD Raphael iGPU (Ryzen 7000-series). Mesa/amdgpu — no proprietary driver.
  services.xserver.videoDrivers = [ "amdgpu" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
