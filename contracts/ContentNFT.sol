// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICreatorGroup} from "./interfaces/ICreatorGroup.sol";

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
    address public marketplace ;

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
    event minted(address from, uint256 tokenId, string nftURI);
    event burned(address from, uint256 tokenId);
 
    // Function to initialize the NFT contract
    function initialize(string memory _name, string memory _symbol, string memory _description, 
        string memory _nftURI, address _target, uint256 _mintFee, uint256 _burnFee, address _USDC, address _marketplace) initializer public {
        // Initialize ERC721 contract
        ERC721Upgradeable.__ERC721_init(_name, _symbol);
        factory = msg.sender;
        owner = _target;
        description = _description;
        tokenNumber = 1;
        _mint(owner, tokenNumber);
        creators[tokenNumber] = owner;
        mintFee = _mintFee;
        burnFee = _burnFee;
        setTokenURI(_nftURI);
        USDC = _USDC ;
        marketplace = _marketplace ;
        emit minted(owner, 0, _nftURI);
    }

    // Function to mint a new NFT token
    function mint(string memory _nftURI) payable public returns(uint256) {
        // Mint the NFT token
        IERC20(USDC).transferFrom(msg.sender, factory, mintFee);
        _mint(msg.sender, tokenNumber);
        creators[tokenNumber] = msg.sender;
        transferHistory[tokenNumber].push(TransferHistory(address(0), msg.sender, block.timestamp));
        setTokenURI(_nftURI);
        emit minted(msg.sender, tokenNumber - 1, _nftURI);
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

    function setLoyaltyFee(uint256 _tokenId, uint256 _loyaltyFee) public {
        require(msg.sender == marketplace, "Only Marketplace can set Loyalty Fee.") ;
        loyaltyFee[_tokenId] = _loyaltyFee;
    }

    // Function to handle NFT transfers and record transfer history
    function transferFrom(address from, address to, uint256 tokenId) public override{
        super.transferFrom(from, to, tokenId);
        if(transferHistory[tokenId].length > 1){
            console.log("Here is ContentNFT") ;
            ICreatorGroup(creators[tokenId]).alarmLoyaltyFeeReceived(tokenId, loyaltyFee[tokenId]);
            IERC20(USDC).transferFrom(msg.sender, creators[tokenId], loyaltyFee[tokenId]);
        }    
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
