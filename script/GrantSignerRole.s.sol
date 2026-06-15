// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MemeCore} from "../src/MemeCore.sol";

/**
 * @title GrantSignerRole
 * @notice 为签名者地址授予 SIGNER_ROLE
 */
contract GrantSignerRole is Script {
    // 合约地址 (Sepolia Testnet)
    MemeCore public core = MemeCore(payable(0x69207F321CFDfd30D73D1d9278e4132E15080ec9));
    
    // 签名者地址（从私钥 c3403525339818ca6d633b409c2f8e31d24250b303f97311b3e2b3bc73516c1f 推导）
    address public signer = 0xF9234defe30C7801837185584d5C986045A9A6E6;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("==============================================");
        console.log("   Grant SIGNER_ROLE");
        console.log("==============================================");
        console.log("Deployer:", deployer);
        console.log("Core Contract:", address(core));
        console.log("Signer Address:", signer);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 检查是否已有权限
        bool hasRole = core.hasRole(core.SIGNER_ROLE(), signer);
        console.log("Current has SIGNER_ROLE:", hasRole);

        if (!hasRole) {
            // 授予 SIGNER_ROLE
            core.grantRole(core.SIGNER_ROLE(), signer);
            console.log("SIGNER_ROLE granted to", signer);
        } else {
            console.log("Signer already has SIGNER_ROLE");
        }

        // 验证权限
        bool hasRoleAfter = core.hasRole(core.SIGNER_ROLE(), signer);
        console.log("After grant, has SIGNER_ROLE:", hasRoleAfter);

        vm.stopBroadcast();

        console.log("");
        console.log("==============================================");
        console.log("   Done!");
        console.log("==============================================");
    }
}

