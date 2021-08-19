// SPDX-License-Identifier: MIT

/*
<Insert ASCII Art Here>

imnotArt Access
*/

pragma solidity ^0.8.4;

interface BaseERC721Interface {
    function ownerOf(uint256 tokenId) external returns (address);
}