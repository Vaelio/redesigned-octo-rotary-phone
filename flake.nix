{
  description = "Docker image with runtime mounts via nix run";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/25.05";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # A wrapper script that mounts ./data and runs the image
      runDevScript = pkgs.writeShellScriptBin "run-my-dev-container" ''
        if [ $# -ge 1 ]; then
                  CTR_NAME="formol-$1"
        else
            rand="$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c5)"
            CTR_NAME="formol-$rand"
        fi
        if sudo docker container inspect "$CTR_NAME" >/dev/null 2>&1; then
          echo "[-] Skipping container creation"
        else
          if [ ! -d ./workspace ]; then
                  mkdir ./workspace
          fi
          echo "[+] Creating $CTR_NAME container..."
          sudo docker create \
            --network=host \
            --name $CTR_NAME \
            --hostname $CTR_NAME \
            --privileged \
            --cap-add=SYS_ADMIN \
            -e SHELL=zsh \
            -e USER=root \
            -e HOME=/root \
            -e NIXPKGS_ALLOW_UNFREE=1 \
            -e DISPLAY=:0 \
            -e _JAVA_AWT_WM_NONREPARENTING=1 \
            -e QT_X11_NO_MITSHM=1 \
            -e ZSH_THEME=gentoo \
            --mount type=bind,src=/tmp/.X11-unix,dst=/tmp/.X11-unix \
            --mount type=bind,src=/etc/localtime,dst=/etc/localtime,readonly=true \
            --mount type=bind,src=./workspace,dst=/workspace \
            nix-pentest-ctr \
            /bin/bash /entrypoint.sh endless
          echo "[+] Copying javaprefs for burp"
          sudo docker cp /root/.java/.userPrefs/burp/ $CTR_NAME:/root/.java/.userPrefs/burp/
        fi
        if sudo docker ps --filter "name=$CTR_NAME" --filter "status=running" --format '{{.Names}}' | grep -qx "$CTR_NAME"; then
          echo "[-] Container already started"
        else
          echo "[+] Starting the container..."
          sudo docker start "$CTR_NAME"
          sleep 3
        fi
        echo "🚀 Exec-ing inside the container..."
        sudo docker exec -w /workspace -e SHELL=/bin/zsh -ti "$CTR_NAME" zsh -c 'source /root/.zshrc; zsh -i'
      '';
      runScript = pkgs.writeShellScriptBin "run-my-container" ''
        if [ $# -ge 1 ]; then
          CTR_NAME="formol-$1"
        else
          rand="$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c5)"
          CTR_NAME="formol-$rand"
        fi
        if sudo docker container inspect "$CTR_NAME" >/dev/null 2>&1; then
          echo "[-] Skipping container creation"
        else
          if [ ! -d ./workspace ]; then
            mkdir ./workspace
          fi
          echo "[+] Creating $CTR_NAME container..."
          sudo docker create \
            --network=host \
            --name $CTR_NAME \
            --hostname $CTR_NAME \
            --privileged \
            --cap-add=SYS_ADMIN \
            -e USER=root \
            -e HOME=/root \
            -e NIXPKGS_ALLOW_UNFREE=1 \
            -e SHELL=zsh \
            -e DISPLAY=:0 \
            -e _JAVA_AWT_WM_NONREPARENTING=1 \
            -e QT_X11_NO_MITSHM=1 \
            -e ZSH_THEME=gentoo \
            --mount type=bind,src=/tmp/.X11-unix,dst=/tmp/.X11-unix \
            --mount type=bind,src=/etc/localtime,dst=/etc/localtime,readonly=true \
            --mount type=bind,src=./workspace,dst=/workspace \
            ghcr.io/vaelio/nix-pentest-ctr:latest \
            /bin/bash /entrypoint.sh endless
          echo "[+] Copying javaprefs for burp"
          sudo docker cp /root/.java/.userPrefs/burp/ $CTR_NAME:/root/.java/.userPrefs/burp/
        fi
        if sudo docker ps --filter "name=$CTR_NAME" --filter "status=running" --format '{{.Names}}' | grep -qx "$CTR_NAME"; then
          echo "[-] Container already started"
        else
            echo "[+] Starting the container..."
            sudo docker start "$CTR_NAME"
            sleep 3
        fi

        echo "🚀 Exec-ing inside the container..."
        sudo docker exec -w /workspace -e SHELL=/bin/zsh -ti "$CTR_NAME" zsh -c 'source /root/.zshrc; zsh -i'
      '';
    in
    {
      # The default app: nix run . → launches container with mount
      apps.${system}.default = {
        type = "app";
        program = "${runScript}/bin/run-my-container";
      };


      # Optional: nix develop gives access to run script
      devShells.${system}.default = pkgs.mkShell {
        packages = [ runDevScript ];
      };
    };
}

