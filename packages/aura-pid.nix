{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  command = writeShellScriptBin "aura-pid" ''
    AURA_PID_DIR=''${TMPDIR:-/tmp}/.aura/pids
    mkdir -p $AURA_PID_DIR

    AURA_PID_PATH=$AURA_PID_DIR/$2.pid
    case $1 in
      start)
        if [ -f $AURA_PID_PATH ]
        then
          echo "$2 already running"
          exit 1
        fi

        echo "Starting $2"
        ''${@:3} &
        echo $! > $AURA_PID_PATH
      ;;
      stop)
        echo "Stopping $2"
        if [ -f $AURA_PID_PATH ] && kill -TERM $(cat $AURA_PID_PATH) 2> /dev/null
        then
          tail --pid $(cat $AURA_PID_PATH) -f /dev/null && echo "Stopped $2"
        fi
        rm $AURA_PID_PATH
      ;;
      *)
        echo "Usage: aura-pid [start|stop] name command [args]..."
        exit 1
      ;;
    esac
  '';
in
buildEnv {
  name = "aura-pid";
  paths = [
    command
  ];
}
