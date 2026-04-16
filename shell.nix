{ pkgs ? import <nixpkgs> { } }:

let
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
pkgs.mkShell {
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
}
