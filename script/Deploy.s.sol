// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DeployScript
 * @notice MEMOX 主部署脚本
 * @dev 部署和配置整个 MEME 发射平台的所有合约
 *
 * 部署顺序：
 * 1. MemeVesting - 归属合约（依赖 Core 地址）
 * 2. MemeCore - 核心合约（依赖 Factory、Helper）
 * 3. MemeHelper - 辅助合约（联合曲线计算、DEX 交互）
 * 4. MemeFactory - 工厂合约（CREATE2 部署代币）
 *
 * 配置步骤：
 * - Factory.setMeme(core) - 授权 Core 调用工厂
 * - Helper.grantRole(CORE_ROLE, core) - 授权 Core 调用辅助合约
 * - Core.setVesting(vesting) - 设置归属合约地址
 *
 * 使用方法：
 * 1. 配置 deploy-config/{chain}/{env}.json 文件
 * 2. 设置环境变量 PRIVATE_KEY
 * 3. 运行部署命令（见下方注释）
 */

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MemeCore} from "../src/MemeCore.sol";
import {MemeFactory} from "../src/MemeFactory.sol";
import {MemeHelper} from "../src/MemeHelper.sol";
import {MemeVesting} from "../src/MemeVesting.sol";
import {MemeToken} from "../src/MemeToken.sol";

import {Deployer} from "./Deployer.sol";
import {DeployConfig} from "./DeployConfig.s.sol";

contract DeployScript is Deployer {
    // ============ 配置和地址存储 ============
    DeployConfig public cfg;           // 部署配置
    address public MemeHelperAddr;     // Helper 合约地址
    address public MemeFactoryAddr;    // Factory 合约地址
    address public MemeCoreAddr;       // Core 代理合约地址

    /**
     * @notice 初始化部署环境
     * @dev 设置项目名称和环境，加载配置文件
     */
    function setUp() public override {
        // ===== 选择部署网络（取消注释对应行）=====
        // Base L2 测试网部署
//        projectName = "base_sepolia/";    // Base Sepolia 测试网
        projectName = "base/";           // Base 主网

        // ===== 选择部署环境 =====
//        environment = "dev";            // 开发环境
//        environment = "test";           // 测试环境
//        environment = "pre";            // 预发布环境
        environment = "prod";           // 生产环境

        super.setUp();

        // 加载配置文件
        string memory path = string.concat(
            vm.projectRoot(),
            "/deploy-config/",
            projectName,
            environment,
            ".json"
        );
        cfg = new DeployConfig(path);
    }

    // ==================== 部署命令示例 ====================
    // Base Sepolia 测试网部署：
    // forge script script/Deploy.s.sol:DeployScript --rpc-url $BASE_SEPOLIA_RPC --broadcast --verify --etherscan-api-key $BASESCAN_API_KEY --verifier basescan --legacy --slow

    // Base 主网部署：
    // forge script script/Deploy.s.sol:DeployScript --rpc-url $BASE_MAIN_RPC --broadcast --verify --etherscan-api-key $BASESCAN_API_KEY --verifier basescan --legacy --slow
    
    // Base 主网部署：
    // forge script script/Deploy.s.sol:DeployScript --rpc-url $BASE_MAIN_RPC --broadcast --legacy --slow

    /**
     * @notice 主部署入口函数
     * @dev 执行完整的部署流程
     */
    function run() external {
        // 从环境变量读取部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // 读取配置
        address admin = cfg.Admin();
        address signer = cfg.Signer();
        address platformFeeReceiver = cfg.PlatformFeeReceiver();
        


        // 打印部署信息
        console.log("Deploying MEMOX system...");
        console.log("Deployer:", deployer);
        console.log("Admin:", admin);
        console.log("Signer:", signer);
        console.log("Platform Fee Receiver:", platformFeeReceiver);
        console.log("-----------------------------------");
        
        // ===== 部署操作 =====
        vm.startBroadcast(deployerPrivateKey);
        deployMemeVesting();      // 部署 Vesting → Core → Factory/Helper
        vm.stopBroadcast();       // 等待部署确认

        // ===== 配置操作（独立广播上下文，确保部署已上链）=====
        // vm.startBroadcast(deployerPrivateKey);
        // setAll();                 // 配置所有合约
        // vm.stopBroadcast();

        // ===== 升级操作（可选）=====
        // vm.startBroadcast(deployerPrivateKey);
        // upgradeMemeCore();        // 升级核心合约
        // vm.stopBroadcast();

        // vm.startBroadcast(deployerPrivateKey);
        // upgradeMemeVesting();     // 升级归属合约
        // vm.stopBroadcast();
    }

    // ==================== 配置函数 ====================
    // 单独执行配置：
    // forge script script/Deploy.s.sol:DeployScript --sig "setAll()" --broadcast --rpc-url $SEPOLIA_TEST_RPC --verify --etherscan-api-key $ETH_API_KEY --verifier etherscan --legacy

    /**
     * @notice 配置所有合约
     * @dev 设置各合约间的权限和地址引用
     */
    function setAll() public {
        setMemeCore();
    }

    // ==================== 部署函数 ====================

    /**
     * @notice 部署 MemeHelper 辅助合约
     * @dev 提供联合曲线计算和 DEX 交互功能
     * @return addr_ 部署的合约地址
     */
    function deployMemeHelper() public returns (address addr_) {
        MemeHelper helper;
        if (cfg.MemeHelper() == address(0)) {
            // 新部署
            helper = new MemeHelper(cfg.Admin(), cfg.Router(), cfg.WETH());

            // 验证配置
            require(helper.PANCAKE_V2_ROUTER() == cfg.Router(), "Router set failed");
            require(helper.WETH() == cfg.WETH(), "WETH set failed");
            console.log("MemeHelper deployed at: %s", address(helper));
        } else {
            // 已部署，使用现有地址
            helper = MemeHelper(payable(address(cfg.MemeHelper())));
            console.log("MemeHelper already deployed at %s", address(helper));
        }
        save("MemeHelper", address(helper));
        addr_ = address(helper);
    }

    /**
     * @notice 部署 MemeFactory 工厂合约
     * @dev 使用 CREATE2 部署代币，支持地址预测
     * @return addr_ 部署的合约地址
     */
    function deployMemeFactory() public returns (address addr_) {
        MemeFactory factory;
        if (cfg.MemeFactory() == address(0)) {
            // 新部署
            factory = new MemeFactory(cfg.Admin());
            console.log("MemeFactory deployed at: %s", address(factory));
        } else {
            // 已部署，使用现有地址
            factory = MemeFactory(cfg.MemeFactory());
            console.log("MemeFactory already deployed at %s", address(factory));
        }
        save("MemeFactory", address(factory));
        addr_ = address(factory);
    }

    /**
     * @notice 部署 MemeCore 核心合约（使用 UUPS 代理）
     * @dev 核心业务逻辑：创建代币、买卖、毕业等
     * @return addr_ 代理合约地址
     */
    function deployMemeCore() public returns (address addr_) {
        MemeCore coreImpl;
        if (cfg.MemeCore() == address(0)) {
            // 1. 部署实现合约
            coreImpl = new MemeCore();
            save("MemeCoreImpl", address(coreImpl));
            console.log("MemeCoreImpl deployed at %s", address(coreImpl));
            
            // 2. 部署依赖合约
            address payable factory = payable(deployMemeFactory());
            address payable helper = payable(deployMemeHelper());
            
            // 3. 编码初始化数据
            bytes memory initData = abi.encodeWithSelector(
                MemeCore.initialize.selector,
                factory,                        // 工厂合约地址
                helper,                         // 辅助合约地址
                cfg.Signer(),                   // 签名者地址
                cfg.PlatformFeeReceiver(),      // 平台费用接收地址
                cfg.MarginReceiver(),           // 保证金接收地址
                cfg.GraduateFeeReceiver(),      // 毕业费用接收地址
                cfg.Admin()                     // 管理员地址
            );
            
            // 4. 部署代理合约
            ERC1967Proxy proxy = new ERC1967Proxy(address(coreImpl), initData);
            console.log("MemeCoreProxy deployed at:", address(proxy));

            // 5. 验证初始化配置
            MemeCore core = MemeCore(payable(address(proxy)));
            require(address(core.factory()) == factory, "factory set failed");
            require(address(core.helper()) == helper, "helper set failed");
            require(address(core.platformFeeReceiver()) == cfg.PlatformFeeReceiver(), "platformFeeReceiver set failed");
            require(address(core.marginReceiver()) == cfg.MarginReceiver(), "marginReceiver set failed");
            require(address(core.graduateFeeReceiver()) == cfg.GraduateFeeReceiver(), "GraduateFeeReceiver set failed");

            // 6. 验证常量配置
            require(core.REQUEST_EXPIRY() == 3600, "REQUEST_EXPIRY set failed");
            require(core.graduationPlatformFeeRate() == 550, "PLATFORM_FEE_RATE set failed");
            require(core.graduationCreatorFeeRate() == 250, "CREATOR_FEE_RATE set failed");
            require(core.MIN_LIQUIDITY() == 10 ether, "MIN_LIQUIDITY set failed");
            require(core.MAX_INITIAL_BUY_PERCENTAGE() == 9990, "MAX_INITIAL_BUY_PERCENTAGE set failed");

            addr_ = address(proxy);
            console.log("MemeCoreProxy deployed at %s", addr_);
            save("MemeCore", addr_);
            
            // 7. 配置权限
            MemeFactory(factory).setMeme(address(proxy));
            MemeHelper(helper).grantRole(MemeHelper(helper).CORE_ROLE(), address(proxy));
        } else {
            addr_ = cfg.MemeCore();
            console.log("MemeCoreProxy already deployed at %s", addr_);
        }
    }

    /**
     * @notice 部署 MemeVesting 归属合约（使用 UUPS 代理）
     * @dev 管理代币锁仓释放：线性、悬崖、销毁模式
     * @return addr_ 代理合约地址
     */
    function deployMemeVesting() public returns (address addr_) {
        MemeVesting vestingImpl;
        if (cfg.MemeVesting() == address(0)) {
            // 1. 部署实现合约
            vestingImpl = new MemeVesting();
            save("MemeVestingImpl", address(vestingImpl));
            console.log("MemeVestingImpl deployed at %s", address(vestingImpl));

            // 2. 部署 Core（如果尚未部署）
            address coreProxyAddr = deployMemeCore();
            
            // 3. 编码初始化数据
            bytes memory vestingInitData = abi.encodeWithSelector(
                MemeVesting.initialize.selector,
                cfg.Admin(),        // 管理员地址
                coreProxyAddr       // Core 代理地址（作为 operator）
            );
            
            // 4. 部署代理合约
            ERC1967Proxy vestingProxy = new ERC1967Proxy(address(vestingImpl), vestingInitData);

            addr_ = address(vestingProxy);
            console.log("MemeVestingProxy deployed at %s", addr_);
            save("MemeVesting", addr_);

            // 5. 配置 Core 引用 Vesting
            MemeCore(payable(address(coreProxyAddr))).setVesting(addr_);
        } else {
            addr_ = cfg.MemeVesting();
            console.log("MemeVestingProxy already deployed at %s", addr_);
        }
    }

    // ==================== 升级函数 ====================

    /**
     * @notice 升级 MemeCore 核心合约
     * @dev 使用 UUPS 升级模式，部署新实现并升级代理
     */
    function upgradeMemeCore() public {
        address currentCoreProxy = cfg.MemeCore();
        require(currentCoreProxy != address(0), "Core proxy not deployed");

        // 部署新实现合约
        MemeCore newImplementation = new MemeCore();
        console.log("New MemeCoreImpl deployed at:", address(newImplementation));

        save("MemeCoreImpl", address(newImplementation));
        
        // 执行升级（无额外初始化数据）
        bytes memory initData = "";
        UUPSUpgradeable core = UUPSUpgradeable(payable(currentCoreProxy));
        core.upgradeToAndCall(address(newImplementation), initData);
        
        console.log("Proxy address:", currentCoreProxy);
    }

    /**
     * @notice 升级 MemeVesting 归属合约
     * @dev 使用 UUPS 升级模式
     */
    function upgradeMemeVesting() public {
        address currentVestingProxy = cfg.MemeVesting();
        require(currentVestingProxy != address(0), "Vesting proxy not deployed");

        // 部署新实现合约
        MemeVesting newImplementation = new MemeVesting();
        console.log("New MemeVestingImpl deployed at:", address(newImplementation));

        save("MemeVestingImpl", address(newImplementation));
        
        // 执行升级
        bytes memory initData = "";
        UUPSUpgradeable vesting = UUPSUpgradeable(payable(currentVestingProxy));
        vesting.upgradeToAndCall(address(newImplementation), initData);

        console.log("Proxy address:", currentVestingProxy);
    }

    // ==================== 配置函数 ====================

    /**
     * @notice 配置 MemeCore 合约的所有参数和权限
     * @dev 检查并设置各项配置，授予必要的角色权限
     */
    function setMemeCore() public {
        // 优先使用部署记录中的地址，回退到配置文件
        address coreAddr = getAddress("MemeCore");
        if (coreAddr == address(0)) coreAddr = cfg.MemeCore();
        require(coreAddr != address(0), "MemeCore not deployed");

        address factoryAddr = getAddress("MemeFactory");
        if (factoryAddr == address(0)) factoryAddr = cfg.MemeFactory();

        address helperAddr = getAddress("MemeHelper");
        if (helperAddr == address(0)) helperAddr = cfg.MemeHelper();

        address vestingAddr = getAddress("MemeVesting");
        if (vestingAddr == address(0)) vestingAddr = cfg.MemeVesting();

        MemeCore core = MemeCore(payable(coreAddr));

        // ===== 配置地址 =====

        // 设置平台费用接收地址
        if (core.platformFeeReceiver() != cfg.PlatformFeeReceiver()) {
            core.setPlatformFeeReceiver(cfg.PlatformFeeReceiver());
            console.log("setPlatformFeeReceiver done");
        } else {
            console.log("platformFeeReceiver already set");
        }

        // 设置工厂合约地址
        if (address(core.factory()) != factoryAddr) {
            core.setFactory(factoryAddr);
            console.log("setFactory done");
        } else {
            console.log("MemeFactory already set");
        }

        // 设置辅助合约地址
        if (address(core.helper()) != helperAddr) {
            core.setHelper(helperAddr);
            console.log("setHelper done");
        } else {
            console.log("MemeHelper already set");
        }

        // 设置归属合约地址
        if (address(core.vesting()) != vestingAddr) {
            core.setVesting(vestingAddr);
            console.log("setVesting done");
        } else {
            console.log("MemeVesting already set");
        }

        // 设置保证金接收地址
        if (address(core.marginReceiver()) != cfg.MarginReceiver()) {
            core.setMarginReceiver(cfg.MarginReceiver());
            console.log("setMarginReceiver done");
        } else {
            console.log("MarginReceiver already set");
        }

        // ===== 配置权限 =====

        MemeFactory factory = MemeFactory(factoryAddr);
        MemeHelper helper = MemeHelper(payable(helperAddr));

        // 授予签名者 SIGNER_ROLE
        if (!core.hasRole(core.SIGNER_ROLE(), cfg.Signer())) {
            core.grantRole(core.SIGNER_ROLE(), cfg.Signer());
            console.log("MemeCore grant SIGNER_ROLE to Signer done");
        }

        // 授予签名者 DEPLOYER_ROLE
        if (!core.hasRole(core.DEPLOYER_ROLE(), cfg.Signer())) {
            core.grantRole(core.DEPLOYER_ROLE(), cfg.Signer());
            console.log("MemeCore grant DEPLOYER_ROLE to Signer done");
        }

        // 授予 Core DEPLOYER_ROLE（在 Factory 中）
        if (!factory.hasRole(factory.DEPLOYER_ROLE(), coreAddr)) {
            factory.grantRole(factory.DEPLOYER_ROLE(), coreAddr);
            console.log("MemeFactory grant DEPLOYER_ROLE to MemeCore done");
        }

        // 设置 Factory 的 Meme 地址
        if (address(factory.metaNode()) != coreAddr) {
            factory.setMeme(coreAddr);
            console.log("MemeFactory setMeme done");
        } else {
            console.log("MemeFactory metaNode already set");
        }

        // 授予 Core CORE_ROLE（在 Helper 中）
        if (!helper.hasRole(helper.CORE_ROLE(), coreAddr)) {
            helper.grantRole(helper.CORE_ROLE(), coreAddr);
            console.log("MemeHelper grant CORE_ROLE to MemeCore done");
        }

        // 设置最小锁仓时间
        if (core.minLockTime() != cfg.MinLockTime()) {
            core.setMinLockTime(cfg.MinLockTime());
            console.log("MemeCore setMinLockTime done");
        } else {
            console.log("MemeCore setMinLockTime already set");
        }
    }
}
