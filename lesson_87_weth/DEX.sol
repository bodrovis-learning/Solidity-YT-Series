// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPToken.sol";

contract SimpleDEX {
    uint256 public wethReserve;
    uint256 public tokenAReserve;
    LPToken public _lpToken;
    IERC20 private _weth;
    IERC20 private _tokenA;

    event SwappedTokenAToWeth(uint256 indexed tokenAAmount, uint256 indexed wethAmount, uint256 indexed feeAmount);
    event SwappedWethToTokenA(uint256 indexed wethAmount, uint256 indexed tokenAAmount, uint256 indexed feeAmount);
    event LiquidityRemoved(uint256 indexed tokenAAmount, uint256 indexed wethAmount);
    
    constructor(address weth_, address tokenA_) {
        _weth = IERC20(weth_);
        _tokenA = IERC20(tokenA_);
        _lpToken = new LPToken("Liquidity Provider Token", "LPT");
    }

    function addLiquidity(uint256 _wethAmount, uint256 _tokenAAmount) external {
        uint256 lpAmount;

        if (wethReserve == 0 && tokenAReserve == 0) {
            // Initial liquidity provider gets LP tokens equal to the added liquidity
            lpAmount = _wethAmount;
        } else {
            // Subsequent providers get LP tokens proportional to their contribution
            lpAmount = (_wethAmount * _lpToken.totalSupply()) / wethReserve;
        }
        
        require(_weth.transferFrom(msg.sender, address(this), _wethAmount), "WETH transfer failed");
        require(_tokenA.transferFrom(msg.sender, address(this), _tokenAAmount), "TokenA transfer failed");

        wethReserve += _wethAmount;
        tokenAReserve += _tokenAAmount;
        
        _lpToken.mint(msg.sender, lpAmount);
    }

    function removeLiquidity(uint256 _lpTokenAmount) external {
        require(_lpToken.balanceOf(msg.sender) >= _lpTokenAmount, "Not enough LP tokens");

        uint256 wethAmount = (_lpTokenAmount * wethReserve) / _lpToken.totalSupply();
        uint256 tokenAAmount = (_lpTokenAmount * tokenAReserve) / _lpToken.totalSupply();

        wethReserve -= wethAmount;
        tokenAReserve -= tokenAAmount;

        _lpToken.burn(msg.sender, _lpTokenAmount);

        _weth.transfer(msg.sender, wethAmount);
        _tokenA.transfer(msg.sender, tokenAAmount);

        emit LiquidityRemoved(tokenAAmount, wethAmount);
    }

    // Function to swap WETH for TokenA, with a small fee to incentivize liquidity providers
    function swapWETHForTokenA(uint256 _wethAmount) external {
        uint256 fee = (_wethAmount * 3) / 1000; // 0.3% fee
        uint256 amountToSwap = _wethAmount - fee;
        uint256 tokenAAmount = getAmountOut(amountToSwap, wethReserve, tokenAReserve);
        
        require(tokenAAmount > 0, "Invalid swap amount");

        _weth.transferFrom(msg.sender, address(this), _wethAmount);
        _tokenA.transfer(msg.sender, tokenAAmount);

        wethReserve += amountToSwap;
        tokenAReserve -= tokenAAmount;

        wethReserve += fee;

        emit SwappedTokenAToWeth(_wethAmount, tokenAAmount, fee);
    }

    function swapTokenAForWETH(uint256 _tokenAAmount) external {
        uint256 fee = (_tokenAAmount * 3) / 1000;
        uint256 amountToSwap = _tokenAAmount - fee;
        uint256 wethAmount = getAmountOut(amountToSwap, tokenAReserve, wethReserve);

        require(wethAmount > 0, "Invalid swap amount");

        _tokenA.transferFrom(msg.sender, address(this), _tokenAAmount);
        _weth.transfer(msg.sender, wethAmount);

        tokenAReserve += amountToSwap;
        wethReserve -= wethAmount;

        tokenAReserve += fee;

        emit SwappedTokenAToWeth(_tokenAAmount, wethAmount, fee);
    }

    function getAmountOut(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");

        uint256 inputAmountWithFee = inputAmount * 997;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;

        return numerator / denominator;
    }
}

