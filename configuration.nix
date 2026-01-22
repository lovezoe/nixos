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

  # 1. 禁用 Systemd 的睡眠目标
  # 在 NixOS 中，将 enable 设为 false 会阻止生成这些 target 的关联，
  # 从而达到类似 mask 的效果 (无法被启动)。
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # 2. Logind 设置 (你之前已经改好的正确版本)
  services.logind = {
    settings = {
      Login = {
        HandlePowerKey = "poweroff";
        HandleSuspendKey = "ignore";
        HandleHibernateKey = "ignore";
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        IdleAction = "ignore";
        IdleActionSec = "0";
      };
    };
  };

  # 3. UPower 设置 (关键！解决 "The system will suspend now" 问题)
  # 那个通知是 UPower 发出的，必须在这里按住它的手。
  services.upower = {
    enable = true;
    
    # 当 UPower 认为电量危急时 (Critical)，执行什么动作？
    # 默认是 HybridSleep 或 PowerOff，我们改成 Ignore (忽略)。
    allowRiskyCriticalPowerAction = true;
    criticalPowerAction = "Ignore";

    # 将所有触发阈值调到最低，防止误判
    percentageLow = 0;
    percentageCritical = 0;
    percentageAction = 0;
    
    # 也可以选择按时间触发的阈值调零
    timeLow = 0;
    timeCritical = 0;
    timeAction = 0;
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
  services.easytier = {
    enable = true;
    instances = {
      default = {
        enable = true;
        settings = {
          network_name = "mike_net";
          network_secret = "mikepass";
          instance_name = "default";
          dhcp = true;
          peers = [ "tcp://public.easytier.top:11010" ];
        };
      };
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
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  networking.interfaces.enp6s0.wakeOnLan.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.inputMethod.type = "fcitx5";

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

  # --- 启用 Flatpak 服务模块 ---
  # 这会自动配置 systemd 服务、Polkit 策略和 D-Bus
  services.flatpak.enable = true;

  # --- 🟡 Niri/Wayland 用户必填：XDG Portal ---
  # Flatpak 强依赖 XDG Portal 来穿透沙盒与系统交互（打开文件、链接等）
  # 之前的配置可能没加这个，会导致 Flatpak 应用无法启动或无法安装
  xdg.portal = {
    enable = true;
    # 安装 GTK portal 作为通用后端 (对非 GNOME/KDE 环境兼容性最好)
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    
    # 告诉 Portal 系统，对于所有桌面环境，默认使用 GTK 实现
    config.common.default = [ "gtk" ];
  };

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
    flatpak
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
  networking.firewall.allowedTCPPorts = [ 22 8082 11010 11011 ];
  networking.firewall.allowedUDPPorts = [ 11010 11011 ];
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
