{ config, pkgs, ... }:

{
  home.username = "hongtou";
  home.homeDirectory = "/home/hongtou";

  # 你可以在这里安装只属于当前用户的软件
  home.packages = with pkgs; [
    python312
    nodejs_24
    jq
    fastfetch   # 漂亮的系统信息展示
    htop        # 进程查看器
    flclash
    httpie
  ];

  # 配置 Git (示例)
  programs.git = {
    enable = true;
    userName = "hongtou";
    userEmail = "your-email@example.com";
  };

  # 配置 Bash 或 Zsh
  programs.bash = {
    enable = true;
    enableCompletion = true;
    # 在这里为 mise 设置 hook，让它自动生效
    initExtra = ''
      eval "$(${pkgs.mise}/bin/mise activate bash)"
      alias rebuild="sudo nixos-rebuild switch --flake /home/hongtou/.nixos-config"
    '';
  };

  # Home Manager 版本状态
  home.stateVersion = "24.11"; # 请保持此版本号或更新
}
