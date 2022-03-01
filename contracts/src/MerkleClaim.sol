// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// ============ Imports ============

import { MerkleProof } from "@openzeppelin/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof
//import { MerkleProof } from "./MerkleProof.sol"; // OZ: MerkleProof

interface IERC20 {
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount ) external returns (bool);
}

/// @title MerkleClaim
/// @notice Allows a held ERC20 to be claimable by members of a merkle tree
/// @author Anish Agnihotri <contact@anishagnihotri.com>
/// @author Jack Corddry https://github.com/corddry
contract MerkleClaim {

  /// ============ Immutable storage ============

  /// @notice ERC20-claimee inclusion root
  bytes32 public immutable merkleRoot;

  /// @notice Contract address of airdropped token
  IERC20 public immutable token;

  /// ============ Mutable storage ============

  /// @notice Mapping of addresses who have claimed tokens
  mapping(address => bool) public hasClaimed;

  /// ============ Errors ============

  /// @notice Thrown if address has already claimed
  error AlreadyClaimed();
  /// @notice Thrown if address/amount are not part of Merkle tree
  error NotInMerkle();
  /// @notice Thrown if claim contract doesn't have enough tokens to payout
  error notEnoughRewards();

  /// ============ Constructor ============

  /// @notice Creates a new MerkleClaimERC20 contract
  /// @param _erc20Address of token to be airdropped
  /// @param _merkleRoot of claimees
  constructor(
    address _erc20Address,
    bytes32 _merkleRoot
  ) {
    merkleRoot = _merkleRoot; // Update root
    token = IERC20(_erc20Address);
  }

  /// ============ Events ============

  /// @notice Emitted after a successful token claim
  /// @param to recipient of claim
  /// @param amount of tokens claimed
  event Claim(address indexed to, uint256 amount);

  /// ============ Functions ============

  /// @notice Allows claiming tokens if address is part of merkle tree
  /// @param to address of claimee
  /// @param amount of tokens owed to claimee
  /// @param proof merkle proof to prove address and amount are in tree
  function claim(address to, uint256 amount, bytes32[] calldata proof) external {
    // Throw if address has already claimed tokens
    if (hasClaimed[to]) revert AlreadyClaimed();

    // Verify merkle proof, or revert if not in tree
    bytes32 leaf = keccak256(abi.encodePacked(to, amount));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
    if (!isValidLeaf) revert NotInMerkle();

    // Throw if the contract doesn't hold enough tokens for claimee
    if (amount > token.balanceOf(address(this))) revert notEnoughRewards();

    // Set address to claimed
    hasClaimed[to] = true;

    // Award tokens to address
    token.transfer(msg.sender, amount);

    // Emit claim event
    emit Claim(to, amount);
  }
}

