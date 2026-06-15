// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DeployAll
 * @notice 一键部署完整的 MEMOX 系统
 * @dev 部署所有合约并配置权限
 */

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MemeCore} from "../src/MemeCore.sol";
import {MemeFactory} from "../src/MemeFactory.sol";
import {MemeHelper} from "../src/MemeHelper.sol";
import {MemeVesting} from "../src/MemeVesting.sol";

contract DeployAll is Script {
    // Sepolia 测试网配置
    address constant PANCAKE_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("==============================================");
        console.log("   MEMOX Sepolia Testnet Deployment");
        console.log("==============================================");
        console.log("Deployer:", deployer);
        console.log("ChainId:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署 Factory
        console.log("1. Deploying MemeFactory...");
        MemeFactory factory = new MemeFactory(deployer);
        console.log("   MemeFactory deployed at:", address(factory));

        // 2. 部署 Helper
        console.log("2. Deploying MemeHelper...");
        MemeHelper helper = new MemeHelper(deployer, PANCAKE_ROUTER, WETH);
        console.log("   MemeHelper deployed at:", address(helper));

        // 3. 部署 Core 实现
        console.log("3. Deploying MemeCore...");
        MemeCore coreImpl = new MemeCore();
        console.log("   MemeCore impl deployed at:", address(coreImpl));

        // 4. 部署 Core 代理
        bytes memory initData = abi.encodeWithSelector(
            MemeCore.initialize.selector,
            address(factory),    // factory
            address(helper),     // helper
            deployer,            // signer
            deployer,            // platformFeeReceiver
            deployer,            // marginReceiver
            deployer,            // graduateFeeReceiver
            deployer             // admin
        );
        ERC1967Proxy coreProxy = new ERC1967Proxy(address(coreImpl), initData);
        MemeCore core = MemeCore(payable(address(coreProxy)));
        console.log("   MemeCore proxy deployed at:", address(core));

        // 5. 部署 Vesting 实现
        console.log("4. Deploying MemeVesting...");
        MemeVesting vestingImpl = new MemeVesting();
        console.log("   MemeVesting impl deployed at:", address(vestingImpl));

        // 6. 部署 Vesting 代理
        bytes memory vestingInitData = abi.encodeWithSelector(
            MemeVesting.initialize.selector,
            deployer,           // admin
            address(core)       // operator (core)
        );
        ERC1967Proxy vestingProxy = new ERC1967Proxy(address(vestingImpl), vestingInitData);
        MemeVesting vesting = MemeVesting(address(vestingProxy));
        console.log("   MemeVesting proxy deployed at:", address(vesting));

        // 7. 配置权限
        console.log("5. Configuring permissions...");
        
        // Factory 设置 Meme
        factory.setMeme(address(core));
        console.log("   Factory.setMeme done");

        // Factory 授予 Core DEPLOYER_ROLE
        factory.grantRole(factory.DEPLOYER_ROLE(), address(core));
        console.log("   Factory granted DEPLOYER_ROLE to Core");

        // Helper 授予 Core CORE_ROLE
        helper.grantRole(helper.CORE_ROLE(), address(core));
        console.log("   Helper granted CORE_ROLE to Core");

        // Core 设置 Vesting
        core.setVesting(address(vesting));
        console.log("   Core.setVesting done");

        // Core 授予 deployer SIGNER_ROLE
        core.grantRole(core.SIGNER_ROLE(), deployer);
        console.log("   Core granted SIGNER_ROLE to deployer");

        // Core 授予 deployer DEPLOYER_ROLE
        core.grantRole(core.DEPLOYER_ROLE(), deployer);
        console.log("   Core granted DEPLOYER_ROLE to deployer");

        vm.stopBroadcast();

        // 输出部署结果
        console.log("");
        console.log("==============================================");
        console.log("   Deployment Complete!");
        console.log("==============================================");
        console.log("MemeFactory:    ", address(factory));
        console.log("MemeHelper:     ", address(helper));
        console.log("MemeCore:   ", address(core));
        console.log("MemeVesting:    ", address(vesting));
        console.log("");
        console.log("Admin:          ", deployer);
        console.log("Signer:         ", deployer);
        console.log("");
    }
}

