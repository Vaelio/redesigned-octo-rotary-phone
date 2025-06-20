#!/bin/bash
# SIGTERM received (the container is stopping, every process must be gracefully stopped before the timeout).

function setup_omz {
    /share/oh-my-zsh/tools/install.sh
    mv /workspace/.zshrc.pre-oh-my-zsh /workspace/.zshrc
}

function finish() {
    echo "READY"
}

function endless() {
  # Start action / endless
  finish
  # Entrypoint for the container, in order to have a process hanging, to keep the container alive
  # Alternative to running bash/zsh/whatever as entrypoint, which is longer to start and to stop and to very clean
  [[ ! -p /tmp/.entrypoint ]] && mkfifo -m 000 /tmp/.entrypoint # Create an empty fifo for sleep by read.
  read -r <> /tmp/.entrypoint  # read from /tmp/.entrypoint => endlessly wait without sub-process or need for TTY option
}


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
