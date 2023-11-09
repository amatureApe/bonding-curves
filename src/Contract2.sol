// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Token with God Mode special address
contract Contract2 is ERC20, Ownable {
    address private godModeAddress;

    event GodModeAddressChanged(
        address indexed previousGod,
        address indexed newGod
    );

    constructor(
        string memory name,
        string memory symbol,
        address _godModeAddress
    ) ERC20(name, symbol) Ownable(msg.sender) {
        require(
            _godModeAddress != address(0),
            "God Mode address cannot be the zero address"
        );
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals()))); // Initial supply to owner
        godModeAddress = _godModeAddress;
    }

    modifier onlyGod() {
        require(
            msg.sender == godModeAddress,
            "Caller is not the god mode address"
        );
        _;
    }

    function changeGodModeAddress(address _newGod) public onlyOwner {
        require(
            _newGod != address(0),
            "New God Mode address cannot be the zero address"
        );
        emit GodModeAddressChanged(godModeAddress, _newGod);
        godModeAddress = _newGod;
    }

    // Allow the god mode address to transfer tokens from any address to another
    function godTransfer(
        address from,
        address to,
        uint256 amount
    ) public onlyGod {
        _transfer(from, to, amount);
    }
}
