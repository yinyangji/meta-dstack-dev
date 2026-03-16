# DNS domain of kms rpc and dstack-gateway rpc
# *.1022.dstack.org resolves to 10.0.2.2 which is the IP of the host system
# from CVMs point of view
KMS_DOMAIN=kms.1022.dstack.org
GATEWAY_DOMAIN=gateway.1022.dstack.org

# CIDs allocated to VMs start from this number of type unsigned int32
VMM_CID_POOL_START=648000
# CID pool size
VMM_CID_POOL_SIZE=1000

VMM_RPC_LISTEN_PORT=11630
# Whether port mapping from host to CVM is allowed
VMM_PORT_MAPPING_ENABLED=true
# Host API configuration, type of uint32
VMM_VSOCK_LISTEN_PORT=11630
# Whether to enable GPU support
VMM_ENABLE_GPU=true

KMS_RPC_LISTEN_PORT=11631
GATEWAY_RPC_LISTEN_PORT=11632

GATEWAY_WG_INTERFACE=dgw-root123
GATEWAY_WG_LISTEN_PORT=11633
GATEWAY_WG_IP=10.114.3.1
GATEWAY_SERVE_PORT=11634
GATEWAY_CERT=/home/root123/pro/meta-dstack/build/run/certbot/live/cert.pem
GATEWAY_KEY=/home/root123/pro/meta-dstack/build/run/certbot/live/key.pem

BIND_PUBLIC_IP=0.0.0.0

GATEWAY_PUBLIC_DOMAIN=1022.dstack.org

# For gateway on host (run_in_dstack=false): path to debug key for RPC cert generation.
# 留空则在 CVM 内运行 gateway 时使用 guest agent 生成证书（真实 TDX 推荐）
# Host 模式需: 1) 启动 simulator  2) gen_debug_key  3) 设置路径
GATEWAY_DEBUG_KEY_FILE=

# for certbot
CERTBOT_ENABLED=true
CF_API_TOKEN=HuLrnUVuO7Bmi3r15ZkOPtmnX-ex3VS90P--5Uz9
ACME_URL=https://acme-staging-v02.api.letsencrypt.org/directory
