{
  description = "Docker image with runtime mounts via nix run";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/25.05";

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      linux-tools = with pkgs; [ coreutils-full lsd zsh bash oh-my-zsh fzf zellij curl wget nano vim git iconv tmux zsh-z zsh-autosuggestions zsh-completions zsh-syntax-highlighting python312 findutils gash-utils];
      ctr-tools = with pkgs.dockerTools; [ usrBinEnv binSh caCertificates fakeNss];
      ad-tools = with pkgs; [ netexec smbclient-ng samdump2 nbtscan openldap pretender onesixtyone sccmhunter krb5 responder mitm6 python312Packages.impacket python312Packages.lsassy bloodhound bloodhound-py neo4j python312Packages.ldapdomaindump];
      network-tools = with pkgs; [ nmap proxychains netcat socat simple-http-server ];
      pwn-tools = with pkgs; [ gdb gef nasm ropgadget python312Packages.ropper pwntools cutter rocmPackages.llvm.clang ];
      nix-pentest = pkgs.dockerTools.buildLayeredImage {
        name = "nix-pentest-ctr";
        tag = "latest";
        config = {
          Cmd = [ "${pkgs.bash}/bin/bash" ]; # Runs bash interactively
        };
	contents = with pkgs; [
	  ./scripts
	  ctr-tools
	  linux-tools
	  ad-tools
	  network-tools
	];
      };

      # A wrapper script that mounts ./data and runs the image
      runScript = pkgs.writeShellScriptBin "run-my-container" ''
        CTR_NAME=formol-$(basename "$PWD")
	if [ ! -d "./workspace" ]; then
              mkdir ./workspace
        fi
        #sudo docker load < ${nix-pentest}
	if sudo docker container inspect "$CTR_NAME" >/dev/null 2>&1; then
            echo "[-] Skipping container creation"
        else
            echo "[+] Creating $CTR_NAME container..."
            sudo docker create \
	      --network=host \
              --name $CTR_NAME \
              --hostname $CTR_NAME \
	      -e HOME=/workspace \
	      -e SHELL=zsh \
	      -e DISPLAY=:0 \
	      -e _JAVA_AWT_WM_NONREPARENTING=1 \
	      -e QT_X11_NO_MITSHM=1 \
              -e ZSH_THEME=gentoo \
	      --mount type=bind,src=/tmp/.X11-unix,dst=/tmp/.X11-unix \
              --mount type=bind,src=/etc/localtime,dst=/etc/localtime,readonly=true \
              --mount type=bind,src=/root/.exegol/my-resources,dst=/opt/my-resources \
              --mount type=bind,src=/root/.exegol/exegol-resources,dst=/opt/resources \
              --mount type=bind,src=./workspace,dst=/workspace \
              ${nix-pentest.imageName} \
	      /bin/bash /bin/entrypoint.sh endless
	fi
	if sudo docker ps --filter "name=$CTR_NAME" --filter "status=running" --format '{{.Names}}' | grep -qx "$CTR_NAME"; then
              echo "[-] Container already started"
          else
              echo "[+] Starting the container..."
              sudo docker start "$CTR_NAME"
          fi
          echo "🚀 Exec-ing inside the container..."
          sudo docker exec -e SHELL=/bin/zsh -ti "$CTR_NAME" zsh -i
      '';
    in {
      # The default app: nix run . → launches container with mount
      apps.${system}.default = {
        type = "app";
        program = "${runScript}/bin/run-my-container";
      };

      # Optional: buildable Docker image with nix build
      packages.${system}.default = nix-pentest;

      # Optional: nix develop gives access to run script
      devShells.${system}.default = pkgs.mkShell {
        packages = [ runScript ];
      };
    };
}

