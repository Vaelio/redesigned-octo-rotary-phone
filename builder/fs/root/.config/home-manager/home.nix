{ config, pkgs, lib, ... }:

rec {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "root";
  home.homeDirectory = "/root";

  imports = [
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.
  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };


  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [

    # Tools
    (pkgs.burpsuite.override { proEdition = true; })

    # python
    pkgs.python3
    pkgs.python312Packages.ipython

  ];


  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {

  };

  home.sessionVariables = {
    EDITOR = "vim";
    TERM = "xterm-256color";
    ZSH_THEME="gentoo";
    PATH = "$HOME/.nix-profile/bin:$PATH";
    SHELL="zsh";
  };

  # setup aliases
  home.shellAliases = {
    ls="lsd";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Enable bash and starship prompt
  programs.bash.enable = true;
  programs.zsh = {
    enable = true;
    envExtra = ''
      prompt_char () {
	if [ $UID -eq 0 ]
	then
		echo "#"
	else
		echo $
	fi
      }
    '';
    initContent = lib.mkOrder 1500 ''
      export PROMPT="$LOGGING$TIME_%{$FX[bold]$FG[013]%} $HOSTNAME %{$fg_bold[blue]%}%(!.%1~.%c) $(prompt_char)%{$reset_color%} "
      export HISTTIMEFORMAT="[%F %T] "
      export TIME_="%{$fg[white]%}[%{$fg[red]%}%D{%b %d, %Y - %T (%Z)}%{$fg[white]%}]%{$reset_color%}"
    '';
    history = {
      size = 100000000;
      save = 100000000;
      extended = true;
      append = true;
      findNoDups = true;
    };
    autosuggestion = {
      enable = true;
      highlight = "fg=#626262";
    };
    syntaxHighlighting = {
      enable = true;
      styles = {
        comment = "fg=#888888";
      };
    };
    oh-my-zsh = {
      enable = true;
      theme = "gentoo";
      plugins = [ "docker" "docker-compose" "tmux" "fzf" "asdf" ];
    };
  };

}
