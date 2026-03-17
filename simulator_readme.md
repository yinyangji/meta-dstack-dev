# Dstack Simulator

TEE 模拟器，用于在无 TDX 硬件的环境下进行本地开发和测试。

## 构建与启动

```bash
# 构建 simulator
./build.sh

# 启动 simulator（会创建 dstack.sock、tappd.sock 等 Unix socket）
./dstack-simulator
```

Simulator 启动后会在当前目录创建以下 socket 文件：
- `dstack.sock` - 当前 TEE 服务接口 (v0.5+)
- `tappd.sock` - 旧版 TEE 服务接口 (v0.3)
- `external.sock`
- `guest.sock`

## 生成 Debug Key（Gateway 宿主机模式）

当 Gateway 在**宿主机**运行（非 CVM 内）时，需要通过 simulator 生成 debug key 才能完成 RPC 证书生成。

### 步骤

**1. 启动 simulator**

```bash
cd dstack/sdk/simulator
./build.sh && ./dstack-simulator
```

保持 simulator 在后台运行，新开一个终端。

**2. 生成 debug_key.json**

```bash
cd dstack

# 使用本地 simulator（Unix socket）
cargo run -p dstack-gateway --bin gen_debug_key -- unix:$(realpath sdk/simulator/dstack.sock)
```

生成的文件 `debug_key.json` 会出现在 `dstack/` 目录下。

**3. 配置 gateway.toml**

在 `gateway.toml` 中添加或确认：

```toml
[core.debug]
insecure_skip_attestation = true
key_file = "/path/to/dstack/debug_key.json"
```

或通过 `build-config.sh` 设置 `GATEWAY_DEBUG_KEY_FILE`，然后执行 `../build.sh hostcfg` 重新生成配置。

**4. 配置 KMS（Simulator 模式下必须）**

Simulator 生成的 quote 无法通过 Intel 校验，需在 `kms.toml` 中启用跳过：

```toml
[core]
sign_cert_skip_quote_verification = true
```

或在 `build-config.sh` 中设置 `KMS_SIGN_CERT_SKIP_QUOTE_VERIFICATION=true`，执行 `./build.sh cfg` 重新生成 kms.toml。

### simulator_url 说明

`gen_debug_key` 需要一个 simulator URL 参数，用于连接 TEE 服务获取 quote：

| 类型 | 格式 | 示例 |
|------|------|------|
| 本地 simulator | `unix:<socket_path>` | `unix:/path/to/dstack/sdk/simulator/dstack.sock` |
| 远程 TDX Lab | `https://<host>:<port>` | `https://xxx.tdxlab.dstack.org:12004` |

### 使用远程 simulator

若有 Phala TDX Lab 等远程 simulator 服务，可直接使用其 URL：

```bash
cargo run -p dstack-gateway --bin gen_debug_key -- https://<instance-id>-<port>.tdxlab.dstack.org:12004
```

## 验证

启动 simulator 后，可检查 socket 是否创建：

```bash
ls -la *.sock
```

设置环境变量后，SDK 会自动使用 simulator：

```bash
export DSTACK_SIMULATOR_ENDPOINT=$(realpath dstack.sock)
```
