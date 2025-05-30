# Fishnet-StandardSystem
[English Version](#english-version)

## 项目概述
本仓库包含鱼网标准节点系统的NixOS配置文件。

## 快速开始
安装NixOS系统后将本仓库clone至NixOS配置目录：
```bash
cd /etc/nixos/
git clone https://github.com/Cynun/Fishnet-StandardSystem.git ./fishnet
```
随后在你的配置文件中引入`fishnet/default.nix`，根据需求修改配置即可。

## 更新
使用git。
```bash
git fetch origin & git merge origin/main
```

## 参考链接
- [NixOS 官方网站](https://nixos.org/)
- [NixOS Options & Packages 查询](https://search.nixos.org/)
- [WSL2 运行 NixOS 指南](https://nix-community.github.io/NixOS-WSL/install.html)
- [NixOS VSCode 远程开发支持](https://github.com/nix-community/nixos-vscode-server)

----
----

## English Version
### Fishnet Standard Node System

### Overview
This repository contains NixOS configuration files for the Fishnet Standard Node System.

### Quick Start
After installing NixOS, clone this repository to your NixOS configuration directory:
```bash
cd /etc/nixos/
git clone https://github.com/Cynun/Fishnet-StandardSystem.git ./fishnet
```
Then import `fishnet/default.nix` in your configuration file and edit the configuration as needed.

## Updating
Use git.
```bash
git fetch origin & git merge origin/main
```

### Reference Links
- [NixOS Official Website](https://nixos.org/)
- [NixOS Options & Packages Search](https://search.nixos.org/)
- [Running NixOS on WSL2](https://nix-community.github.io/NixOS-WSL/install.html)
- [NixOS VSCode Remote Development Support](https://github.com/nix-community/nixos-vscode-server)
