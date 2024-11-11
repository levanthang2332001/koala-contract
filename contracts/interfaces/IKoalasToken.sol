// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKoalasToken is IERC721 {
    event Mint(address indexed to, uint256 amount);
    event WhitelistMint(address indexed to, uint256 amount);

    function baseURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mint(uint256 _mintAmount) external payable;

    function whitelistMint(uint256 _mintAmount) external payable;

    function pauseMinting() external;

    function totalMinted() external view returns (uint256);

    function reveal() external;

    function setBaseURI(string memory _newBaseURI) external;

    function setNotRevealedURI(string memory _notRevealedURI) external;

    function setCost(uint256 _newCost) external;

    function setMaxMintAmount(uint256 _newMaxMintAmount) external;

    function togglePublicMint() external;

    function toggleWhitelistMint() external;

    function addToWhitelist(address[] calldata addresses) external;

    function withdraw() external;
}
