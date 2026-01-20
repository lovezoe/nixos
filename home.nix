{ config, pkgs, ... }:

{
  home.username = "hongtou";
  home.homeDirectory = "/home/hongtou";

  home.file.".ssh/authorized_keys".text = ''
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAufQNMpMEpuNAtV6YLgK/5y7hIu/dQU16H52/rPUCvXSufnVIkfP66a07/lH37BpQa+0NEpHnTSrATkXUm7yE+9XWcsUzRnWp48fKeC7AmfI3ObZcAucz/p/87moJh/bW/UxH5h8EFWaYJirM93VqBCf+XpkDd9P1tt4QVMyrYmQHEsNtg1QpKStyjLpDNoowG/9EPA2EJdusf8vBCiFn6XzxKJfModfDt7ObSFhcZrc8XYlknuaddlMPycOHS6URm8ciYlXzYcfRkjT+QTEFKTZazYAFSDF53OXikaPlRdhhXfdXIS5XyD1EI/9Sg/EHtRyIWZjocD4DnRC20B0hANaFcs+5/Qwt2mH6Gb5zsHNPbHlKO0M0bh7HMPpxr9BZEn8cObn19/SnSuJCejuBuSnRxuw6q2xPtlqr8k6EhTDBzChtTgHxkdcOerCMxVZXN7qKVNeneW1dBAwnfu6lVOLqaBOazQ43NDytlYLt5x5rCtXWMeXwVKgnHFSJr1D5Jui48/odEleAXFzeYZCf3+E0ejnCQxRbprarsuxJsW8drcB8+gk1X6Wrjn4RXR/lxU8fQSSI0LeJWtEbWh4x8fhgAjoosS+t4Gnsdt6XA1pyvGiAQbauto42GrzGN1Q7tc/S8KM6ORyl60FyQstJefXpfopQNzoPdyVnGHrP4w== ccteym@gmail.com
  '';

  # 你可以在这里安装只属于当前用户的软件
  home.packages = with pkgs; [
    fastfetch   # 漂亮的系统信息展示
    htop        # 进程查看器
    flclash
    zellij
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
    '';
  };

  # Home Manager 版本状态
  home.stateVersion = "24.11"; # 请保持此版本号或更新
}
