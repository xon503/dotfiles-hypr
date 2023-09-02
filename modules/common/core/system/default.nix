_: {
  imports = [
    ./activation # activation system for nixos-rebuild
    ./boot # boot and bootloader configurations
    ./emulation # emulation setup to fix QEMU issues
    ./hardware # hardware - i.e bluetooth, sound, tpm etc.
    ./media # enable multimedia
    ./os # system configurations
    ./smb # host and recive smb shares
    ./virtualization # hypervisor and virtualisation related options - docker, QEMU, waydroid etc.
  ];
}
