#!/bin/bash
# SIGTERM received (the container is stopping, every process must be gracefully stopped before the timeout).

function setup_channels {
    echo 'root:x:0:0:root user:/root:/bin/sh' > /etc/passwd
    echo 'nobody:x:65534:65534:nobody:/var/empty:/bin/sh' >> /etc/passwd
    echo 'nixbld:x:30000:nixbld1,nixbld10,nixbld11,nixbld12,nixbld13,nixbld14,nixbld15,nixbld16,nixbld17,nixbld18,nixbld19,nixbld2,nixbld20,nixbld21,nixbld22,nixbld23,nixbld24,nixbld25,nixbld26,nixbld27,nixbld28,nixbld29,nixbld3,nixbld30,nixbld31,nixbld32,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9' >> /etc/group
    echo 'nogroup:x:65534:' >> /etc/group
    for i in $(seq 1 32); do
       echo "nixbld$i:x:$((30000 + $i)):30000::/var/empty:/bin/nologin" >> /etc/passwd
    done
    nix-channel --add "https://nixos.org/channels/nixpkgs-unstable" nixpkgs
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install

    # create the userPrefs directory for burp
    mkdir -p /root/.java/.userPrefs/
    
    
}

function finish() {
    echo "READY"
}

function endless() {
  # Start action / endless
  # setup_channels

  finish
  # Entrypoint for the container, in order to have a process hanging, to keep the container alive
  # Alternative to running bash/zsh/whatever as entrypoint, which is longer to start and to stop and to very clean
  [[ ! -p /tmp/.entrypoint ]] && mkfifo -m 000 /tmp/.entrypoint # Create an empty fifo for sleep by read.
  read -r <> /tmp/.entrypoint  # read from /tmp/.entrypoint => endlessly wait without sub-process or need for TTY option
}


# Function to handle termination signals
cleanup() {
   # Shutting down the container.
   # Sending SIGTERM to all interactive process for proper closing
   pgrep vnc && desktop-stop  # Stop webui desktop if started TODO improve desktop shutdown
   # shellcheck disable=SC2046
   kill $(pgrep -f -- openvpn | grep -vE '^1$') 2>/dev/null
   # shellcheck disable=SC2046
   kill $(pgrep -x -f -- zsh) 2>/dev/null
   # shellcheck disable=SC2046
   kill $(pgrep -x -f -- -zsh) 2>/dev/null
   # shellcheck disable=SC2046
   kill $(pgrep -x -f -- bash) 2>/dev/null
   # shellcheck disable=SC2046
   kill $(pgrep -x -f -- -bash) 2>/dev/null
   # Wait for every active process to exit (e.g: shell logging compression, VPN closing, WebUI)
   WAIT_LIST="$(pgrep -f "(.log|spawn.sh|vnc)" | grep -vE '^1$')"
   for i in $WAIT_LIST; do
     # Waiting for: $i PID process to exit
     tail --pid="$i" -f /dev/null
   done
   exit 0
}

# Trap signals
trap cleanup SIGTERM SIGINT


### Argument parsing

# Par each parameter
for arg in "$@"; do
 # Check if the function exist
 FUNCTION_NAME=$(echo "$arg" | cut -d ' ' -f 1)
 if declare -f "$FUNCTION_NAME" > /dev/null; then
   $arg
 else
   echo "The function '$arg' doesn't exist."
 fi
done
