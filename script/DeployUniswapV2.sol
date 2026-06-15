// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "./uniswap-v2/UniswapV2Factory.sol";
import "./uniswap-v2/UniswapV2Router02.sol";

/**
 * @title DeployUniswapV2
 * @notice 部署简化的 Uniswap V2 Factory 和 Router 到 Base Sepolia
 * @dev 部署的合约兼容 PancakeSwap V2 接口
 */
contract DeployUniswapV2 is Script {
    // Base Sepolia WETH 地址
    address constant BASE_SEPOLIA_WETH = 0x4200000000000000000000000000000000000006;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("==============================================");
        console.log("   Uniswap V2 Deployment - Base Sepolia");
        console.log("==============================================");
        console.log("Deployer:", deployer);
        console.log("ChainId:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署 Factory
        console.log("Deploying UniswapV2Factory...");
        UniswapV2Factory factory = new UniswapV2Factory(
            deployer,  // feeTo
            deployer   // owner
        );
        console.log("UniswapV2Factory deployed at:", address(factory));
        console.logBytes32(factory.INIT_CODE_HASH());

        // 2. 部署 Router
        console.log("Deploying UniswapV2Router02...");
        UniswapV2Router02 router = new UniswapV2Router02(
            address(factory),
            BASE_SEPOLIA_WETH
        );
        console.log("UniswapV2Router02 deployed at:", address(router));

        vm.stopBroadcast();

        console.log("");
        console.log("==============================================");
        console.log("   Deployment Complete!");
        console.log("==============================================");
        console.log("Factory:", address(factory));
        console.log("Router:", address(router));
        console.log("WETH:", BASE_SEPOLIA_WETH);
        console.log("");
        console.log("==============================================");
        console.log("   Next: Update deploy-config/base_sepolia/dev.json");
        console.log("   Set Router to:", address(router));
        console.log("==============================================");
    }
}
