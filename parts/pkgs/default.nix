{self, ...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: {
    packages = let
      docs = pkgs.callPackage (self + /docs) {inherit self;};
    in {
      docs-md = docs.md;
      docs-html = docs.html;

      lutgen-rs = pkgs.callPackage ./lutgen-rs.nix {};
      patched-gjs = pkgs.callPackage ./patched-gjs.nix {};
      plymouth-theme-catppuccin = pkgs.callPackage ./plymouth-theme-catppuccin.nix {};
      headscale-ui = pkgs.callPackage ./headscale-ui.nix {};

      bellado = inputs'.bellado.packages.default;
      catppuccinifier-cli = inputs'.catppuccinifier.packages.cli;
    };
  };
}