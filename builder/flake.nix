{
  description = "Docker image with runtime mounts via nix run";
  inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/25.05";
      ffuf.url = "./ffuf";
  };

  outputs = { self, nixpkgs, ffuf}:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
        inherit system;
	config.allowUnfree = true;
      };
      ffufpkg = ffuf.packages.${system}.ffuf;
      linux-tools = with pkgs; [ (pkgs.symlinkJoin {
        name = "linux-tools";
	paths = [ coreutils-full lsd zsh bash oh-my-zsh fzf zellij curl wget nano vim git iconv tmux zsh-z zsh-autosuggestions zsh-completions zsh-syntax-highlighting python312 findutils gash-utils procps nix cacert su python312Packages.ipython unixtools.script less ];
      })];
      web-tools = with pkgs; [ (pkgs.symlinkJoin {
        name = "web-tools";
	paths = [ feroxbuster seclists ffufpkg];
      })];
      android = with pkgs; [ (pkgs.symlinkJoin {
        name = "android";
	paths = [ android-tools ];
      })];
      ctr-tools = with pkgs.dockerTools; [ (pkgs.symlinkJoin {
        name = "ctr-tools";
	paths = [ usrBinEnv binSh caCertificates fakeNss ];
      })];
      ad-tools = with pkgs; [ (pkgs.symlinkJoin {
        name = "ad-tools";
	paths = [ netexec smbclient-ng samdump2 nbtscan openldap pretender onesixtyone sccmhunter krb5 responder mitm6 python312Packages.impacket python312Packages.lsassy bloodhound bloodhound-py neo4j python312Packages.ldapdomaindump python313Packages.certipy ldeep ];
      })];
      network-tools = with pkgs; [ (pkgs.symlinkJoin { 
        name = "network-tools";
	paths = [ nmap proxychains-ng netcat socat simple-http-server wireshark openssh];
      })];
      pwn-tools = with pkgs; [ (pkgs.symlinkJoin {
        name = "pwn-tools";
	paths = [ gdb gef nasm ropgadget python312Packages.ropper pwntool cutter rocmPackages.llvm.clang ];
      })];
      nix-pentest = pkgs.dockerTools.buildLayeredImage {
        name = "nix-pentest-ctr";
        tag = "latest";
        config = {
          Cmd = [ "${pkgs.bash}/bin/bash" ]; # Runs bash interactively
	  User = "root";
	  WorkingDir = "/workspace";
	  Env = [ "HOME=/root" "ZSH_THEME=gentoo" "USER=root" "NIXPKGS_ALLOW_UNFREE=1"];
        };
	contents = with pkgs; [
	  ./fs
	  android
	  ctr-tools
	  linux-tools
	  ad-tools
	  network-tools
	  web-tools
	  shadow
	];
	maxLayers = 10;
	extraCommands = ''
	  mkdir -p ./tmp
	'';
      };
    in {

      packages.${system}.default = nix-pentest;

    };
}

