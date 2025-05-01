# export a function that can build various Linux Sui Versions
{
  lib,
  system ? stdenv.hostPlatform.system,
  platform ? stdenv.hostPlatform,
  stdenv,
  target ? if lib.strings.hasInfix "x86_64" system then "x86_64" else "aarch64",
  fetchzip,
  autoPatchelfHook,
  gccForLibs,
  versionCheckHook,
}:

let
  mk_release =
    # builder function
    {
      type ? "mainnet",
      version_number,
      arch,
      vhash,
    }:
    let
      triple = if platform.isLinux then "ubuntu-${arch}" else "macos-${arch}";
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "sui-mainnet";
      version = version_number;
      src = fetchzip {
        url = "https://github.com/MystenLabs/sui/releases/download/${type}-v${finalAttrs.version}/sui-${type}-v${finalAttrs.version}-${triple}.tgz";
        hash = vhash;
        stripRoot = false;
      };
      nativeBuildInputs = lib.optionals platform.isLinux [
        autoPatchelfHook
      ];
      buildInputs = lib.optionals platform.isLinux [ gccForLibs.lib ];
      installPhase = ''
        runHook preInstall
        install -m 755 -d $out/bin
        install -m 755 sui* move-analyzer $out/bin
        runHook postInstall
      '';
      # check the version for each binary
      installCheckPhase = ''
        runHook preInstallCheck
        for f in $out/bin/*; do
             echo Checking version for $f
             if [[ ! $f =~ "${finalAttrs.version}" ]] then
                  echo FAILED $f: "${finalAttrs.version}"
                  exit 1
              fi
         done
         runHook postInstallCheck
      '';
      doInstallCheck = true;
      meta = {
        longDescription = "Sui, a next-generation smart contract platform with high throughput, low latency, and an asset-oriented programming model powered by the Move programming language";
        description = "patched Sui binaries for nix compat";
        homepage = "https://sui.io/";
        changelog = "https://github.com/MystenLabs/sui/releases/tag/${type}-v${version_number}";
        downloadPage = "https://github.com/MystenLabs/sui";
        license = lib.licenses.asl20;
        platforms = lib.platforms.linux ++ lib.platforms.darwin;
        mainProgram = "sui";
        maintainers = with lib.maintainers; [ smolpatches ];
      };
    });
in
mk_release {
  # BUILD MAC RELEASE
  type = "mainnet";
  arch = target;
  version_number = "1.46.3";
  vhash = "sha256-kwoibkFDrBLs3OB1dgofgdJTqyOiyozXWncN5MJ1Uco=";
}
