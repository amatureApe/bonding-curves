// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EscrowService is ReentrancyGuard, Ownable {
    uint256 public constant RECOVERY_PERIOD = 30 days;

    struct EscrowData {
        address tokenAddress;
        address seller; // Address of the seller
        uint256 amount;
        uint256 withdrawalTime;
    }

    // A mapping of buyer to their escrow count
    mapping(address => uint256) private escrowCounters;

    // A mapping of buyer to escrow IDs to escrow data
    mapping(address => mapping(uint256 => EscrowData)) public escrows;

    // Event logs
    event EscrowCreated(
        address indexed buyer,
        address indexed seller,
        uint256 indexed escrowId,
        address tokenAddress,
        uint256 amount,
        uint256 withdrawalTime
    );
    event WithdrawalConfirmed(
        address indexed seller,
        uint256 indexed escrowId,
        uint256 amountReceived
    );
    event EscrowRecovered(
        address indexed owner,
        address indexed buyer,
        address indexed seller,
        uint256 escrowId,
        uint256 amount
    );

    // Custom errors
    error TransferFailed();
    error TokensStillLocked();
    error NoTokensToWithdraw();
    error RecoveryPeriodNotReached();
    error InsufficientTokensInEscrow();
    error Unauthorized();

    // Modifier to check that the caller is the seller for a given escrow
    modifier onlySeller(address buyer, uint256 escrowId) {
        if (escrows[buyer][escrowId].seller != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    // Creating an escrow entry by the buyer for the seller
    function createEscrow(
        address seller,
        address tokenAddress,
        uint256 amount,
        uint256 withdrawalDelay
    ) external nonReentrant {
        uint256 escrowId = escrowCounters[msg.sender]++;

        IERC20 token = IERC20(tokenAddress);
        uint256 preBalance = token.balanceOf(address(this));
        // Attempt to transfer tokens to the escrow contract from the buyer
        if (!token.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }
        uint256 postBalance = token.balanceOf(address(this));
        uint256 actualAmount = postBalance - preBalance;

        // Store the actual amount received after fees (if any)
        EscrowData storage escrow = escrows[msg.sender][escrowId];
        escrow.tokenAddress = tokenAddress;
        escrow.seller = seller; // Set the seller for this escrow
        escrow.amount = actualAmount;
        escrow.withdrawalTime = block.timestamp + withdrawalDelay;

        emit EscrowCreated(
            msg.sender,
            seller,
            escrowId,
            tokenAddress,
            actualAmount,
            escrow.withdrawalTime
        );
    }

    // Sellers withdraw the funds after the withdrawal time has passed
    function withdrawFunds(
        address buyer,
        uint256 escrowId
    ) external nonReentrant onlySeller(buyer, escrowId) {
        EscrowData storage escrow = escrows[buyer][escrowId];
        if (block.timestamp < escrow.withdrawalTime) {
            revert TokensStillLocked();
        }
        if (escrow.amount == 0) {
            revert NoTokensToWithdraw();
        }

        IERC20 token = IERC20(escrow.tokenAddress);
        // Attempt to transfer the tokens to the seller
        if (!token.transfer(msg.sender, escrow.amount)) {
            revert TransferFailed();
        }

        // Emit the event before deleting to provide a record in the logs
        emit WithdrawalConfirmed(msg.sender, escrowId, escrow.amount);

        // Clear the escrow once funds are successfully withdrawn
        delete escrows[buyer][escrowId];
    }

    function recoverTokens(address buyer, uint256 escrowId) external onlyOwner {
        EscrowData storage escrow = escrows[buyer][escrowId];

        // Ensure the recovery period has passed
        if (block.timestamp < escrow.withdrawalTime + RECOVERY_PERIOD) {
            revert RecoveryPeriodNotReached();
        }

        uint256 amountToRecover = escrow.amount;
        if (amountToRecover == 0) {
            revert NoTokensToWithdraw();
        }

        IERC20 token = IERC20(escrow.tokenAddress);
        // Attempt to transfer the tokens to the owner
        if (!token.transfer(owner(), amountToRecover)) {
            revert TransferFailed();
        }

        // Emit the event before deleting to provide a record in the logs
        emit EscrowRecovered(
            owner(),
            buyer,
            escrow.seller,
            escrowId,
            amountToRecover
        );

        // Clear the escrow once funds are successfully recovered
        delete escrows[buyer][escrowId];
    }
}
