// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MemeCore} from "../src/MemeCore.sol";
import {IMemeCore} from "../src/interfaces/IMemeCore.sol";

/**
 * @title TestFeeCalculation
 * @notice 测试费用计算，验证前端计算是否正确
 */
contract TestFeeCalculation is Script {
    MemeCore public core = MemeCore(payable(0x69207F321CFDfd30D73D1d9278e4132E15080ec9));

    function run() external {
        console.log("==============================================");
        console.log("   Test Fee Calculation");
        console.log("==============================================");
        console.log("Core Contract:", address(core));
        console.log("");
        
        // Read contract fees
        uint256 creationFee = core.creationFee();
        uint256 preBuyFeeRate = core.preBuyFeeRate();
        
        console.log("Contract Configuration:");
        console.log("creationFee (wei):", creationFee);
        console.log("creationFee (BNB):", creationFee / 1e18);
        console.log("preBuyFeeRate (BP):", preBuyFeeRate);
        console.log("preBuyFeeRate (%):", preBuyFeeRate / 100);
        console.log("");
        
        // Test case: 10% prebuy (1000 BP)
        uint256 percentageBP = 1000; // 10%
        uint256 totalSupply = 1_000_000_000 * 1e18; // 1,000,000,000 tokens
        uint256 virtualETHReserve = 8219178082191780000; // ~8.22 BNB
        uint256 virtualTokenReserve = 1073972602 * 1e18; // 1,073,972,602 tokens
        
        console.log("Test Parameters:");
        console.log("percentageBP:", percentageBP);
        console.log("totalSupply:", totalSupply);
        console.log("virtualETHReserve:", virtualETHReserve);
        console.log("virtualTokenReserve:", virtualTokenReserve);
        console.log("");
        
        // Calculate using contract function
        (uint256 totalPayment, uint256 preBuyFee) = core.calculateInitialBuyETH(
            totalSupply,
            virtualETHReserve,
            virtualTokenReserve,
            percentageBP
        );
        
        console.log("Contract Calculation Result:");
        console.log("totalPayment (wei):", totalPayment);
        console.log("totalPayment (BNB):", totalPayment / 1e18);
        console.log("preBuyFee (wei):", preBuyFee);
        console.log("preBuyFee (BNB):", preBuyFee / 1e18);
        uint256 initialETH = totalPayment - preBuyFee;
        console.log("initialETH (wei):", initialETH);
        console.log("initialETH (BNB):", initialETH / 1e18);
        console.log("");
        
        // Calculate total required
        uint256 totalRequired = creationFee + totalPayment;
        console.log("Total Required Payment:");
        console.log("creationFee (BNB):", creationFee / 1e18);
        console.log("initialETH + preBuyFee (BNB):", totalPayment / 1e18);
        console.log("TOTAL (BNB):", totalRequired / 1e18);
        console.log("TOTAL (wei):", totalRequired);
        console.log("");
        
        // Test with different values to find minimum
        console.log("Testing different msg.value amounts:");
        for (uint256 i = 0; i < 5; i++) {
            uint256 testValue = totalRequired - (i * 1e15); // Subtract 0.001 ETH each time
            bool wouldPass = testValue >= creationFee && testValue >= totalRequired;
            console.log("Test value", i, "BNB:", testValue / 1e18);
            console.log("Would pass:", wouldPass);
        }
        
        console.log("");
        console.log("==============================================");
    }
}

