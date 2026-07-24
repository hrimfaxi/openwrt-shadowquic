# ShadowQUIC OpenWrt Package

A 0-RTT QUIC proxy with SNI camouflage — UDP friendly, full cone NAT support, and user management.

本仓库是 OpenWrt 的 package feed，用于在 OpenWrt SDK 中编译 shadowquic。

## 前提条件

- OpenWrt SDK（已 `./scripts/feeds update -a && ./scripts/feeds install -a`）
- 目标设备对应的 toolchain 已编译或已下载预编译版本
- Rust 工具链（SDK 中需安装 `rust` 和 `cargo`，或通过 feed 安装）

## 编译步骤

### 1. 克隆到 package 目录

在 OpenWrt SDK 根目录下，将本仓库克隆到 `package/` 目录：

```bash
cd openwrt-sdk-*
git clone https://github.com/hrimfaxi/openwrt-shadowquic.git package/shadowquic
```

如果使用本地仓库：

```bash
ln -s /path/to/openwrt-shadowquic package/shadowquic
```

### 2. 选择包

```bash
make menuconfig
```

进入 `Network` -> 勾选 `shadowquic` 为 `M`（模块）或 `*`（内置）。

### 3. 编译

```bash
# 仅编译本包
make package/shadowquic/compile V=s

# 或编译整个固件（会一并打包）
make -j$(nproc) V=s
```

编译产物位于 `bin/targets/<target>/<subtarget>/` 或 `build_dir/` 下。

## 支持的架构

Makefile 自动识别目标架构并选择对应的 Rust target triple：

| OpenWrt ARCH | Rust Target |
|---|---|
| aarch64 | `aarch64-unknown-linux-musl` |
| x86_64 | `x86_64-unknown-linux-musl` |
| mips | `mips-unknown-linux-musl` |
| mipsel | `mipsel-unknown-linux-musl` |
| arm (v7) | `armv7-unknown-linux-musleabihf` |
| arm | `arm-unknown-linux-musleabi` |

其他架构会回退到 `<arch>-unknown-linux-musl`。

## 安装到设备

编译完成后，将生成的 `.ipk` 文件传到 OpenWrt 设备上安装：

```bash
scp bin/packages/*/shadowquic/*.ipk root@<router>:/tmp/
ssh root@<router> "opkg install /tmp/shadowquic_*.ipk"
```

## 包含的文件

安装后会在设备上部署：

- `/usr/bin/shadowquic` — 主程序
- `/etc/config/shadowquic` — UCI 配置
- `/etc/init.d/shadowquic` — procd 启动脚本（含 ujail 沙箱加固）
- `/etc/capabilities/shadowquic.json` — 权限声明（CAP_NET_ADMIN）

## ujail 沙箱

当 OpenWrt 系统中存在 `/sbin/ujail` 且 capabilities 文件就绪时，服务会自动启用 ujail 沙箱：

- **ronly** — 根文件系统只读挂载
- **requirejail** — ujail 不可用时直接拒绝启动，不会静默回退到无沙箱的 root 模式
- **log** — 保留日志通道（`/dev/log` 等可写）
- **nobody** — 以 nobody 用户运行，禁用新特权（`no_new_privs`）
- 仅挂载配置文件和 `/etc/resolv.conf`、`/etc/hosts`、`/etc/TZ` 为只读

## 配置

配置文件位于 `/etc/config/shadowquic`，使用 UCI 格式。每个实例需要指定一个 YAML 配置文件路径。

```bash
# 启用/禁用实例
uci set shadowquic.@instance[0].enabled='1'
uci commit shadowquic

# 重启服务
/etc/init.d/shadowquic restart
```

## 许可证

MIT
