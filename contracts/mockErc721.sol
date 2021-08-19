// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract mockErc721 is Ownable, ERC721Enumerable {
    using SafeMath for uint256;

    // ---
    // Properties
    // ---
    uint256 public nextTokenId = 1;

    // ---
    // Security
    // ---
    mapping(address => bool) private _isAdmin;

    modifier onlyAdmin() {
        require(_isAdmin[msg.sender], "Only admins.");
        _;
    }

    // ---
    // Constructor
    // ---
    constructor() ERC721("mockErc721 Contract", "MOCK") {
        _isAdmin[msg.sender] = true;
    }

    // ---
    // Minting
    // ---
    function mint() public onlyAdmin returns (uint256 tokenId) {
        tokenId = nextTokenId;
        nextTokenId = nextTokenId.add(1);

        _mint(msg.sender, tokenId);
    }
}