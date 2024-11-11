// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IKoalasToken } from "./interfaces/IKoalasToken.sol";

contract Koalas is IKoalasToken , ERC721, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    uint256 private _tokenIds;

    string public baseTokenURI;
    string public baseExtension = ".json";
    string public notRevealedURI;
    bool public revealed = false;


    // Minting Configuration
    uint256 public cost = 0.003 ether;
    uint256 public maxSupply = 500;
    uint256 public maxMintAmount = 2;
    bool public publicMintEnabled = false;
    
    // Whitelist Configuration
    mapping(address => bool) public whitelist;
    bool public whitelistMintEnabled = false;

    // Pause minting
    bool public mintPaused = false;
    
    // Metadata Storage
    mapping(uint256 => string) private _tokenURIs;

    mapping(address => uint256) private _totalMinted;

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedURI
    ) ERC721("Koalas", "KOALAS") Ownable(msg.sender) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedURI);
    }

    // Keep the internal _baseURI as is from ERC721
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function baseURI() external view override returns (string memory) {
        return baseTokenURI;
    }


    // Public/External View Functions
    function tokenURI(uint256 tokenId) 
        public 
        view  
        override(ERC721, IKoalasToken)
        returns (string memory) 
    {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        if(!revealed) {
            return notRevealedURI;
        }
        
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;   
        }
        
        return string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    function mint(uint256 _mintAmount) external payable nonReentrant {
        require(publicMintEnabled, "Public mint is not enabled");
        require(_mintAmount > 0, "Invalid mint amount");
        require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
        require(msg.value >= cost * _mintAmount, "Insufficient funds sent");
        require(_totalMinted[msg.sender] < 1, "Minted only 1 time");
        require(!mintPaused, "Minting is paused");
    

        _mintTokens(msg.sender,_mintAmount);
        _totalMinted[msg.sender]++;

        emit Mint(msg.sender, _mintAmount);
    }

    function _mintTokens(address _to, uint256 _mintAmount) private {
        uint256 supply = _tokenIds;
        require(supply + _mintAmount <= maxSupply, "Max supply exceeded");

        for (uint256 i = 0; i < _mintAmount; i++) {
            _tokenIds++;
            _safeMint(_to, _tokenIds);
        }
    }
    
    function whitelistMint(uint256 _mintAmount) external payable nonReentrant {
        require(whitelistMintEnabled, "Whitelist mint is not enabled");
        require(_mintAmount > 0, "Invalid mint amount");
        require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
        require(msg.value == 0, "Insufficient funds sent");
        require(whitelist[msg.sender], "You are not on the whitelist");
        require(_totalMinted[msg.sender] < 1, "Minted only 1 time");
        require(!mintPaused, "Minting is paused");

        _mintTokens(msg.sender, _mintAmount);
        _totalMinted[msg.sender]++;

        emit WhitelistMint(msg.sender, _mintAmount);
    }

    function pauseMinting() public onlyOwner {
        mintPaused = true;
    }

    function totalMinted() external view override returns (uint256) {
        return _tokenIds;
    }

     // Admin Functions
    function reveal() public onlyOwner {
        revealed = true;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }
    
    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }
    
    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }
    
    function togglePublicMint() external onlyOwner {
        publicMintEnabled = !publicMintEnabled;
    }
    
    function toggleWhitelistMint() external onlyOwner {
        whitelistMintEnabled = !whitelistMintEnabled;
    }
    
    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }
    
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }
}
