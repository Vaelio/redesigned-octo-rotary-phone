{
  description = "Docker image with runtime mounts via nix run";
  inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/25.05";
      #rustyproxy = {
      #  url = "gitlab:r2367/RustyProxy";
      #};
  };

  outputs = { self, nixpkgs}: #, rustyproxy
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
        inherit system;
	config.allowUnfree = true;
      };
      linux-tools = with pkgs; [ coreutils-full lsd zsh bash oh-my-zsh fzf zellij curl wget nano vim git iconv tmux zsh-z zsh-autosuggestions zsh-completions zsh-syntax-highlighting python312 findutils gash-utils procps nix cacert su];
      ctr-tools = with pkgs.dockerTools; [ usrBinEnv binSh caCertificates fakeNss];
      ad-tools = with pkgs; [ netexec smbclient-ng samdump2 nbtscan openldap pretender onesixtyone sccmhunter krb5 responder mitm6 python312Packages.impacket python312Packages.lsassy bloodhound bloodhound-py neo4j python312Packages.ldapdomaindump];
      network-tools = with pkgs; [ nmap proxychains netcat socat simple-http-server ];
      pwn-tools = with pkgs; [ gdb gef nasm ropgadget python312Packages.ropper pwntools cutter rocmPackages.llvm.clang ];
      nix-pentest = pkgs.dockerTools.buildLayeredImage {
        name = "nix-pentest-ctr";
        tag = "latest";
        config = {
          Cmd = [ "${pkgs.bash}/bin/bash" ]; # Runs bash interactively
	  User = "root";
	  WorkingDir = "/workspace";
	  Env = [ "HOME=/root" "ZSH_THEME=gentoo" "USER=root"];
        };
	contents = with pkgs; [
	  ./scripts
	  ctr-tools
	  linux-tools
	  ad-tools
	  network-tools
	  shadow
	];
      };

    in {

      packages.${system}.default = nix-pentest;

    };
}

