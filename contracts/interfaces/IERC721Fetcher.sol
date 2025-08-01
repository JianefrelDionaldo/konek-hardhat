// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IERC721Fetcher {
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);
}
