{ pkgs ? import <nixpkgs> {} }:

let
  script = pkgs.writeScriptBin "run-docker-build" ''
    #! ${pkgs.stdenv.shell}
    set -e

    echo "building root image..." >&2
    imageOut=$(nix-build -A image --no-out-link)
    echo "importing root image..." >&2
    docker load < $imageOut
    echo "building {unstable.version}..." >&2
    cp -f {baseDocker} Dockerfile
    docker build -t lnl7/nix:{unstable.version} .
    docker rmi nix-base:{unstable.version}
  '';
in
#  script
pkgs.stdenv.mkDerivation {
  name = builtins.trace ("script= " + script)
  "docker_test";

  # phases = [ "installPhase" ];
  src = pkgs.lib.cleanSource ./.;
  BUILD_TARGET = "\"Ala ma 41kota!\"";
  _installPhase = builtins.trace (">>>>>>>> installPhase " ) ''
    mkdir $out
    echo ">>>>>>>>>>>>>> out= " $out
    ech "Ala ma kota" > $out/jk.test
    echo $out >> $out/jk.test
    echo cp ${script}/run-docker-build $out
#   '';

#   src =
#   cleanSourceWith {
#     filter = name: _type: !(hasSuffix ".nix" name);
#     src = cleanSource script;
#   };

#   doCheck = true;

}
