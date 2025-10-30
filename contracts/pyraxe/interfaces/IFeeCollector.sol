// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

/**
 * @title IFeeCollector
 * @notice Interface for the FeeCollector contract
 * @dev Defines the interface for collecting protocol fees and managing withdrawals
 * @author Pyraxe Protocol
 */
interface IFeeCollector {
  // ============ Custom Errors ============
  error CallerNotWithdrawRole();
  error CallerNotGuardianRole();
  error CallerNotAdminRole();
  error InvalidRequest();
  error CooldownNotPassed();
  error AdminCannotBeZeroAddress();
  error GuardianCannotBeZeroAddress();
  error WithdrawerCannotBeZeroAddress();
  error TokenCannotBeZeroAddress();
  error AmountMustBeGreaterThanZero();
  error RecipientCannotBeZeroAddress();
  error InsufficientBalance();

  // ============ Events ============
  event WithdrawalRequested(
    uint256 indexed requestId,
    address indexed token,
    address indexed recipient,
    uint256 amount,
    uint256 requestTime
  );

  event WithdrawalClaimed(
    uint256 indexed requestId,
    address indexed token,
    address indexed recipient,
    uint256 amount
  );

  event WithdrawalRejected(
    uint256 indexed requestId,
    address indexed token,
    address indexed recipient,
    uint256 amount
  );

  // ============ Structs ============
  struct WithdrawalRequest {
    uint256 amount;
    address token;
    address recipient;
    uint256 requestTime;
    bool isActive;
  }

  // ============ Functions ============
  function requestWithdraw(
    uint256 amount,
    address token,
    address recipient
  ) external returns (uint256 requestId);

  function claimWithdraw(uint256 requestId) external;

  function rejectRequest(uint256 requestId) external;

  function getWithdrawalRequest(uint256 requestId) external view returns (WithdrawalRequest memory);

  function getWithdrawalRequestsLength() external view returns (uint256);
}
