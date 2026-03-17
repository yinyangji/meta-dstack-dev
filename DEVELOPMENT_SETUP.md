# Dstack 开发环境搭建指南

本文档介绍在**无 TDX 硬件**或**宿主机开发模式**下，使用 Simulator 完整运行 dstack 的流程与注意事项。

---

## 一、模式说明

| 模式 | 适用场景 | Gateway 位置 | 证书来源 | KMS 配置 |
|------|----------|--------------|----------|----------|
| **Simulator / 宿主机** | 无 TDX 硬件、本地开发 | 宿主机 | debug key | `sign_cert_skip_quote_verification = true` |
| **真实 TDX 生产** | 有 TDX 硬件、生产部署 | CVM 内 | guest agent | `sign_cert_skip_quote_verification = false` |

---

## 二、Simulator 模式完整流程

### 2.1 前置准备

```bash
# 依赖（以 Ubuntu 24.04 为例）
sudo apt install -y build-essential wireguard-tools

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 2.2 初始化构建

```bash
cd meta-dstack
mkdir -p build && cd build

# 首次运行会生成 build-config.sh，按提示编辑后再次执行
../build.sh hostcfg
```

### 2.3 关键配置（build-config.sh）

Simulator 模式下必须配置以下变量：

```bash
# 宿主机模式：debug_key.json 路径（用于 Gateway RPC 证书生成）
# 留空则视为 Gateway 在 CVM 内，使用 guest agent
GATEWAY_DEBUG_KEY_FILE=/path/to/meta-dstack/dstack/debug_key.json

# Simulator 模式：KMS 跳过 Intel quote 校验（否则 SignCert 失败）
KMS_SIGN_CERT_SKIP_QUOTE_VERIFICATION=true
```

其他常用配置：

```bash
KMS_DOMAIN=kms.example.com
GATEWAY_DOMAIN=gateway.example.com
GATEWAY_PUBLIC_DOMAIN=example.com

# Certbot（如需 HTTPS）
CERTBOT_ENABLED=true
CF_API_TOKEN=<your-token>
ACME_URL=https://acme-staging-v02.api.letsencrypt.org/directory
```

### 2.4 生成 debug_key.json（必须）

**步骤 1：启动 Simulator**

```bash
cd dstack/sdk/simulator
./build.sh && ./dstack-simulator
```

保持运行，新开终端。

**步骤 2：生成 debug key**

```bash
cd dstack
cargo run -p dstack-gateway --bin gen_debug_key -- unix:$(realpath sdk/simulator/dstack.sock)
```

生成的 `debug_key.json` 位于 `dstack/` 目录。

**步骤 3：确认 build-config.sh 中的路径**

确保 `GATEWAY_DEBUG_KEY_FILE` 指向实际的 `debug_key.json` 路径，例如：

```
GATEWAY_DEBUG_KEY_FILE=/home/youruser/meta-dstack/dstack/debug_key.json
```

### 2.5 重新生成配置

修改 `build-config.sh` 后需重新生成配置：

```bash
cd build
../build.sh cfg
```

### 2.6 启动顺序

> **说明**：生成 `debug_key.json` 后，日常启动 KMS + Gateway 时**无需**再运行 Simulator。Simulator 仅在生成 debug key 时需要。

在 `build/` 目录下，**按顺序**在三个终端中启动：

```bash
# 终端 1：KMS
./dstack-kms -c kms.toml

# 终端 2：Gateway（需 sudo 用于 WireGuard）
sudo ./dstack-gateway -c gateway.toml

# 终端 3：VMM（如需启动 CVM）
./dstack-vmm -c vmm.toml
```

成功后 Gateway 日志可见证书生成完成，WireGuard 接口就绪。

---

## 三、常见问题与注意事项

### 3.1 "No such file or directory" 启动 Gateway 时

**原因**：Gateway 尝试使用 guest agent（`/var/run/dstack.sock`），但该 socket 仅存在于 CVM 内，宿主机上不存在。

**处理**：配置 debug key 模式：

1. 在 `build-config.sh` 中设置 `GATEWAY_DEBUG_KEY_FILE`
2. 执行 `../build.sh cfg` 重新生成 gateway.toml

### 3.2 "Quote verification failed: ISV enclave report signature is invalid"

**原因**：KMS 对 Simulator 生成的 quote 进行 Intel 校验失败。

**处理**：

1. 确认 `build-config.sh` 中 `KMS_SIGN_CERT_SKIP_QUOTE_VERIFICATION=true`
2. 执行 `../build.sh cfg` 重新生成 kms.toml
3. **重启 KMS** 以加载新配置
4. 若仍失败：确认使用的是**最新构建的 KMS**（修改过 `sign_cert_skip_quote_verification` 逻辑后需重新编译）

### 3.3 修改 KMS 代码后仍报 Quote 错误

**原因**：`build/` 下的 `dstack-kms` 可能是旧二进制。

**处理**：

```bash
# 1. 停止 KMS（Ctrl+C）

# 2. 重新编译并替换
cd meta-dstack/dstack
cargo build --release -p dstack-kms

# 3. 复制到 build 目录
cp target/release/dstack-kms ../build/dstack-kms

# 4. 重启 KMS
cd ../build && ./dstack-kms -c kms.toml
```

### 3.4 如何判断 Gateway 是否在 TD 内运行

| 启动日志 | 含义 |
|----------|------|
| `Using dstack guest agent for certificate generation` | 在 CVM 内，使用 guest agent |
| `Loading debug key data from: ...` | 在宿主机，使用 debug key |

配置上：

- `gateway.toml` 中 `run_in_dstack = false` → 宿主机模式
- `insecure_skip_attestation = true` 且有 `key_file` → 宿主机 debug 模式

### 3.5 build.sh 命令一览

| 命令 | 说明 |
|------|------|
| `../build.sh host` | 仅编译宿主机二进制 |
| `../build.sh cfg` | 仅生成配置文件 |
| `../build.sh hostcfg` | 编译 + 生成配置 |
| `../build.sh dl 0.5.5` | 下载 guest 镜像 |

---

## 四、配置示例

### Simulator 模式（build-config.sh 片段）

```bash
# 宿主机 + Simulator
GATEWAY_DEBUG_KEY_FILE=/home/youruser/meta-dstack/dstack/debug_key.json
KMS_SIGN_CERT_SKIP_QUOTE_VERIFICATION=true

# Certbot 可选
CERTBOT_ENABLED=true
CF_API_TOKEN=<token>
```

### 真实 TDX 模式（生产环境）

```bash
# Gateway 在 CVM 内，使用 guest agent
GATEWAY_DEBUG_KEY_FILE=

# 真实 quote 需 Intel 校验
KMS_SIGN_CERT_SKIP_QUOTE_VERIFICATION=false
```

---

## 五、文件结构速查

```
meta-dstack/
├── build/
│   ├── build-config.sh     # 主要配置，修改后运行 ../build.sh cfg
│   ├── kms.toml            # KMS 配置（由 cfg 生成）
│   ├── gateway.toml        # Gateway 配置（由 cfg 生成）
│   ├── vmm.toml            # VMM 配置
│   ├── dstack-kms          # KMS 二进制
│   ├── dstack-gateway      # Gateway 二进制
│   └── dstack-vmm          # VMM 二进制
├── dstack/
│   ├── debug_key.json      # gen_debug_key 生成，宿主机模式必需
│   └── sdk/simulator/      # Simulator 源码
└── DEVELOPMENT_SETUP.md    # 本文档
```

---

## 六、相关文档

- [Simulator 使用说明](simulator_readme.md) - Simulator 与 debug key 详细说明
- [dstack 部署文档](dstack/docs/deployment.md) - 生产环境部署
- [安全最佳实践](dstack/docs/security/security-best-practices.md)
