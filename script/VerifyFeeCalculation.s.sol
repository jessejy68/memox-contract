// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MemeCore} from "../src/MemeCore.sol";
import {IMemeCore} from "../src/interfaces/IMemeCore.sol";

/**
 * @title VerifyFeeCalculation
 * @notice 验证前端计算的费用是否与合约的 totalPaymentRequired 一致
 */
contract VerifyFeeCalculation is Script {
    MemeCore public core = MemeCore(payable(0x69207F321CFDfd30D73D1d9278e4132E15080ec9));

    function run() external {
        console.log("==============================================");
        console.log("   Verify Fee Calculation");
        console.log("==============================================");
        
        // Read contract fees
        uint256 creationFee = core.creationFee();
        uint256 preBuyFeeRate = core.preBuyFeeRate();
        
        console.log("Contract Configuration:");
        console.log("creationFee:", creationFee);
        console.log("preBuyFeeRate:", preBuyFeeRate);
        console.log("");
        
        // Test parameters (from frontend)
        uint256 totalSupply = 1_000_000_000 * 1e18; // 1,000,000,000 tokens
        uint256 saleAmount = 800_000_000 * 1e18; // 800,000,000 tokens
        uint256 virtualETHReserve = 8219178082191780000; // ~8.22 BNB
        uint256 virtualTokenReserve = 1073972602 * 1e18; // 1,073,972,602 tokens
        uint256 initialBuyPercentage = 1000; // 10% = 1000 BP
        uint256 marginEth = 0;
        
        console.log("Test Parameters:");
        console.log("totalSupply:", totalSupply);
        console.log("saleAmount:", saleAmount);
        console.log("virtualETHReserve:", virtualETHReserve);
        console.log("virtualTokenReserve:", virtualTokenReserve);
        console.log("initialBuyPercentage:", initialBuyPercentage, "BP (10%)");
        console.log("marginEth:", marginEth);
        console.log("");
        
        // Calculate using contract function (what frontend should use)
        (uint256 totalPayment, uint256 preBuyFee) = core.calculateInitialBuyETH(
            totalSupply,
            virtualETHReserve,
            virtualTokenReserve,
            initialBuyPercentage
        );
        
        uint256 initialETH = totalPayment - preBuyFee;
        
        console.log("Contract calculateInitialBuyETH Result:");
        console.log("totalPayment:", totalPayment);
        console.log("preBuyFee:", preBuyFee);
        console.log("initialETH:", initialETH);
        console.log("");
        
        // Calculate totalPaymentRequired (as contract does in createToken)
        uint256 totalPaymentRequired = creationFee;
        if (marginEth > 0) {
            totalPaymentRequired += marginEth;
        }
        if (initialBuyPercentage > 0) {
            totalPaymentRequired += initialETH + preBuyFee;
        }
        
        console.log("Contract totalPaymentRequired Calculation:");
        console.log("Step 1: totalPaymentRequired = creationFee");
        console.log("  totalPaymentRequired:", creationFee);
        console.log("Step 2: if (marginEth > 0) totalPaymentRequired += marginEth");
        console.log("  marginEth:", marginEth);
        console.log("  totalPaymentRequired:", totalPaymentRequired);
        console.log("Step 3: if (initialBuyPercentage > 0) totalPaymentRequired += initialETH + preBuyFee");
        console.log("  initialETH:", initialETH);
        console.log("  preBuyFee:", preBuyFee);
        console.log("  totalPaymentRequired:", totalPaymentRequired);
        console.log("");
        
        console.log("Final Result:");
        console.log("totalPaymentRequired (wei):", totalPaymentRequired);
        console.log("totalPaymentRequired (BNB):", totalPaymentRequired / 1e18);
        console.log("");
        
        // Test different msg.value amounts
        console.log("Testing msg.value amounts:");
        uint256[] memory testValues = new uint256[](5);
        testValues[0] = totalPaymentRequired; // Exact amount
        testValues[1] = totalPaymentRequired - 1; // 1 wei less
        testValues[2] = totalPaymentRequired - 1e15; // 0.001 ETH less
        testValues[3] = creationFee; // Only creationFee
        testValues[4] = creationFee + initialETH; // creationFee + initialETH (missing preBuyFee)
        
        for (uint256 i = 0; i < testValues.length; i++) {
            bool passFirstCheck = testValues[i] >= creationFee;
            bool passSecondCheck = testValues[i] >= totalPaymentRequired;
            console.log("Test", i);
            console.log("msg.value (wei):", testValues[i]);
            console.log("msg.value (BNB):", testValues[i] / 1e18);
            console.log("Pass line 383:", passFirstCheck);
            console.log("Pass line 430:", passSecondCheck);
            console.log("");
        }
        
        console.log("==============================================");
    }
}

