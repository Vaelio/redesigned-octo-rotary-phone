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

    # fonts

    # rust
    
    # keyboard stuff

    # nix stuff

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
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=#626262";
    #ZSH_HIGHLIGHT_STYLES\[comment\] = "fg=#888888";
    TERM = "xterm-256color";
    HISTFILESIZE=1000000000;
    HISTSIZE=1000000000;
    ZSH_THEME="gentoo";
    HISTTIMEFORMAT="[%F %T] ";
    #TIME_="%{$fg[white]%}[%{$fg[red]%}%D{%b %d, %Y - %T (%Z)}%{$fg[white]%}]%{$reset_color%}";
    #PROMPT="$LOGGING$TIME_%{$FX[bold]$FG[013]%} $EXEGOL_HOSTNAME %{$fg_bold[blue]%}%(!.%1~.%c) $(prompt_char)%{$reset_color%} ";
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
  programs.starship.enable = true;
  programs.nushell.enable = true;
  programs.starship.enableNushellIntegration = true;
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "gentoo";
      plugins = [ "docker" "docker-compose" "zsh-syntax-highlighting" "zsh-completions" "zsh-autosuggestions" "tmux" "fzf" "zsh-z" "zsh-nvm" "asdf" ];
    };
  };

}
