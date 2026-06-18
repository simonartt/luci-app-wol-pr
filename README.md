# luci-app-wol-pro - 局域网唤醒插件 (iStoreOS)
注意:这是一个vibe coding项目
一个现代化的 iStoreOS 局域网唤醒插件，支持设备记忆、图块化展示和一键唤醒。

## 功能特性

- 🖥️ **设备记忆**：保存常用设备的 MAC 地址、IP、广播地址等信息
- 🧱 **图块展示**：以卡片/图块形式直观展示所有已保存设备
- ⚡ **一键唤醒**：点击设备图块即可发送 Magic Packet
- 🔍 **在线检测**：通过 ARP 表自动检测设备在线状态
- ✏️ **设备管理**：支持添加、编辑、删除设备
- 📝 **备注功能**：可为每个设备添加自定义备注

## 目录结构

```
luci-app-wol-pro/
├── Makefile                      # OpenWRT 编译规则
├── istore_meta.json              # iStore 软件中心元数据
├── luasrc/
│   ├── controller/
│   │   └── wol-pro.lua           # LuCI 控制器 & API 路由
│   ├── model/cbi/
│   │   └── config.lua            # CBI 配置界面（可选）
│   └── view/wol-pro/
│       └── index.htm             # 主界面（图块式 UI）
├── root/
│   ├── etc/config/
│   │   └── wol-pro               # UCI 默认配置
│   └── usr/libexec/istoree/
│       └── wol-pro.sh            # iStore 状态脚本
└── src/                          # 预留（二进制工具等）
```

## 编译方法

### 1. 准备 OpenWRT/iStoreOS 编译环境

```bash
# 克隆 iStoreOS 源码
git clone https://github.com/istoreos/istoreos.git
cd istoreos

# 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a
```

### 2. 放入插件源码

将 `luci-app-wol-pro` 目录复制到 OpenWRT 源码的 `package/` 目录下：

```bash
cp -r luci-app-wol-pro /path/to/istoreos/package/
```

### 3. 编译

```bash
# 配置编译选项
make menuconfig
# 在 LuCI -> Applications 中勾选 luci-app-wol-pro

# 编译插件
make package/luci-app-wol-pro/compile V=s
```

编译成功后，`.ipk` 文件将生成在：
```
bin/packages/<目标架构>/base/luci-app-wol-pro_1.0.0-1_all.ipk
```

## 安装方法

### 方式一：iStore 软件中心

1. 将 `istore_meta.json` 和 `.ipk` 文件打包
2. 通过 iStore 软件中心上传安装

### 方式二：命令行安装

```bash
# 上传 .ipk 到路由器
scp luci-app-wol-pro_1.0.0-1_all.ipk root@192.168.1.1:/tmp/

# 安装
ssh root@192.168.1.1
opkg install /tmp/luci-app-wol-pro_1.0.0-1_all.ipk
```

## 使用说明

1. 安装后，在 LuCI 管理界面 → **服务** → **Wake-on-LAN Pro**
2. 点击「添加设备」填写：
   - 设备名称（如：书房电脑）
   - MAC 地址（格式：AA:BB:CC:DD:EE:FF）
   - IP 地址（可选）
   - 广播地址（默认 255.255.255.255）
   - 网络接口（默认 br-lan）
   - 备注信息
3. 点击图块上的 ⚡ 按钮即可唤醒设备

## UCI 配置示例

```
config device 'my_pc'
    option name '书房电脑'
    option mac 'AA:BB:CC:DD:EE:FF'
    option ipaddr '192.168.1.100'
    option broadcast '255.255.255.255'
    option iface 'br-lan'
    option notes '台式机，支持 WOL'
```

## 依赖

- `etherwake`：发送 Magic Packet 的工具
- `luci-compat`：LuCI 兼容层

## 许可

Apache License 2.0
