// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Token with banable addresses
contract Contract1 is ERC20, Ownable {
    // Mapping to keep track of banned addresses
    mapping(address => bool) public banned;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals()))); // Mint some tokens to the deploying address
    }

    // Function to ban an address
    function banAddress(address _address) public onlyOwner {
        require(!banned[_address], "Address is already banned");
        banned[_address] = true;
    }

    // Function to unban an address
    function unbanAddress(address _address) public onlyOwner {
        require(banned[_address], "Address is not banned");
        banned[_address] = false;
    }

    // Override the transfer function to check for banned addresses
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(!banned[sender], "Sender address is banned");
        require(!banned[recipient], "Recipient address is banned");
        super._transfer(sender, recipient, amount);
    }

    // Optionally, override the `transferFrom` function if you want to apply bans to `transferFrom` operations as well
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!banned[sender], "Sender address is banned");
        require(!banned[recipient], "Recipient address is banned");
        return super.transferFrom(sender, recipient, amount);
    }
}
