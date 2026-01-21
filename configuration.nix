# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "amdgpu" ];

  # --- 电源策略：彻底禁止休眠与睡眠 (修正版) ---

  # 1. 禁用 Systemd 的睡眠目标 (保持不变，这是最核心的)
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # 2. 配置 Logind 行为
  services.logind = {
    # 移除所有旧的顶级选项 (如 lidSwitch)，避免 "renamed" 警告
    # 所有的配置现在都放进 settings.Login 下面
    settings = {
      Login = {
        # 对应 logind.conf 中的 [Login] 部分
        
        # 物理按键行为
        HandlePowerKey = "poweroff";
        HandleSuspendKey = "ignore";
        HandleHibernateKey = "ignore";
        
        # 合盖行为 (替代之前的 services.logind.lidSwitch)
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        
        # 闲置行为
        IdleAction = "ignore";
        IdleActionSec = "0";
      };
    };
  };
  
  # --- 解决动态链接库问题 (Fix "Could not start dynamically linked executable") ---
  programs.nix-ld.enable = true;

  # 配置 Copilot 和其他 VSCode 插件可能需要的库
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib  # 包含 libstdc++ (C++ 标准库)
    zlib              # 压缩库
    glib              # 基础库
    openssl           # 加密库
    icu               # Unicode 支持
  ];

  # ... existing config ...
  systemd.services.easytier = {
    description = "EasyTier Network Service";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      # 指向你的配置文件路径
      ExecStart = "${pkgs.easytier}/bin/easytier-core -d --network-name mike_net --network-secret mikepass -p tcp://public.easytier.top:11010";
      Restart = "always";
      User = "root";
    };
  };

  systemd.services.zellij-web = {
    description = "Zellij Web (user hongtou)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.zellij}/bin/zellij web --port 8081";
      Restart = "always";
      User = "hongtou";
    };
  };

  systemd.services.socat-forward = {
    description = "Socat port forward 8082->127.0.0.1:8081 (user hongtou)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:8082,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:8081";
      Restart = "always";
      User = "hongtou";
    };
  };
  

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" "https://cache.nixos.org/" ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = false;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true; # enforce Wayland session for GDM
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  # (X server disabled because using Wayland)

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support for libinput (works with Wayland)
  services.libinput.enable = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.hongtou = {
    isNormalUser = true;
    description = "hongtou";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
    openssh.authorizedKeys.keys = [
      # 在这里粘贴你的公钥字符串 (id_ed25519.pub 的内容)
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAufQNMpMEpuNAtV6YLgK/5y7hIu/dQU16H52/rPUCvXSufnVIkfP66a07/lH37BpQa+0NEpHnTSrATkXUm7yE+9XWcsUzRnWp48fKeC7AmfI3ObZcAucz/p/87moJh/bW/UxH5h8EFWaYJirM93VqBCf+XpkDd9P1tt4QVMyrYmQHEsNtg1QpKStyjLpDNoowG/9EPA2EJdusf8vBCiFn6XzxKJfModfDt7ObSFhcZrc8XYlknuaddlMPycOHS6URm8ciYlXzYcfRkjT+QTEFKTZazYAFSDF53OXikaPlRdhhXfdXIS5XyD1EI/9Sg/EHtRyIWZjocD4DnRC20B0hANaFcs+5/Qwt2mH6Gb5zsHNPbHlKO0M0bh7HMPpxr9BZEn8cObn19/SnSuJCejuBuSnRxuw6q2xPtlqr8k6EhTDBzChtTgHxkdcOerCMxVZXN7qKVNeneW1dBAwnfu6lVOLqaBOazQ43NDytlYLt5x5rCtXWMeXwVKgnHFSJr1D5Jui48/odEleAXFzeYZCf3+E0ejnCQxRbprarsuxJsW8drcB8+gk1X6Wrjn4RXR/lxU8fQSSI0LeJWtEbWh4x8fhgAjoosS+t4Gnsdt6XA1pyvGiAQbauto42GrzGN1Q7tc/S8KM6ORyl60FyQstJefXpfopQNzoPdyVnGHrP4w== ccteym@gmail.com" 
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gcc       # 包含 gcc 和 g++
    gnumake   # make 命令 (通常编译都需要)
    cmake     # 可选：如果你需要 cmake
    git
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    zellij
    socat
    easytier
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 8082 11010 ];
  networking.firewall.allowedUDPPorts = [ 11010 ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
