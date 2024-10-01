// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract Dex is ReentrancyGuard {
    IERC20 public Token1;
    IERC20 public Token2;

    uint256 public reserve1;
    uint256 public reserve2;
    uint256 public Total_Liq;

    mapping(address => uint256) public liquidity;

    // Events
    event _addliquidit(address sender, uint256 Token1_amount, uint256 Token2_amount);
    event RemoveLiquidity(address receiver, uint256 Token1_amount, uint256 Token2_amount);
    event Swap(address swapper, address tokenIN, uint256 amountIn, address tokenOUT, uint256 amountOut);

    constructor(address _token1, address _token2) {
        Token1 = IERC20(_token1);
        Token2 = IERC20(_token2);
    }

    function addLiquidity(uint256 Token1_amount, uint256 Token2_amount)
        external
        nonReentrant
        returns (uint256 total_mint)
    {
        uint256 total_liq_mint;

        if (Total_Liq == 0) {
            reserve1 = Token1_amount;
            reserve2 = Token2_amount;
            total_liq_mint = Token1_amount; // Assumes Token1 ratio sets initial liquidity
        } else {
            uint256 token1_ratio = Token1_amount * Total_Liq / reserve1;
            uint256 token2_ratio = Token2_amount * Total_Liq / reserve2;
            require(token1_ratio == token2_ratio, "Unbalanced ratio of tokens");
            total_liq_mint = token1_ratio;
        }

        // Update state before external interactions
        reserve1 += Token1_amount;
        reserve2 += Token2_amount;
        Total_Liq += total_liq_mint;
        liquidity[msg.sender] += total_liq_mint;

        // Transfer tokens
        Token1.transferFrom(msg.sender, address(this), Token1_amount);
        Token2.transferFrom(msg.sender, address(this), Token2_amount);

        emit _addliquidit(msg.sender, Token1_amount, Token2_amount);
        return total_liq_mint;
    }

    function Withdraw_Liq(uint256 _amount)
        external
        nonReentrant
        returns (uint256 _token1_amount, uint256 _token2_amount)
    {
        require(liquidity[msg.sender] >= _amount, "Insufficient liquidity");

        uint256 token1Amount = _amount * reserve1 / Total_Liq;
        uint256 token2Amount = _amount * reserve2 / Total_Liq;

        reserve1 -= token1Amount;
        reserve2 -= token2Amount;
        Total_Liq -= _amount;
        liquidity[msg.sender] -= _amount;

        Token1.transfer(msg.sender, token1Amount);
        Token2.transfer(msg.sender, token2Amount);

        emit RemoveLiquidity(msg.sender, token1Amount, token2Amount);
        return (token1Amount, token2Amount);
    }

    function swap(uint256 _amount, address tokenIN, address tokenOUT)
        external
        nonReentrant
        returns (uint256 amount_out)
    {
        require(
            (tokenIN == address(Token1) && tokenOUT == address(Token2))
                || (tokenIN == address(Token2) && tokenOUT == address(Token1)),
            "Invalid pair of tokens"
        );
        uint256 k = reserve1 * reserve2;

        if (tokenIN == address(Token1)) {
            Token1.transferFrom(msg.sender, address(this), _amount);
            reserve1 += _amount;  // Update reserve before external call

            uint256 newReserve2 = k / reserve1;
            amount_out = reserve2 - newReserve2;
            reserve2 = newReserve2;

            Token2.transfer(msg.sender, amount_out);  // Interaction after state change
        } else {
            Token2.transferFrom(msg.sender, address(this), _amount);
            reserve2 += _amount;  // Update reserve before external call

            uint256 newReserve1 = k / reserve2;
            amount_out = reserve1 - newReserve1;
            reserve1 = newReserve1;

            Token1.transfer(msg.sender, amount_out);  // Interaction after state change
        }

        emit Swap(msg.sender, tokenIN, _amount, tokenOUT, amount_out);
        return amount_out;
    }

    function getPrice(uint256 inputAmount, address tokenIn) external view returns (uint256 outputAmount) {
        uint256 k = reserve1 * reserve2;
        if (tokenIn == address(Token1)) {
            uint256 newReserve1 = reserve1 + inputAmount;
            uint256 newReserve2 = k / newReserve1;
            outputAmount = reserve2 - newReserve2;
        } else {
            uint256 newReserve2 = reserve2 + inputAmount;
            uint256 newReserve1 = k / newReserve2;
            outputAmount = reserve1 - newReserve1;
        }
    }
}
