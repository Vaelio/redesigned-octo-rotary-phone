{
  description = "Docker image with runtime mounts via nix run";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
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
      extraLayer = with pkgs; [
        (pkgs.symlinkJoin {
          name = "extra-layer";
          paths = lib.optional (useExtra) [ ./fmd.nix ];
        })
      ];
      linux-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "linux-tools";
          paths = [ coreutils-full lsd zsh bash oh-my-zsh fzf zellij curl wget nano vim git iconv tmux zsh-z zsh-autosuggestions zsh-completions zsh-syntax-highlighting python312 findutils procps nix cacert su python312Packages.ipython unixtools.script less iproute2 unixtools.netstat bottom htop gnugrep gawkInteractive gnused ncurses unixtools.xxd cachix nix-search-cli];
        })
      ];
      web-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "web-tools";
          paths = [ feroxbuster seclists ffuf sslscan nuclei soapui sqlmap subfinder testssl wafw00f waybackurls wfuzz whatweb whois wpscan arjun assetfinder dirb python312Packages.dirsearch dnsenum dnsx gau gobuster hakrawler hping httprobe httpx joomscan jwt-cli katana ngrok scout testssl ];
        })
      ];
      generic-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "generic-tools";
          paths = [ exiftool dex2jar fcrackzip gron hashcat hexedit john ligolo-ng pdfcrack ];
        })
      ];
      cloud-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "cloud-tools";
          paths = [ awscli2 azure-cli kubectl k9s];
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
      code-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "code-tools";
          paths = [ semgrep gitleaks trufflehog ];
        })
      ];
      ad-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "ad-tools";
          paths = [ netexec smbclient-ng samdump2 nbtscan openldap pretender onesixtyone sccmhunter krb5 responder mitm6 python312Packages.impacket python312Packages.lsassy bloodhound bloodhound-py neo4j python312Packages.ldapdomaindump python312Packages.certipy ldeep manspider asrepcatcher legba mariadb masscan metasploit mitmproxy netdiscover exploitdb sshuttle swaks freerdp smbmap enum4linux enum4linux-ng pylaps python312Packages.pypykatz krbjack libmspack polenum coercer donpapi certsync keepwn pre2k python312Packages.masky python312Packages.pywerview autobloody python312Packages.dploot amass bettercap cewl eyewitness gowitness ruler ];
        })
      ];
      network-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "network-tools";
          paths = [ nmap proxychains-ng netcat-gnu socat simple-http-server wireshark openssh proxmark3 rdesktop rsync tcpdump tshark traceroute wifite2 aircrack-ng chisel tigervnc openvpn];
        })
      ];
      pwn-tools = with pkgs; [
        (pkgs.symlinkJoin {
          name = "pwn-tools";
          paths = [ gdb gef nasm ropgadget python312Packages.ropper pwntools binutils cutter rocmPackages.llvm.clang binwalk checksec ];
        })
      ];
      extraLibs = with pkgs; [
        zlib
        zstd
        stdenv.cc.cc  # includes the libstdc++ runtime
        curl
        openssl
        attr
        libssh
        bzip2
        libxml2
        acl
        libsodium
        util-linux
        xz
        systemd
      
        # Steam hack: expose lib64 from steam-run’s FHS env
        (pkgs.runCommand "steamrun-lib" {} ''
          mkdir -p $out
          ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib
        '')
      ];
      nix-pentest = pkgs.dockerTools.buildLayeredImage {
        name = "nix-pentest-ctr";
        tag = "latest";
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
	  pwn-tools
          shadow
          extraLayer
        ];
        maxLayers = 10;
        created = "now";
        extraCommands = ''
          	        mkdir -p ./tmp
			mkdir -p ./lib
			#ln -s ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 ./lib/ld-linux-x86-64.so.2
          	      '';
        config = {
          Cmd = [ "${pkgs.zsh}/bin/zsh" ]; # Runs bash interactively
          User = "root";
          WorkingDir = "/workspace";
          Env = [ "HOME=/root" "ZSH_THEME=gentoo" "USER=root" "NIXPKGS_ALLOW_UNFREE=1" "NIX_LD=${pkgs.nix-ld}/bin/ld.so" "NIX_LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath extraLibs}" ];
        };
      };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      packages.${system}.default = nix-pentest;

    };
}

