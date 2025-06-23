{
  description = "Docker image with runtime mounts via nix run";
  inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/25.05";
      home-manager = {
        url = "github:nix-community/home-manager/release-25.05";
	inputs.nixpkgs.follows = "nixpkgs";
      };
  };

  outputs = { self, nixpkgs, home-manager }: 
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
        inherit system;
	config.allowUnfree = true;
      };
      hm = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
        ];
        extraSpecialArgs = {};
      };
      linux-tools = with pkgs; [ coreutils-full lsd zsh bash oh-my-zsh fzf zellij curl wget nano vim git iconv tmux zsh-z zsh-autosuggestions zsh-completions zsh-syntax-highlighting python312 findutils gash-utils procps nix home-manager];
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
	  hm.activationPackage
	];
      };

    in {

      packages.${system}.default = nix-pentest;

    };
}

