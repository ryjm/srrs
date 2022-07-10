{ pkgs ? import <nixpkgs> { } }:

with pkgs;
let
  desk-path = "/mnt/laptop-sandisk/distem-bottus-littel-wolfur/seer/";
  interface-path = "ui";
  npm-scripts = rec {
    inherit scripts;
    start = writeShellScriptBin "start" ''
      npm run start --prefix ${interface-path}
    '';
    build = writeShellScriptBin "build" ''
      npm run build --prefix ${interface-path}
    '';
    install = writeShellScriptBin "setup" ''
      npm install --prefix ${interface-path}
    '';
    run = writeShellScriptBin "run" ''
      npm run --prefix ${interface-path}
    '';
  };
  scripts = {
    # Print all npm scripts
    nss = writeShellScriptBin "nss" ''
      jq ".scripts" ${interface-path}/package.json
    '';
    # Watch a repo for changes and copy it to `desk-path`
    urbit-watch = writeShellScriptBin "urbit-watch" ''
      watch cp -RL ./desk/* ${desk-path}
    '';
  };
  yarn-scripts = rec {
    inherit scripts;
    start = writeShellScriptBin "start" ''
      yarn --cwd ${interface-path} start
    '';
    build = writeShellScriptBin "build" ''
      yarn --cwd ${interface-path} build
    '';
    install = writeShellScriptBin "setup" ''
      yarn --cwd ${interface-path} install
    '';
    run = writeShellScriptBin "run" ''
      yarn --cwd ${interface-path} run
    '';
  };
in mkShell {
  # buildInputs = with npm-scripts; [
  #   nodejs
  #   jq
  #   scripts.urbit-watch
  #   build
  #   start
  #   install
  #   run
  #   scripts.nss
  # ]
  #  ;
  buildInputs = with yarn-scripts; [
    jq
    scripts.urbit-watch
    build
    start
    install
    run
    scripts.nss
  ];
  shellHook = ''
    export PATH="$PWD/${interface-path}/node_modules/.bin/:$PATH"
    # save shell history in project folder
    HISTFILE=${toString ./.history}
  '';

}
