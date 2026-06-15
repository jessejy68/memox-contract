# MEMOX - Base 去中心化代币发射平台

## 📋 概述

MEMOX 是一个部署在 Base 网络上的去中心化代币发射平台，支持：

- ✅ 公平启动代币创建
- ✅ 联合曲线定价机制
- ✅ 自动添加到 DEX 流动性
- ✅ 线性归属（Linear Vesting）功能
- ✅ 预购（Initial Buy）功能

## 🔗 Base 主网合约地址

| 合约 | 地址 | BaseScan |
|------|------|----------|
| **MemeCoreProxy** | `0xCd7974a718F9BF3077827076535dAE52255617A2` | [查看](https://basescan.org/address/0xCd7974a718F9BF3077827076535dAE52255617A2) |
| **MemeCoreImpl** | `0x93D346A1424a34568C721e04f527E93CAFde9519` | [查看](https://basescan.org/address/0x93D346A1424a34568C721e04f527E93CAFde9519) |
| **MemeVestingProxy** | `0xb91775F2Fa02607851e05dE4cfC6317b722E4f53` | [查看](https://basescan.org/address/0xb91775F2Fa02607851e05dE4cfC6317b722E4f53) |
| **MemeVestingImpl** | `0xF192Eb40877549C82E8d9798E425F18b82097b7C` | [查看](https://basescan.org/address/0xF192Eb40877549C82E8d9798E425F18b82097b7C) |
| **MemeFactory** | `0x7E8db7526D7fd6519bDCB374f97Da698cF8b8a04` | [查看](https://basescan.org/address/0x7E8db7526D7fd6519bDCB374f97Da698cF8b8a04) |
| **MemeHelper** | `0x9d61CDea34373962f3627acad46651806Cd597D0` | [查看](https://basescan.org/address/0x9d61CDea34373962f3627acad46651806Cd597D0) |

## 🔗 Base Sepolia 测试网合约地址

| 合约 | 地址 | BaseScan |
|------|------|----------|
| **MemeCoreProxy** | `0x33d84F8F5E7Ea1105Dd8a52d7B1Ceb48b43221C5` | [查看](https://sepolia.basescan.org/address/0x33d84F8F5E7Ea1105Dd8a52d7B1Ceb48b43221C5) |
| **MemeCoreImpl** | `0xB29F30C9a5d18B4E6A89198894B23cF06eCEdCad` | [查看](https://sepolia.basescan.org/address/0xB29F30C9a5d18B4E6A89198894B23cF06eCEdCad) |
| **MemeVestingProxy** | `0x96257F2bc8BC9E7c374eAb73766a5aA31fe80734` | [查看](https://sepolia.basescan.org/address/0x96257F2bc8BC9E7c374eAb73766a5aA31fe80734) |
| **MemeVestingImpl** | `0x395F4fcA2cA8E7C4bc3eb00b170e1a641ccaEDd8` | [查看](https://sepolia.basescan.org/address/0x395F4fcA2cA8E7C4bc3eb00b170e1a641ccaEDd8) |
| **MemeFactory** | `0xB7795c90A2747C30FCE30564e8E879D2166A93a1` | [查看](https://sepolia.basescan.org/address/0xB7795c90A2747C30FCE30564e8E879D2166A93a1) |
| **MemeHelper** | `0xF0021d9d51580dFA3994Fcf013ca38D8720A87c4` | [查看](https://sepolia.basescan.org/address/0xF0021d9d51580dFA3994Fcf013ca38D8720A87c4) |

### 基础合约

| 网络 | 合约 | 地址 | 说明 |
|------|------|------|------|
| **主网** | WETH | `0x4200000000000000000000000000000000000006` | Base 主网 Wrapped ETH |
| **主网** | Uniswap V2 Router | `0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24` | DEX 路由合约 |
| **测试网** | WETH | `0x4200000000000000000000000000000000000006` | Base Sepolia Wrapped ETH |
| **测试网** | UniswapV2Router02 | `0xB032ab6808C8b4af5FA397E1181eAFD9ac1fd870` | 部署的 DEX 路由合约 |

---

## 📖 启动脚本

详细的部署和使用指南请参阅：[启动脚本](./START.md)

完整的 Base 网络部署文档请参阅：[BASE_DEPLOYMENT.md](./BASE_DEPLOYMENT.md)

---

## 🏗️ 架构

### 系统组件

```
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│    MemeCore      │─────▶│   MemeVesting    │◀─────│     User         │
│  (代币创建)       │      │  (线性释放)      │      │    (领取)        │
└──────────────────┘      └──────────────────┘      └──────────────────┘
         │                         │
         ▼                         ▼
┌──────────────────┐      ┌──────────────────┐
│   MemeToken      │      │ 归属时间表        │
│   (ERC20)        │      │   管理           │
└──────────────────┘      └──────────────────┘
```

### 合约集成

- **MemeCore**: 核心业务逻辑，支持代币创建、买卖、归属分配
- **MemeVesting**: 可升级合约，管理代币锁仓释放
- **MemeFactory**: 使用 CREATE2 部署代币合约
- **MemeHelper**: 联合曲线计算和 DEX 交互

---

## 🚀 功能特性

### 1. 线性归属（Linear Vesting）

用户可以将初始代币购买分成多个部分，每个部分都有自己的归属期限：

- 没有最短或最长时间限制
- 每个时间表从开始到结束时间线性释放代币
- 每次代币创建支持任意数量的归属时间表

**归属计算：**
```
已归属金额 = (总金额 × 经过的时间) / 总持续时间
可领取金额 = 已归属金额 - 已领取金额
```

### 2. 预购功能（Initial Buy）

支持代币正式交易前的预购阶段：

- 可设置预购时间窗口
- 预购金额有上限和下限
- 预购失败可退款

### 3. 联合曲线定价

- 基于恒定乘积公式 `k = x × y`
- 价格随买卖自动调整
- 毕业时自动添加流动性到 DEX

---

## 📝 使用方法

### 创建带有归属的代币

```solidity
IMemeCore.VestingAllocation[] memory vestingAllocations = new IMemeCore.VestingAllocation[](3);

// 30% 归属期 1 天
vestingAllocations[0] = IMemeCore.VestingAllocation({
    amount: 3000,      // 30% (基点)
    duration: 86400    // 1 天 (秒)
});

// 50% 归属期 1 周
vestingAllocations[1] = IMemeCore.VestingAllocation({
    amount: 5000,      // 50%
    duration: 604800   // 1 周
});

// 20% 立即释放（剩余部分）
IMemeCore.CreateTokenParams memory params = IMemeCore.CreateTokenParams({
    // ... 其他参数 ...
    initialBuyPercentage: 1000,  // 10% 初始购买
    vestingAllocations: vestingAllocations
});

// 调用创建代币
core.createToken(params);
```

### 领取已归属代币

```solidity
// 从特定时间表领取
uint256 claimed = vesting.claim(tokenAddress, scheduleId);

// 领取所有可用代币
uint256 totalClaimed = vesting.claimAll(tokenAddress);

// 领取前查询可领取金额
uint256 claimable = vesting.getClaimableAmount(tokenAddress, beneficiary, scheduleId);
```

### 查询归属信息

```solidity
// 获取总归属信息
(uint256 vested, uint256 claimed, uint256 locked) = vesting.getTotalVestedAmount(
    tokenAddress, 
    beneficiary
);

// 获取特定时间表详情
IMemeVesting.VestingSchedule memory schedule = vesting.getVestingSchedule(
    tokenAddress,
    beneficiary,
    scheduleId
);

// 获取时间表数量
uint256 count = vesting.getVestingScheduleCount(tokenAddress, beneficiary);
```

---

## 🔒 安全特性

### 访问控制

| 角色 | 权限 |
|------|------|
| **ADMIN_ROLE** | 撤销时间表、紧急提款、升级合约 |
| **OPERATOR_ROLE** | 创建归属时间表（授予 MemeCore） |
| **CORE_ROLE** | 调用 Helper 合约（授予 MemeCore） |
| **DEPLOYER_ROLE** | 部署代币（授予 MemeCore） |
| **SIGNER_ROLE** | 签名验证（授予签名者） |

### 安全机制

- **ReentrancyGuard**: 防止重入攻击
- **SafeERC20**: 安全的代币转移操作
- **UUPS Upgradeable**: 可升级合约模式
- **AccessControl**: 细粒度权限控制

---

## 🎯 示例场景

### 场景 1：团队代币归属

项目创建者购买 10% 的代币并进行归属：
- 40% 分 6 个月归属给团队
- 30% 分 1 年归属给顾问
- 30% 立即释放用于提供流动性

### 场景 2：反抛售保护

创建者将 100% 的初始购买代币在 30 天内归属，防止立即抛售并展示长期承诺。

### 场景 3：基于里程碑的释放

多个归属时间表与项目里程碑保持一致：
- 25% 在 1 个月后释放 (MVP)
- 25% 在 3 个月后释放 (Beta)
- 50% 在 6 个月后释放 (全面发布)

---

## 💰 Gas 优化

### 高效存储

- 使用映射实现 O(1) 访问归属时间表
- 跟踪总金额以避免迭代
- 领取期间最小化存储更新

### 批量操作

- 单笔交易中创建多个归属时间表
- 一次调用领取所有可用代币
- 降低用户的 Gas 成本

### Base 主网费用参考

| 操作 | Gas 消耗 | 费用 (USD)* |
|------|----------|-------------|
| 创建代币 | ~500,000 | ~$0.18 |
| 买入/卖出 | ~150,000 | ~$0.05 |
| 领取归属代币 | ~100,000 | ~$0.03 |

*按 ETH = $3,500，Gas = 0.05 gwei 计算

---

## 📊 事件

系统发出的主要事件：

```solidity
// 归属时间表创建
event VestingScheduleCreated(
    address indexed token,
    address indexed beneficiary,
    uint256 scheduleId,
    uint256 amount,
    uint256 startTime,
    uint256 endTime
);

// 代币领取
event TokensClaimed(
    address indexed token,
    address indexed beneficiary,
    uint256 scheduleId,
    uint256 amount
);

// 归属创建（MemeCore 中）
event VestingCreated(
    address indexed token,
    address indexed beneficiary,
    uint256 totalVestedAmount,
    uint256 scheduleCount
);

// 代币部署
event TokenDeployed(
    address indexed token,
    string name,
    string symbol,
    uint256 totalSupply,
    address indexed deployer
);
```

---

## 🧪 测试

运行测试：

```bash
# 运行所有测试
forge test

# 运行归属功能测试
forge test --match-contract VestingTest -vvv

# 运行费用计算测试
forge test --match-contract ComprehensiveFeeTest -vvv

# 生成 Gas 报告
forge test --gas-report
```

---

## 📦 部署

### 部署到 Base 主网

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

详细部署指南请参阅：[BASE_DEPLOYMENT.md](./BASE_DEPLOYMENT.md)

---

## 🔗 有用链接

| 类别 | 名称 | 网址 |
|------|------|------|
| **官方** | Base 官方文档 | https://docs.base.org/ |
| | Base Bridge | https://bridge.base.org/ |
| **浏览器** | BaseScan | https://basescan.org/ |
| | BaseScan API | https://basescan.org/myapikey |
| **DEX** | Uniswap | https://app.uniswap.org/ |

---

## 📄 许可证

MIT License
