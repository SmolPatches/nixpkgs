# export a function that can build various Linux Sui Versions
{
  lib,
  system ? stdenv.hostPlatform.system,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  gccForLibs,
  versionCheckHook,
}:

let
  arch =
    if "${system}" == "aarch64-linux" then
      "aarch64"
    else if "${system}" == "x86_64-linux" then
      "x86_64"
    else
      throw "using unsupported system"; # architecture check for builder

  mk_release =
    # builder function
    {
      type ? "mainnet",
      version_number,
      arch,
      vhash,
    }:

    stdenv.mkDerivation (finalAttrs: {
      pname = "sui-mainnet";
      version = version_number;
      src = fetchzip {
        url = "https://github.com/MystenLabs/sui/releases/download/${type}-v${finalAttrs.version}/sui-${type}-v${finalAttrs.version}-ubuntu-${arch}.tgz";
        hash = vhash;
        stripRoot = false;
      };
      nativeBuildInputs = [
        autoPatchelfHook
      ];
      buildInputs = [ gccForLibs.lib ];
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
        platforms = lib.platforms.linux;
        mainProgram = "sui";
        maintainers = with lib.maintainers; [ smolpatches ];
      };
    });
in

mk_release {
  type = "mainnet";
  arch = arch;
  version_number = "1.46.3";
  vhash = "sha256-kwoibkFDrBLs3OB1dgofgdJTqyOiyozXWncN5MJ1Uco=";
}
