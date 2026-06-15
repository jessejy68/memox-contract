// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function INIT_CODE_HASH() external pure returns (bytes32);
}

interface IUniswapV2Pair {
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title UniswapV2Router02
/// @notice 简化版 Uniswap V2 Router，兼容 PancakeSwap V2 接口
contract UniswapV2Router02 {
    using SafeERC20 for IERC20;

    address public immutable factory;
    address public immutable WETH;

    // 死地址
    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    /**
     * @notice 添加流动性（兼容 PancakeSwap V2 接口）
     * @param token 代币地址
     * @param amountTokenDesired 期望代币数量
     * @param amountTokenMin 最小代币数量
     * @param amountETHMin 最小 ETH 数量
     * @param deadline 截止时间
     * @param optOutUserShare 是否放弃用户份额（设为 true 时 LP 发送到死地址）
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline,
        bool optOutUserShare
    ) external payable ensure(deadline) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        IUniswapV2Factory factoryContract = IUniswapV2Factory(factory);

        // Create pair if doesn't exist
        if (factoryContract.getPair(token, WETH) == address(0)) {
            factoryContract.createPair(token, WETH);
        }

        address pair = factoryContract.getPair(token, WETH);

        // Transfer tokens from sender
        IERC20(token).safeTransferFrom(msg.sender, address(this), amountTokenDesired);

        // Calculate amounts (simplified - use provided amounts)
        amountToken = amountTokenDesired;
        amountETH = msg.value;

        // Approve and transfer
        IERC20(token).safeTransfer(pair, amountToken);

        // Wrap ETH and transfer
        IWETH(WETH).deposit{value: amountETH}();
        IWETH(WETH).transfer(pair, amountETH);

        // Mint LP tokens
        liquidity = IUniswapV2Pair(pair).mint(
            optOutUserShare ? DEAD_ADDRESS : msg.sender
        );

        // Refund excess ETH
        if (msg.value > amountETH) {
            (bool success, ) = msg.sender.call{value: msg.value - amountETH}("");
            require(success, "ETH refund failed");
        }

        // Refund excess tokens
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        if (tokenBalance > 0) {
            IERC20(token).safeTransfer(msg.sender, tokenBalance);
        }
    }

    /**
     * @notice 移除流动性（兼容 PancakeSwap V2 接口）
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        IUniswapV2Factory factoryContract = IUniswapV2Factory(factory);
        address pair = factoryContract.getPair(token, WETH);
        require(pair != address(0), "PAIR_NOT_FOUND");

        // Transfer LP tokens
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);

        // Burn LP tokens
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);

        // Sort tokens
        (address token0,) = _sortTokens(token, WETH);
        (amountToken, amountETH) = token == token0 ? (amount0, amount1) : (amount1, amount0);

        require(amountToken >= amountTokenMin, "INSUFFICIENT_TOKEN_AMOUNT");
        require(amountETH >= amountETHMin, "INSUFFICIENT_ETH_AMOUNT");
    }

    /**
     * @notice 获取数量输出
     */
    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        pure
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        // Simplified: 1:1 ratio for testing
        for (uint256 i = 1; i < path.length; i++) {
            amounts[i] = amountIn;
        }
    }

    /**
     * @notice 获取数量输入
     */
    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        pure
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](path.length);
        amounts[path.length - 1] = amountOut;
        // Simplified: 1:1 ratio for testing
        for (uint256 i = path.length - 1; i > 0; i--) {
            amounts[i - 1] = amountOut;
        }
    }

    /**
     * @notice 交换 ETH 为代币（兼容 PancakeSwap V2）
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) {
        require(path[0] == WETH, "INVALID_PATH");

        uint256 amountOut = _swapETHForTokens(msg.value, path, to);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
    }

    /**
     * @notice 交换代币为 ETH（兼容 PancakeSwap V2）
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) {
        require(path[path.length - 1] == WETH, "INVALID_PATH");

        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = _swapTokensForETH(amountIn, path, to);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
    }

    /**
     * @notice 交换代币（兼容 PancakeSwap V2）
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = _swapTokens(path, amountIn, to);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
        _swapTokens(path, amountIn, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        uint256 amountIn = _swapTokens(path, amountOut, to);
        require(amountIn <= amountInMax, "EXCESSIVE_INPUT_AMOUNT");

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        uint256 amountOut = _swapETHForTokens(msg.value, path, to);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        amounts = new uint256[](2);
        amounts[0] = msg.value;
        amounts[1] = amountOut;
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountInMax);

        uint256 amountIn = _swapTokensForETH(amountOut, path, to);
        require(amountIn <= amountInMax, "EXCESSIVE_INPUT_AMOUNT");

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        uint256 amountIn = _swapETHForTokens(amountOut, path, to);
        require(msg.value >= amountIn, "EXCESSIVE_INPUT_AMOUNT");

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        // Refund excess
        if (msg.value > amountIn) {
            (bool success, ) = msg.sender.call{value: msg.value - amountIn}("");
            require(success, "ETH refund failed");
        }
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = _swapTokensForETH(amountOutMin, path, to);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    // Internal functions
    function _swapETHForTokens(uint256 amountIn, address[] calldata path, address to) internal returns (uint256 amountOut) {
        address pair = IUniswapV2Factory(factory).getPair(path[0], path[1]);
        require(pair != address(0), "PAIR_NOT_FOUND");

        IWETH(WETH).deposit{value: amountIn}();
        IWETH(WETH).transfer(pair, amountIn);

        // Simplified swap
        amountOut = amountIn;
    }

    function _swapTokensForETH(uint256 amountIn, address[] calldata path, address to) internal returns (uint256 amountOut) {
        address pair = IUniswapV2Factory(factory).getPair(path[0], path[1]);
        require(pair != address(0), "PAIR_NOT_FOUND");

        // Simplified swap
        amountOut = amountIn;
        IWETH(WETH).withdraw(amountOut);
        (bool success, ) = to.call{value: amountOut}("");
        require(success, "ETH transfer failed");
    }

    function _swapTokens(address[] calldata path, uint256 amount, address to) internal returns (uint256 amountOut) {
        address pair = IUniswapV2Factory(factory).getPair(path[0], path[1]);
        require(pair != address(0), "PAIR_NOT_FOUND");

        // Simplified swap
        amountOut = amount;
        IERC20(path[1]).transfer(to, amountOut);
    }

    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}
