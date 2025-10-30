// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {TransferHelper} from '../libraries/TransferHelper.sol';
import {IFeeCollector} from '../interfaces/IFeeCollector.sol';

/**
 * @title FeeCollector
 * @notice Collects protocol fees and manages withdrawals through a multisig-controlled system
 * @dev Implements a two-step withdrawal process with 24-hour cooldown and Guardian oversight
 * @author Pyraxe Protocol
 */
contract FeeCollector is AccessControl, IFeeCollector {
  // Role definitions
  bytes32 public constant GUARDIAN_ROLE = keccak256('GUARDIAN_ROLE');
  bytes32 public constant WITHDRAW_ROLE = keccak256('WITHDRAW_ROLE');

  // Constants
  uint256 public constant WITHDRAWAL_COOLDOWN = 24 hours;

  // State variables
  WithdrawalRequest[] public withdrawalRequests;

  // Modifiers
  modifier onlyRoleWithCustomError(bytes32 role) {
    if (!hasRole(role, msg.sender)) {
      if (role == WITHDRAW_ROLE) revert CallerNotWithdrawRole();
      if (role == GUARDIAN_ROLE) revert CallerNotGuardianRole();
      if (role == DEFAULT_ADMIN_ROLE) revert CallerNotAdminRole();
    }
    _;
  }

  modifier validRequest(uint256 requestId) {
    if (requestId >= withdrawalRequests.length || !withdrawalRequests[requestId].isActive) {
      revert InvalidRequest();
    }
    _;
  }

  modifier cooldownPassed(uint256 requestId) {
    if (block.timestamp < withdrawalRequests[requestId].requestTime + WITHDRAWAL_COOLDOWN) {
      revert CooldownNotPassed();
    }
    _;
  }

  /**
   * @dev Constructor sets up the initial roles
   * @param admin Address that will be granted admin role (typically multisig)
   * @param guardian Address that will be granted guardian role
   * @param withdrawer Address that will be granted withdraw role
   */
  constructor(address admin, address guardian, address withdrawer) {
    if (admin == address(0)) revert AdminCannotBeZeroAddress();
    if (guardian == address(0)) revert GuardianCannotBeZeroAddress();
    if (withdrawer == address(0)) revert WithdrawerCannotBeZeroAddress();

    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(GUARDIAN_ROLE, guardian);
    _setupRole(WITHDRAW_ROLE, withdrawer);
  }

  /**
   * @dev Requests a withdrawal of tokens
   * @param amount Amount of tokens to withdraw
   * @param token Address of the token to withdraw
   * @param recipient Address that will receive the tokens
   * @return requestId Unique identifier for the withdrawal request (array index)
   */
  function requestWithdraw(
    uint256 amount,
    address token,
    address recipient
  ) external onlyRoleWithCustomError(WITHDRAW_ROLE) returns (uint256 requestId) {
    if (amount == 0) revert AmountMustBeGreaterThanZero();
    if (token == address(0)) revert TokenCannotBeZeroAddress();
    if (recipient == address(0)) revert RecipientCannotBeZeroAddress();
    if (IERC20(token).balanceOf(address(this)) < amount) revert InsufficientBalance();

    // Create withdrawal request and push to array
    withdrawalRequests.push(
      WithdrawalRequest({
        amount: amount,
        token: token,
        recipient: recipient,
        requestTime: block.timestamp,
        isActive: true
      })
    );

    requestId = withdrawalRequests.length - 1;

    emit WithdrawalRequested(requestId, token, recipient, amount, block.timestamp);
  }

  /**
   * @dev Claims a withdrawal after the cooldown period
   * @param requestId Unique identifier for the withdrawal request (array index)
   */
  function claimWithdraw(
    uint256 requestId
  )
    external
    validRequest(requestId)
    cooldownPassed(requestId)
    onlyRoleWithCustomError(WITHDRAW_ROLE)
  {
    WithdrawalRequest storage request = withdrawalRequests[requestId];

    // Deactivate request
    request.isActive = false;

    // Transfer tokens
    TransferHelper.safeTransfer(request.token, request.recipient, request.amount);

    emit WithdrawalClaimed(requestId, request.token, request.recipient, request.amount);
  }

  /**
   * @dev Rejects a withdrawal request (Guardian only)
   * @param requestId Unique identifier for the withdrawal request (array index)
   */
  function rejectRequest(
    uint256 requestId
  ) external onlyRoleWithCustomError(GUARDIAN_ROLE) validRequest(requestId) {
    WithdrawalRequest storage request = withdrawalRequests[requestId];

    // Mark as inactive
    request.isActive = false;

    emit WithdrawalRejected(requestId, request.token, request.recipient, request.amount);
  }

  /**
   * @dev Gets withdrawal request details
   * @param requestId Unique identifier for the withdrawal request (array index)
   * @return request WithdrawalRequest struct containing all details
   */
  function getWithdrawalRequest(
    uint256 requestId
  ) external view returns (WithdrawalRequest memory request) {
    if (requestId >= withdrawalRequests.length) {
      revert InvalidRequest();
    }
    return withdrawalRequests[requestId];
  }

  /**
   * @dev Gets the total number of withdrawal requests
   * @return length Total number of withdrawal requests in the array
   */
  function getWithdrawalRequestsLength() external view returns (uint256 length) {
    return withdrawalRequests.length;
  }
}
