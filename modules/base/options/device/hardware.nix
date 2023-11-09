{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.modules.device = {
    type = mkOption {
      type = types.enum ["laptop" "desktop" "server" "hybrid" "lite" "vm"];
      default = "";
    };

    cpu = mkOption {
      type = types.enum ["pi" "intel" "vm-intel" "amd" "vm-amd" null];
      default = null;
    };

    gpu = mkOption {
      type = types.enum ["amd" "intel" "nvidia" null];
      default = null;
      description = "The manifacturer/type of the primary system gpu";
    };

    monitors = mkOption {
      type = with types; listOf str;
      default = [];
      description = ''
        this does not affect any drivers and such, it is only necessary for
        declaring things like monitors in window manager configurations
        you can avoid declaring this, but I'd rather if you did declare
      '';
    };

    keyboard = mkOption {
      type = types.enum ["us" "gb"];
      default = "gb";
    };
  };
}
