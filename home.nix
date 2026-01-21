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
  programs.git.enable = true;
  programs.git.settings.user.name = "mike";
  programs.git.settings.user.email = "ccteym@gmail.com";

  # 配置 Bash 或 Zsh
  programs.bash = {
    enable = true;
    enableCompletion = true;
    # 在这里为 mise 设置 hook，让它自动生效
    initExtra = ''
      rebuild() {
        flake="/home/hongtou/.nixos-config"
        echo "Running dry-run check..."
        sudo nixos-rebuild switch --flake "$flake" --show-trace --dry-run || { echo "Dry-run failed, aborting"; return 1; }
        echo "Dry-run passed. Building..."
        sudo nixos-rebuild build --flake "$flake" || { echo "Build failed, aborting"; return 1; }
        echo "Build succeeded. Switching..."
        sudo nixos-rebuild switch --flake "$flake" || { echo "Switch failed"; return 1; }
        echo "Rebuild complete."
      }
    '';
  };

  # Home Manager 版本状态
  home.stateVersion = "24.11"; # 请保持此版本号或更新
}
