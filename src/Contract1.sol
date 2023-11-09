// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Token with banable addresses
contract Contract1 is ERC20, Ownable {
    // Mapping to keep track of banned addresses
    mapping(address => bool) public banned;

    event addressBanned(address indexed banned);
    event addressUnbanned(address indexed unbanned);

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals()))); // Mint some tokens to the deploying address
    }

    // Function to ban an address
    function banAddress(address _address) public onlyOwner {
        require(!banned[_address], "Address is already banned");
        banned[_address] = true;

        emit addressBanned(_address);
    }

    // Function to unban an address
    function unbanAddress(address _address) public onlyOwner {
        require(banned[_address], "Address is not banned");
        banned[_address] = false;

        emit addressUnbanned(_address);
    }

    // Override the transfer function to check for banned addresses
    function bannableTransfer(
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        require(!banned[msg.sender], "Sender address is banned");
        require(!banned[recipient], "Recipient address is banned");
        return super.transfer(recipient, amount);
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
