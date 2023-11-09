// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ERC20 contract with linear bonding curve token sale.
contract Contract3 is ERC20, Ownable {
    uint256 private constant INITIAL_PRICE = 1e18; // 1 Token = 1 Ether
    uint256 private constant PRICE_INCREMENT = 1e16; // Price increases by 0.01 Ether for each token sold

    // Maximum allowed gas price for transactions. Not great for users during high
    // network usage, but will prevent sandwhich attacks.
    uint256 public maxGasPrice = 100 gwei;

    event TokensPurchased(address buyer, uint256 amount, uint256 totalCost);
    event TokensSold(address seller, uint256 amount, uint256 salePrice);

    // Constructor initializes the ERC20 token with a name and symbol
    constructor() ERC20("BondingCurveToken", "BCT") Ownable(msg.sender) {}

    // Function to receive Ether when msg.data is empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    // The current price of the token is based on the total supply
    function currentPrice() public view returns (uint256) {
        return INITIAL_PRICE + (totalSupply() * PRICE_INCREMENT);
    }

    // Anyone can buy tokens directly from the contract
    function buyTokens(uint256 numTokens) external payable {
        require(tx.gasprice <= maxGasPrice, "Gas price exceeds limit");

        uint256 totalPrice = numTokens * currentPrice();
        require(msg.value >= totalPrice, "Not enough ETH sent");

        _mint(msg.sender, numTokens);

        emit TokensPurchased(msg.sender, numTokens, totalPrice);

        // Refund excess ETH if the buyer sent too much
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    // Allow token holders to sell tokens back to the contract at the current price
    function sellTokens(uint256 numTokens) external {
        require(balanceOf(msg.sender) >= numTokens, "Not enough tokens owned");

        uint256 salePrice = numTokens * currentPrice();

        _burn(msg.sender, numTokens);

        emit TokensSold(msg.sender, numTokens, salePrice);

        payable(msg.sender).transfer(salePrice);
    }

    // Owner can update the maximum gas price
    function setMaxGasPrice(uint256 _maxGasPrice) external onlyOwner {
        maxGasPrice = _maxGasPrice;
    }
}
