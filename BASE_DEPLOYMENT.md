# Base 网络部署指南

> 本文档包含 Base Sepolia 测试网和 Base 主网的完整部署信息

---

## 📋 目录

1. [快速参考](#快速参考)
2. [部署前准备](#部署前准备)
3. [部署命令](#部署命令)
4. [测试网部署详情](#测试网部署详情)
5. [主网部署详情](#主网部署详情)
6. [网络配置](#网络配置)
7. [费用说明](#费用说明)

---

## 🚀 快速参考

### Base Sepolia 测试网

| 类别 | 合约 | 地址 | BaseScan |
|------|------|------|----------|
| **基础合约** | WETH | `0x4200000000000000000000000000000000000006` | [查看](https://sepolia.basescan.org/address/0x4200000000000000000000000000000000000006) |
| | UniswapV2Factory | `0x398Cb0460D5cb84a0cA2C3A71E15761d68B7c609` | [查看](https://sepolia.basescan.org/address/0x398Cb0460D5cb84a0cA2C3A71E15761d68B7c609) |
| | UniswapV2Router02 | `0xB032ab6808C8b4af5FA397E1181eAFD9ac1fd870` | [查看](https://sepolia.basescan.org/address/0xB032ab6808C8b4af5FA397E1181eAFD9ac1fd870) |
| **MEMOX 合约** | MemeFactory | `0x7E8db7526D7fd6519bDCB374f97Da698cF8b8a04` | [查看](https://sepolia.basescan.org/address/0x7E8db7526D7fd6519bDCB374f97Da698cF8b8a04) |
| | MemeHelper | `0x9d61CDea34373962f3627acad46651806Cd597D0` | [查看](https://sepolia.basescan.org/address/0x9d61CDea34373962f3627acad46651806Cd597D0) |
| | MemeCore (Proxy) | `0xCd7974a718F9BF3077827076535dAE52255617A2` | [查看](https://sepolia.basescan.org/address/0xCd7974a718F9BF3077827076535dAE52255617A2) |
| | MemeCore (Impl) | `0x93D346A1424a34568C721e04f527E93CAFde9519` | [查看](https://sepolia.basescan.org/address/0x93D346A1424a34568C721e04f527E93CAFde9519) |
| | MemeVesting (Proxy) | `0xb91775F2Fa02607851e05dE4cfC6317b722E4f53` | [查看](https://sepolia.basescan.org/address/0xb91775F2Fa02607851e05dE4cfC6317b722E4f53) |
| | MemeVesting (Impl) | `0xF192Eb40877549C82E8d9798E425F18b82097b7C` | [查看](https://sepolia.basescan.org/address/0xF192Eb40877549C82E8d9798E425F18b82097b7C) |

### Base 主网

| 类别 | 合约 | 地址 | BaseScan |
|------|------|------|----------|
| **基础合约** | WETH | `0x4200000000000000000000000000000000000006` | [查看](https://basescan.org/address/0x4200000000000000000000000000000000000006) |
| | Uniswap V2 Router | `0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24` | [查看](https://basescan.org/address/0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24) |
| **MEMOX 合约** | MemeFactory | `0xaB67852E714745dE1A22910aAeeF8844564d1599` | [查看](https://basescan.org/address/0xaB67852E714745dE1A22910aAeeF8844564d1599) |
| | MemeHelper | `0x6d2a3a8335404834a31998d112852Cf720A1D986` | [查看](https://basescan.org/address/0x6d2a3a8335404834a31998d112852Cf720A1D986) |
| | MemeCore (Proxy) | `0xAd60714bb32F9870750a12ee061d0f5b3F19abD5` | [查看](https://basescan.org/address/0xAd60714bb32F9870750a12ee061d0f5b3F19abD5) |
| | MemeCore (Impl) | `0xCa75D9aD93Ec3038A00a101CC5d07055901481e1` | [查看](https://basescan.org/address/0xCa75D9aD93Ec3038A00a101CC5d07055901481e1) |
| | MemeVesting (Proxy) | `0xbdB49D6C141ec77c1190D023f5E7B6553F35044e` | [查看](https://basescan.org/address/0xbdB49D6C141ec77c1190D023f5E7B6553F35044e) |
| | MemeVesting (Impl) | `0x783CfcE696C05DA3Fcdb51dD9340e84B690aEeea` | [查看](https://basescan.org/address/0x783CfcE696C05DA3Fcdb51dD9340e84B690aEeea) |

---

## 🔑 部署前准备

### 1. 获取 BaseScan API Key

访问 https://basescan.org/myapikey 注册并获取 API Key

### 2. 设置环境变量

创建 `.env` 文件：

```bash
# 私钥（不要提交到 Git！）
PRIVATE_KEY=你的私钥

# RPC 地址
BASE_SEPOLIA_RPC=https://sepolia.base.org
BASE_MAIN_RPC=https://mainnet.base.org

# 区块浏览器 API Key
BASESCAN_API_KEY=你的 BaseScan API Key
```

### 3. 获取测试 ETH

| 平台 | 网址 |
|------|------|
| Base 官方 Faucet | https://faucet.base.org/ |
| Alchemy Faucet | https://www.alchemy.com/faucets/base-sepolia |
| Chainlink Faucet | https://faucets.chain.link/base-sepolia |

### 4. 配置部署文件

#### `deploy-config/base_sepolia/dev.json`（测试网）

```json
{
  "Admin": "0x 你的管理员地址",
  "Signer": "0x 你的签名者地址",
  "PlatformFeeReceiver": "0x 你的费用接收地址",
  "MarginReceiver": "0x 你的保证金接收地址",
  "GraduateFeeReceiver": "0x 你的毕业费接收地址",
  "Router": "0xB032ab6808C8b4af5FA397E1181eAFD9ac1fd870",
  "WETH": "0x4200000000000000000000000000000000000006",
  "MinLockTime": 86400
}
```

#### `deploy-config/base/prod.json`（主网）

```json
{
  "Admin": "0x 你的管理员地址",
  "Signer": "0x 你的签名者地址",
  "PlatformFeeReceiver": "0x 你的费用接收地址",
  "MarginReceiver": "0x 你的保证金接收地址",
  "GraduateFeeReceiver": "0x 你的毕业费接收地址",
  "Router": "0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24",
  "WETH": "0x4200000000000000000000000000000000000006",
  "MinLockTime": 86400
}
```

---

## 🚀 部署命令

### 测试网部署

```bash
# 1. 加载环境变量
source .env

# 2. 修改 script/Deploy.s.sol：
#    projectName = "base_sepolia/";
#    environment = "dev";

# 3. 执行部署
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url $BASE_SEPOLIA_RPC \
    --broadcast \
    --verify \
    --etherscan-api-key $BASESCAN_API_KEY \
    --verifier-url "https://api.etherscan.io/v2/api?chainid=84532" \
    --legacy \
    --slow
```

### 主网部署

```bash
# 1. 加载环境变量
source .env

# 2. 修改 script/Deploy.s.sol：
#    projectName = "base/";
#    environment = "prod";

# 3. 执行部署
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url $BASE_MAIN_RPC \
    --broadcast \
    --verify \
    --etherscan-api-key $BASESCAN_API_KEY \
    --verifier-url "https://api.etherscan.io/v2/api?chainid=8453" \
    --legacy \
    --slow
```

---

## 📊 测试网部署详情

### Base Sepolia 网络信息

| 项目 | 值 |
|------|-----|
| **网络名称** | Base Sepolia |
| **Chain ID** | 84532 |
| **RPC URL** | https://sepolia.base.org |
| **区块浏览器** | https://sepolia.basescan.org |
| **Gas 代币** | ETH (测试币) |

### 已部署合约

| 合约 | 地址 | BaseScan |
|------|------|----------|
| **UniswapV2Factory** | `0x398Cb0460D5cb84a0cA2C3A71E15761d68B7c609` | [查看](https://sepolia.basescan.org/address/0x398Cb0460D5cb84a0cA2C3A71E15761d68B7c609) |
| **UniswapV2Router02** | `0xB032ab6808C8b4af5FA397E1181eAFD9ac1fd870` | [查看](https://sepolia.basescan.org/address/0xB032ab6808C8b4af5FA397E1181eAFD9ac1fd870) |
| **MemeFactory** | `0x7E8db7526D7fd6519bDCB374f97Da698cF8b8a04` | [查看](https://sepolia.basescan.org/address/0x7E8db7526D7fd6519bDCB374f97Da698cF8b8a04) |
| **MemeHelper** | `0x9d61CDea34373962f3627acad46651806Cd597D0` | [查看](https://sepolia.basescan.org/address/0x9d61CDea34373962f3627acad46651806Cd597D0) |
| **MemeCore (Proxy)** | `0xCd7974a718F9BF3077827076535dAE52255617A2` | [查看](https://sepolia.basescan.org/address/0xCd7974a718F9BF3077827076535dAE52255617A2) |
| **MemeCore (Impl)** | `0x93D346A1424a34568C721e04f527E93CAFde9519` | [查看](https://sepolia.basescan.org/address/0x93D346A1424a34568C721e04f527E93CAFde9519) |
| **MemeVesting (Proxy)** | `0xb91775F2Fa02607851e05dE4cfC6317b722E4f53` | [查看](https://sepolia.basescan.org/address/0xb91775F2Fa02607851e05dE4cfC6317b722E4f53) |
| **MemeVesting (Impl)** | `0xF192Eb40877549C82E8d9798E425F18b82097b7C` | [查看](https://sepolia.basescan.org/address/0xF192Eb40877549C82E8d9798E425F18b82097b7C) |

---

## 📊 主网部署详情

### Base 主网网络信息

| 项目 | 值 |
|------|-----|
| **网络名称** | Base Mainnet |
| **Chain ID** | 8453 |
| **RPC URL** | https://mainnet.base.org |
| **区块浏览器** | https://basescan.org |
| **Gas 代币** | ETH (真实) |

### 已部署合约

| 合约 | 地址 | BaseScan |
|------|------|----------|
| **Uniswap V2 Router** | `0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24` | [查看](https://basescan.org/address/0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24) |
| **MemeFactory** | `0xaB67852E714745dE1A22910aAeeF8844564d1599` | [查看](https://basescan.org/address/0xaB67852E714745dE1A22910aAeeF8844564d1599) |
| **MemeHelper** | `0x6d2a3a8335404834a31998d112852Cf720A1D986` | [查看](https://basescan.org/address/0x6d2a3a8335404834a31998d112852Cf720A1D986) |
| **MemeCore (Proxy)** | `0xAd60714bb32F9870750a12ee061d0f5b3F19abD5` | [查看](https://basescan.org/address/0xAd60714bb32F9870750a12ee061d0f5b3F19abD5) |
| **MemeCore (Impl)** | `0xCa75D9aD93Ec3038A00a101CC5d07055901481e1` | [查看](https://basescan.org/address/0xCa75D9aD93Ec3038A00a101CC5d07055901481e1) |
| **MemeVesting (Proxy)** | `0xbdB49D6C141ec77c1190D023f5E7B6553F35044e` | [查看](https://basescan.org/address/0xbdB49D6C141ec77c1190D023f5E7B6553F35044e) |
| **MemeVesting (Impl)** | `0x783CfcE696C05DA3Fcdb51dD9340e84B690aEeea` | [查看](https://basescan.org/address/0x783CfcE696C05DA3Fcdb51dD9340e84B690aEeea) |

---

## 🌐 网络配置

### Foundry 配置 (`foundry.toml`)

```toml
[rpc_endpoints]
base_sepolia = "https://sepolia.base.org"
base = "https://mainnet.base.org"

[etherscan]
base_sepolia = { key = "${BASESCAN_API_KEY}", url = "https://api.etherscan.io/v2/api?chainid=84532", chain = 84532 }
base = { key = "${BASESCAN_API_KEY}", url = "https://api.etherscan.io/v2/api?chainid=8453", chain = 8453 }
```

### 网络对比

| 网络 | Chain ID | RPC URL | 区块浏览器 |
|------|----------|---------|-----------|
| **Base Sepolia** | 84532 | https://sepolia.base.org | https://sepolia.basescan.org |
| **Base 主网** | 8453 | https://mainnet.base.org | https://basescan.org |

---

## 💰 费用说明

### 测试网费用

| 操作 | Gas 消耗 | 费用 (ETH) | 费用 (USD) |
|------|----------|------------|------------|
| 完整部署 | ~14,680,000 | ~0.0003-0.001 | 免费（测试币） |
| 用户创建代币 | ~500,000 | ~0.00005 | 免费（测试币） |
| 用户买入/卖出 | ~150,000 | ~0.000015 | 免费（测试币） |

### 主网费用

| 操作 | Gas 消耗 | 费用 (ETH) | 费用 (USD)* |
|------|----------|------------|-------------|
| 完整部署 | ~14,680,000 | ~0.0003-0.001 | ~$1-3.5 |
| 用户创建代币 | ~500,000 | ~0.00005 | ~$0.18 |
| 用户买入/卖出 | ~150,000 | ~0.000015 | ~$0.05 |

*按 ETH = $3,500 计算，实际费用随 Gas 价格波动

---

## ⚠️ 注意事项

1. **Router 地址**：
   - 测试网：`0xB032ab6808C8b4af5FA397E1181eAFD9ac1fd870`（部署的 UniswapV2Router02）
   - 主网：`0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24`（Uniswap V2 Router）

2. **WETH 地址**：Base 测试网和主网使用相同的 WETH 地址 `0x4200000000000000000000000000000000000006`

3. **Gas 代币**：
   - 测试网：免费测试 ETH
   - 主网：真实 ETH（需要成本）

4. **验证器 URL**：使用 Etherscan API V2 端点
   - 测试网：`https://api.etherscan.io/v2/api?chainid=84532`
   - 主网：`https://api.etherscan.io/v2/api?chainid=8453`

5. **API Key**：需要在 https://basescan.org/myapikey 申请

---

## 🔗 有用链接

| 类别 | 名称 | 网址 |
|------|------|------|
| **官方** | Base 官方文档 | https://docs.base.org/ |
| | Base Bridge | https://bridge.base.org/ |
| **Faucet** | Base 官方 Faucet | https://faucet.base.org/ |
| | Alchemy Faucet | https://www.alchemy.com/faucets/base-sepolia |
| | Chainlink Faucet | https://faucets.chain.link/base-sepolia |
| **浏览器** | BaseScan 主网 | https://basescan.org/ |
| | BaseScan 测试网 | https://sepolia.basescan.org/ |
| | BaseScan API | https://basescan.org/myapikey |
| **DEX** | Uniswap V2 | https://app.uniswap.org/ |

---

## 📝 更新日志

| 日期 | 内容 |
|------|------|
| 2026-06-14 | Base 主网部署完成，更新合约地址 |
| 2026-06-14 | Base Sepolia 测试网部署完成 |
