// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    uint256 private _tokenIds;

    constructor() ERC721("MetaLand Mock", "MLM") {}

    function mint(address to) public {
        uint256 tokenId = _tokenIds;
        _tokenIds++;
        _mint(to, tokenId);
    }
}