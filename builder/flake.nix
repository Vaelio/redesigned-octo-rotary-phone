{
  description = "Docker image with runtime mounts via nix run";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/unstable";
    manspiderPkg.url = "github:vaelio/manspider-flake";
    asrepcatcherPkg.url = "github:vaelio/ASRepCatcher-flake";
    pylapsPkg.url = "github:vaelio/pylaps-flake";
  };

  outputs = { self, nixpkgs, manspiderPkg, asrepcatcherPkg, pylapsPkg }:
    let
      system = "x86_64-linux";
      manspider = manspiderPkg.packages.${system}.default;
      asrepcatcher = asrepcatcherPkg.packages.${system}.default;
      pylaps = pylapsPkg.packages.${system}.default;
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
          paths = [ coreutils-full lsd zsh bash oh-my-zsh fzf zellij curl wget nano vim git iconv tmux zsh-z zsh-autosuggestions zsh-completions zsh-syntax-highlighting python312 findutils procps nix cacert su python312Packages.ipython unixtools.script less iproute2 unixtools.netstat bottom htop gnugrep gawkInteractive gnused ncurses unixtools.xxd ];
        })
      ];
      web-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "web-tools";
          paths = [ feroxbuster seclists ffuf sslscan nuclei soapui sqlmap subfinder testssl wafw00f waybackurls wfuzz whatweb whois wpscan arjun assetfinder dirb dirsearch dnsenum dnsx gau gobuster hakrawler hping httprobe httpx joomscan jwt-cli katana ngrok scout testssl ];
        })
      ];
      generic-tools = with pkgs; [
        (pkgs.symlinjJoin {
          name = "generic-tools";
          paths = [ exiftool dex2jar fcrackzip gron hashcat hexedit john ligolo-ng pdfcrack ];
        })
      ];
      cloud-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "cloud-tools";
          paths = [ awscli2 azure-cli kubectl ];
        })
      ];
      android = with pkgs; [
        (pkgs.symlinkJoin {
          name = "android";
          paths = [ android-tools anew apksigner apktool frida-tools ];
        })
      ];
      ctr-tools = with pkgs.dockerTools; [
        (pkgs.symlinkJoin {
          name = "ctr-tools";
          paths = [ usrBinEnv binSh caCertificates fakeNss ];
        })
      ];
      code-tools = with pkgs.dockerTools; [
        (pkgs.symlinkJoin {
          name = "code-tools";
          paths = [ semgrep gitleaks trufflehog ];
        })
      ];
      ad-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "ad-tools";
          paths = [ netexec smbclient-ng samdump2 nbtscan openldap pretender onesixtyone sccmhunter krb5 responder mitm6 python312Packages.impacket python312Packages.lsassy bloodhound bloodhound-py neo4j python312Packages.ldapdomaindump python312Packages.certipy ldeep manspider asrepcatcher legba mariadb masscan metasploit mitmproxy netdiscover exploitdb sshuttle swaks freerdp smbmap enum4linux enum4linux-ng pylaps python312Packages.pypykatz krbjack libmspack polenum coercer donpapi certsync keepwn pre2k python312Packages.masky python312Packages.pywerview autobloody python312Packages.dploot amass bettercap cewl eyewitness gotwitness ];
        })
      ];
      network-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "network-tools";
          paths = [ nmap proxychains-ng netcat socat simple-http-server wireshark openssh proxmark3 rdesktop rsync tcpdump tshark traceroute wifite2 aircrack-ng chisel tigervnc ];
        })
      ];
      pwn-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "pwn-tools";
          paths = [ gdb gef nasm ropgadget python312Packages.ropper pwntools cutter rocmPackages.llvm.clang binwalk checksec ];
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
          code-tools
          linux-tools
          ad-tools
          network-tools
          generic-tools
          web-tools
          cloud-tools
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

