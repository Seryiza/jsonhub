{
  description = "jsonhub development shell with Chromium for browser-based script testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          # Prefer Chromium here: Nix-managed extension workflows are better aligned
          # with Chromium than with proprietary Google Chrome.
          jsonhubChrome = pkgs.writeShellApplication {
            name = "jsonhub-chrome";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.chromium
            ];
            text = ''
              profile_dir="$PWD/.jsonhub/chromium-profile"
              mkdir -p "$profile_dir"

              exec "${pkgs.chromium}/bin/chromium" \
                --user-data-dir="$profile_dir" \
                --no-first-run \
                --no-default-browser-check \
                "$@"
            '';
          };
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.chromium
              pkgs.nodejs
              jsonhubChrome
            ];

            shellHook = ''
              export JSONHUB_CHROME_BIN="${pkgs.chromium}/bin/chromium"
              export CHROME_BIN="$JSONHUB_CHROME_BIN"
              export JSONHUB_CHROME_USER_DATA_DIR="$PWD/.jsonhub/chromium-profile"
              mkdir -p "$JSONHUB_CHROME_USER_DATA_DIR"
            '';
          };
        }
      );
    };
}
