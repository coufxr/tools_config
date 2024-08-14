# 在WSL2中安装ArchLinux

## 前置安装

用管理员打开powershell输入

### 1. 启用WSL

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

### 2. 启用虚拟平台

```powershell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

### 3. 下载Linux内核升级包  

> 下载地址：<https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi>

wsl更新至最新

```powershell
wsl.exe --update
```

### 4. 将WSL2设置为默认版本

```powershell
wsl --set-default-version 2
```

### 5. 安装默认Linux

```powershell
wsl.exe --install Ubuntu
```

配置相关设置

## 构建arch

### 1. 下载文件

```bash
wget https://mirrors.tuna.tsinghua.edu.cn/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.gz
```

### 2. 安装bsdtar

```bash
sudo apt-get update
sudo apt install libarchive-tools 
```

### 3. 解压

```bash
sudo bsdtar -xpvf archlinux-bootstrap-x86_64.tar.gz
```

命令解释:
> bsdtar：这是BSD版的tar工具，能够处理tar格式的归档文件。  
> -x：这个选项表示要解压缩（extract）档案文件。  
> -p：保留文件原有属性（permissions），包括所有者、用户组、文件权限等。  
> -v：详细模式（verbose），在解压过程中显示详细信息，如正在解压的文件名。  
> -f：指定要操作的归档文件名，这里是archlinux-bootstrap-x86_64.tar.gz。  

### 4. 打包

```bash
sudo bsdtar -cpvf archlinux-bootstrap.tar -C root.x86_64 .
```

命令解释:
> -c：创建一个新的归档文件（create）。  
> -p：保留文件原有属性（permissions），包括所有者、用户组、文件权限等。  
> -v：详细模式（verbose），在打包过程中显示详细信息，列出正在打包的文件。  
> -f：指定输出的归档文件名，这里是archlinux-bootstrap.tar。  
> -C： root.x86_64：改变至指定目录（change directory）进行打包操作，即先切换到名为root.x86_64的目录下，然后再对该目录及其内部的内容进行打包。  

使用文件管理器将 `*.tar` 文件移动到安装位置，如 `E:`盘根目录下

```bash
explorer.exe .
```

如何不在使用`Ubuntu`，可将其卸载`powershell`下执行

```powershell
wsl --unregister Ubuntu
```

然后在开始菜单中将其卸载，否则使用`wsl`时会默认安装

### 5. 导入

将 `ArchLinux` 安装到 `E:\wsl\ArchLinux` 下

```powershell
wsl --import ArchLinux E:\wsl\ArchLinux E:\archlinux-bootstrap.tar
```

## 配置ArchLinux

设置`ArchLinux`为 `wsl2`

```powershell
wsl --set-version ArchLinux 2
```

### 进入系统

```powershell
wsl -d ArchLinux
```

### 网络配置

删除网络连接配置

```bash
rm /etc/resolv.conf
```

重新启动`Archlinux`
> exit

然后再次进入`Archlinux`

### 换源

```bash
cd /etc/
explorer.exe .
```

文件管理器中找到 `pacman.conf`，在这个文件最后加入

```text
[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
```

然后进入下一级目录`pacman.d`  
编辑里面的`mirrolist`文件，将China的源注释去掉（选择部分即可）

### 安装包

问题:
> error: archlinuxcn-keyring: Signature from "Jiachen YANG (Arch Linux Packager Signing Key) " is marginal trust  
> <https://www.archlinuxcn.org/archlinuxcn-keyring-manually-trust-farseerfc-key/>

```bash
pacman -Syy
pacman-key --init
pacman-key --populate
pacman-key --lsign-key "farseerfc@archlinux.org"
pacman -S archlinuxcn-keyring
pacman -S base base-devel vim git wget
```

#### 其他推荐

建议安装:

- `paru` 基于 Yay 的新 AUR 助手: <https://github.com/Morganamilo/paru>
- `zsh`
- `eza` 现代的 `ls` 替代品: <https://github.com/eza-community/eza>
- `bat` 类似 cat，但带有 git 集成和语法高亮: <https://github.com/sharkdp/bat>

可选择:

- `bottom` 用于终端的可定制的跨平台图形化进程/系统监视器: <https://github.com/ClementTsang/bottom>
- `procs` 现代的 `ps` 替代品: <https://github.com/dalance/procs>
- `neofetch` 命令行系统信息工具: <https://github.com/dylanaraps/neofetch>
- `yazi` 极速终端文件管理器: <https://github.com/sxyazi/yazi>
 
终端美化:

- `starship` 轻量、迅速、客制化的高颜值终端: <https://starship.rs/zh-CN/>
- `sheldon` zsh插件管理器: <https://github.com/rossmacarthur/sheldon>

### 新建账户

给当前的root设置密码

```bash
passwd
```

然后新建一个普通用户

```bash
useradd -m -G wheel -s /bin/bash <用户名>
passwd <用户名>
```

#### 权限

打开文件 `sudoers`

```bash
vim /etc/sudoers
```

取消 `wheel ALL=(ALL) ALL`的注释

到此为止已经完成了`Archlinux`的配置

## 重要

`wsl` 会默认以`root`用户登录`Archlinux`，所以需要修改`Archlinux`的默认用户

需要在 `/etc/wsl.conf` 中添加以下内容:

```text
# Set the user when launching a distribution with WSL.
[user]
default = <用户名>
```

`wsl.conf` 的其他配置:
><https://learn.microsoft.com/zh-cn/windows/wsl/wsl-config>

### 其他

- arch_logo: <https://cdn0.iconfinder.com/data/icons/flat-round-system/512/archlinux-512.png>

- zi: <https://blog.maple3142.net/2020/09/27/zsh-customization/>
- zinit: <https://www.cnblogs.com/hongdada/p/16821715.html>

## 参考  
>
> <https://www.cnblogs.com/LunTsunami/p/18133726>  
> <https://zhuanlan.zhihu.com/p/266585727>  
