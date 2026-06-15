// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title UniswapV2Factory
/// @notice 简化版 Uniswap V2 Factory，兼容 PancakeSwap V2 接口
contract UniswapV2Factory {
    address public feeTo;
    address public immutable owner;

    // PancakeSwap V2 Pair INIT_CODE_HASH
    bytes32 public immutable INIT_CODE_HASH = 0xd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(address _feeTo, address _owner) {
        feeTo = _feeTo;
        owner = _owner;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        require(tokenA != address(0) && tokenB != address(0), "UniswapV2: ZERO_ADDRESS");

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(getPair[token0][token1] == address(0), "UniswapV2: PAIR_EXISTS");

        // Deploy pair using CREATE2
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        // Deploy UniswapV2Pair-like contract
        pair = _createPair(token0, token1, salt);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function _createPair(address token0, address token1, bytes32 salt) internal returns (address) {
        // Deploy pair contract
        address pair = address(new UniswapV2Pair());
        UniswapV2Pair(pair).initialize(token0, token1);
        return pair;
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == owner, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }
}

/// @title UniswapV2Pair
/// @notice 简化版交易对合约，兼容 PancakeSwap V2
contract UniswapV2Pair {
    address public token0;
    address public token1;

    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    constructor() {}

    function initialize(address _token0, address _token1) external {
        require(token0 == address(0) && token1 == address(0), "ALREADY_INITIALIZED");
        token0 = _token0;
        token1 = _token1;
    }

    function mint(address to) external returns (uint256 liquidity) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        if (totalSupply == 0) {
            // Initial liquidity
            liquidity = (balance0 * balance1) / 1000 ether;
        } else {
            liquidity = (totalSupply * balance0) / reserve0;
        }

        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY");

        totalSupply += liquidity;
        balanceOf[to] += liquidity;

        reserve0 = balance0;
        reserve1 = balance1;

        emit Transfer(address(0), to, liquidity);
        emit Mint(msg.sender, balance0, balance1);
    }

    function burn(address to) external returns (uint256 amount0, uint256 amount1) {
        uint256 liquidity = balanceOf[msg.sender];

        amount0 = (liquidity * reserve0) / totalSupply;
        amount1 = (liquidity * reserve1) / totalSupply;

        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY");

        balanceOf[msg.sender] -= liquidity;
        totalSupply -= liquidity;

        reserve0 -= amount0;
        reserve1 -= amount1;

        IERC20(token0).transfer(to, amount0);
        IERC20(token1).transfer(to, amount1);

        emit Transfer(msg.sender, address(0), liquidity);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserve0 >= amount0Out && reserve1 >= amount1Out, "INSUFFICIENT_LIQUIDITY");

        if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);

        reserve0 = IERC20(token0).balanceOf(address(this));
        reserve1 = IERC20(token1).balanceOf(address(this));
    }
}
