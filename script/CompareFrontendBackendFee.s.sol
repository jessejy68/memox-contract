// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MemeCore} from "../src/MemeCore.sol";

/**
 * @title CompareFrontendBackendFee
 * @notice 对比前端计算和合约计算的费用，找出差异
 */
contract CompareFrontendBackendFee is Script {
    MemeCore public core = MemeCore(payable(0x69207F321CFDfd30D73D1d9278e4132E15080ec9));

    function run() external {
        console.log("==============================================");
        console.log("   Compare Frontend vs Contract Fee Calculation");
        console.log("==============================================");
        
        uint256 creationFee = core.creationFee();
        uint256 preBuyFeeRate = core.preBuyFeeRate();
        
        // Test case: 10% prebuy, no margin
        uint256 totalSupply = 1_000_000_000 * 1e18;
        uint256 virtualETHReserve = 8219178082191780000;
        uint256 virtualTokenReserve = 1073972602 * 1e18;
        uint256 initialBuyPercentage = 1000; // 10% = 1000 BP
        uint256 marginEth = 0;
        
        // Contract calculation (what actually happens in createToken)
        (uint256 tokensOut, uint256 initialETH, uint256 newETHReserve, uint256 newTokenReserve) = 
            this.calculateInitialBuyInternal(totalSupply, virtualETHReserve, virtualTokenReserve, initialBuyPercentage);
        uint256 preBuyFee = (initialETH * preBuyFeeRate) / 10000;
        uint256 contractTotalPaymentRequired = creationFee + marginEth + initialETH + preBuyFee;
        
        // Frontend calculation (what frontend should calculate)
        // Frontend uses calculateInitialBuyETH which returns (totalPayment, preBuyFee)
        (uint256 frontendTotalPayment, uint256 frontendPreBuyFee) = core.calculateInitialBuyETH(
            totalSupply,
            virtualETHReserve,
            virtualTokenReserve,
            initialBuyPercentage
        );
        uint256 frontendInitialETH = frontendTotalPayment - frontendPreBuyFee;
        uint256 frontendTotalPaymentRequired = creationFee + marginEth + frontendInitialETH + frontendPreBuyFee;
        
        console.log("Contract Internal Calculation:");
        console.log("initialETH:", initialETH);
        console.log("preBuyFee:", preBuyFee);
        console.log("totalPaymentRequired:", contractTotalPaymentRequired);
        console.log("");
        
        console.log("Frontend Calculation (using calculateInitialBuyETH):");
        console.log("frontendInitialETH:", frontendInitialETH);
        console.log("frontendPreBuyFee:", frontendPreBuyFee);
        console.log("frontendTotalPaymentRequired:", frontendTotalPaymentRequired);
        console.log("");
        
        console.log("Comparison:");
        console.log("initialETH match:", initialETH == frontendInitialETH);
        console.log("preBuyFee match:", preBuyFee == frontendPreBuyFee);
        console.log("totalPaymentRequired match:", contractTotalPaymentRequired == frontendTotalPaymentRequired);
        
        if (contractTotalPaymentRequired != frontendTotalPaymentRequired) {
            console.log("DIFFERENCE:", contractTotalPaymentRequired > frontendTotalPaymentRequired ? 
                contractTotalPaymentRequired - frontendTotalPaymentRequired : 
                frontendTotalPaymentRequired - contractTotalPaymentRequired);
        }
        
        console.log("");
        console.log("==============================================");
    }
    
    // Helper function to call internal _calculateInitialBuy
    function calculateInitialBuyInternal(
        uint256 totalSupply,
        uint256 virtualETHReserve,
        uint256 virtualTokenReserve,
        uint256 percentageBP
    ) external pure returns (uint256 tokensOut, uint256 bnbRequired, uint256 newETHReserve, uint256 newTokenReserve) {
        tokensOut = (totalSupply * percentageBP) / 10000;
        uint256 k = virtualETHReserve * virtualTokenReserve;
        newTokenReserve = virtualTokenReserve - tokensOut;
        newETHReserve = k / newTokenReserve;
        bnbRequired = newETHReserve - virtualETHReserve;
    }
}


