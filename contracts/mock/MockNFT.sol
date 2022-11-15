// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MockNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("MetaLand Mock", "MLM") {}

    function mint(address to) public {
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _mint(to, tokenId);
    }
}