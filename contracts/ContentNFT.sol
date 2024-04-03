// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ContentNFT is ERC721Upgradeable {
    // State variables
    address public owner; // Address of the contract owner
    address public factory; // Address of the factory contract
    mapping(uint256 => string) public nftURIPath; // Mapping to store NFT URI paths
    string public description; // Description of the NFT contract
    uint256 public tokenNumber; // Current token number
    uint256 public mintFee; // Fee required for minting
    uint256 public burnFee; // Fee required for burning
    address public USDC ;

    // Mapping to store the creator address for each NFT token ID
    mapping(uint256 => address) public creators;

    // Mapping to store the loyalty fee percentage for each NFT token ID
    mapping(uint256 => uint256) public loyaltyFee;

    // Struct to store transfer details
    struct TransferHistory {
        address from;
        address to;
        uint256 timestamp;
    }
    mapping(uint256 => TransferHistory[]) public transferHistory; // Mapping to store transfer history

    // Events
    event minted(address from, uint256 tokenId, string nftURI, uint256 loyaltyFee);
    event burned(address from, uint256 tokenId);

    // Function to initialize the NFT contract
    function initialize(string memory _name, string memory _symbol, string memory _description, string memory _nftURI, address _target, uint256 _mintFee, uint256 _burnFee, uint256 _loyaltyFee, address _USDC) initializer public {
        // Initialize ERC721 contract
        ERC721Upgradeable.__ERC721_init(_name, _symbol);
        factory = msg.sender;
        owner = _target;
        description = _description;
        tokenNumber = 1;
        _mint(owner, tokenNumber);
        creators[tokenNumber] = owner;
        loyaltyFee[tokenNumber] = _loyaltyFee;
        mintFee = _mintFee;
        burnFee = _burnFee;
        setTokenURI(_nftURI);
        USDC = _USDC ;
        emit minted(owner, 0, _nftURI, _loyaltyFee);
    }

    // Function to mint a new NFT token
    function mint(string memory _nftURI, uint256 _loyaltyFee) payable public returns(uint256) {
        // Mint the NFT token
        IERC20(USDC).transferFrom(msg.sender, factory, mintFee);
        _mint(msg.sender, tokenNumber);
        creators[tokenNumber] = msg.sender;
        transferHistory[tokenNumber].push(TransferHistory(address(0), msg.sender, block.timestamp));
        loyaltyFee[tokenNumber] = _loyaltyFee;
        setTokenURI(_nftURI);
        emit minted(msg.sender, tokenNumber - 1, _nftURI, _loyaltyFee);
        return tokenNumber - 1 ;
    }

    // Function to burn an NFT token
    function burn(uint256 tokenId) payable public returns(uint256) {
        // Burn the NFT token
        IERC20(USDC).transferFrom(msg.sender, factory, burnFee);        
        _burn(tokenId);  
        emit burned(msg.sender, tokenId);
        return tokenId;
    }

    // Function to set the token URI path
    function setTokenURI(string memory _nftURI) private {
        nftURIPath[tokenNumber] = _nftURI;
        tokenNumber++;
    }

    // Function to get the token URI for a given token ID
    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        return nftURIPath[_tokenId];
    }

    // Function to handle NFT transfers and record transfer history
    function transferFrom(address from, address to, uint256 tokenId) public override{
        super.transferFrom(from, to, tokenId);
        IERC20(USDC).transferFrom(msg.sender, creators[tokenId], loyaltyFee[tokenId]);
        transferHistory[tokenId].push(TransferHistory(from, to, block.timestamp));
    }
    
    // Function to get the transfer history for a given token ID
    function getTransferHistory(uint256 tokenId) public view returns (TransferHistory[] memory) {
        return transferHistory[tokenId];
    }

    // Function to get the loyalty fee for a given token ID
    function getLoyaltyFee(uint256 tokenId) public view returns (uint256) {
        return loyaltyFee[tokenId];
    }
}
