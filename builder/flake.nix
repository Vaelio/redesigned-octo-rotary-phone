{
  description = "Docker image with runtime mounts via nix run";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
    manspiderPkg.url = "github:vaelio/manspider-flake";
    asrepcatcherPkg.url = "github:vaelio/ASRepCatcher-flake";
  };

  outputs = { self, nixpkgs, manspiderPkg, asrepcatcherPkg }:
    let
      system = "x86_64-linux";
      manspider = manspiderPkg.packages.${system}.default;
      asrepcatcher = asrepcatcherPkg.packages.${system}.default;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      useExtra = builtins.getEnv "IMPORT_FMD" == "1";
      #kaliImage = pkgs.dockerTools.pullImage {
      #  imageName = "kalilinux/kali-rolling";
      #  imageDigest = "sha256:c21cb4b884932cf7dcc732efb20b88ea650475591c55c17d51af4bcd45859b18";
      #  finalImageName = "kali";
      #  finalImageTag = "latest";
      #  hash = "sha256-2u7LK434S/INRe5zApAkHmQTKqcxYZkVXTEGGonzmo4=";
      #};
      extraLayer = with pkgs; [
        (pkgs.symlinkJoin {
          name = "extra-layer";
          paths = lib.optional (useExtra) [ ./fmd.nix ];
        })
      ];
      linux-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "linux-tools";
          paths = [ coreutils-full lsd zsh bash oh-my-zsh fzf zellij curl wget nano vim git iconv tmux zsh-z zsh-autosuggestions zsh-completions zsh-syntax-highlighting python312 findutils gash-utils procps nix cacert su python312Packages.ipython unixtools.script less iproute2 unixtools.netstat bottom htop gnugrep ];
        })
      ];
      web-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "web-tools";
          paths = [ feroxbuster seclists ffuf sslscan nuclei soapui sqlmap subfinder testssl wafw00f waybackurls wfuzz whatweb whois wpscan];
        })
      ];
      android = with pkgs; [
        (pkgs.symlinkJoin {
          name = "android";
          paths = [ android-tools ];
        })
      ];
      ctr-tools = with pkgs.dockerTools; [
        (pkgs.symlinkJoin {
          name = "ctr-tools";
          paths = [ usrBinEnv binSh caCertificates fakeNss ];
        })
      ];
      ad-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "ad-tools";
          paths = [ netexec smbclient-ng samdump2 nbtscan openldap pretender onesixtyone sccmhunter krb5 responder mitm6 python312Packages.impacket python312Packages.lsassy bloodhound bloodhound-py neo4j python312Packages.ldapdomaindump python313Packages.certipy ldeep manspider asrepcatcher legba mariadb masscan metasploit mitmproxy netdiscover exploitdb sshuttle swaks freerdp smbmap enum4linux enum4linux-ng];
        })
      ];
      network-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "network-tools";
          paths = [ nmap proxychains-ng netcat socat simple-http-server wireshark openssh proxmark3 rdesktop rsync tcpdump tshark traceroute wifite2 ];
        })
      ];
      pwn-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "pwn-tools";
          paths = [ gdb gef nasm ropgadget python312Packages.ropper pwntool cutter rocmPackages.llvm.clang ];
        })
      ];
      nix-pentest = pkgs.dockerTools.buildLayeredImage {
        name = "nix-pentest-ctr";
        tag = "latest";
	#fromImage = kaliImage;
	#fromImageName = null;
	#fromImageTag = "latest";
        config = {
          Cmd = [ "${pkgs.bash}/bin/bash" ]; # Runs bash interactively
          User = "root";
          WorkingDir = "/workspace";
          Env = [ "HOME=/root" "ZSH_THEME=gentoo" "USER=root" "NIXPKGS_ALLOW_UNFREE=1" ];
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
          extraLayer
        ];
        maxLayers = 10;
	      created = "now";
        extraCommands = ''
          	        mkdir -p ./tmp
          	      '';
      };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      packages.${system}.default = nix-pentest;

    };
}

