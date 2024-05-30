// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICreatorGroup} from "./interfaces/ICreatorGroup.sol";

contract ContentNFT is ERC721Upgradeable {
    // Struct to store transfer details
    struct TransferHistory {
        address from;
        address to;
        uint256 timestamp;
    }
    // State variables
    address public owner; // Address of the contract owner
    address public factory; // Address of the factory contract
    mapping(uint256 => string) private nftURIPath; // Mapping to store NFT URI paths
    string public description; // Description of the NFT contract
    uint256 public tokenNumber; // Current token number
    uint256 public mintFee; // Fee required for minting
    uint256 public burnFee; // Fee required for burning
    address public USDC; // USDC address
    address public marketplace; // Marketplace address
    IERC20 public USDC_token;  // USDC token contract
    mapping(uint256 => address) public creators; // Mapping to store the creator address for each NFT token ID
    mapping(uint256 => uint256) private loyaltyFee; // Mapping to store the loyalty fee percentage for each NFT token ID
    mapping(uint256 => TransferHistory[]) public transferHistory; // Mapping to store transfer history
    // Events
    event minted(
        address indexed from,
        uint256 indexed tokenId,
        string indexed nftURI
    );
    event burned(address indexed from, uint256 indexed tokenId);
    event LoyaltyFeeChanged(uint256 indexed tokenId, uint256 indexed newFee);

    /// @notice Function to initialize the NFT contract
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _nftURI,
        address _target,
        uint256 _mintFee,
        uint256 _burnFee,
        address _USDC,
        address _marketplace
    ) public initializer {
        // Initialize ERC721 contract
        ERC721Upgradeable.__ERC721_init(_name, _symbol);
        factory = msg.sender;
        require(_target != address(0), "target address cannot be 0");
        owner = _target;
        description = _description;
        tokenNumber = 1;
        _mint(owner, tokenNumber);
        creators[tokenNumber] = owner;
        mintFee = _mintFee;
        burnFee = _burnFee;
        transferHistory[tokenNumber].push(
            TransferHistory(address(0), owner, block.timestamp)
        );
        _setTokenURI(_nftURI);
        require(_USDC!=address(0), "USDC address cannot be 0");
        USDC = _USDC;
        USDC_token = IERC20(_USDC);
        require(_marketplace!=address(0),"marketplace address cannot be 0");
        marketplace = _marketplace;
        emit minted(owner, 0, _nftURI);
    }

    /// @notice Function to mint a new NFT token
    /// @param _nftURI URI of the NFT token
    /// @return tokenNumber
    function mint(string memory _nftURI) public payable returns (uint256) {
        // Mint the NFT token
        if (mintFee > 0)
            SafeERC20.safeTransferFrom(
                USDC_token,
                msg.sender,
                factory,
                mintFee
            );
        _mint(msg.sender, tokenNumber);
        creators[tokenNumber] = msg.sender;
        transferHistory[tokenNumber].push(
            TransferHistory(address(0), msg.sender, block.timestamp)
        );
        _setTokenURI(_nftURI);
        emit minted(msg.sender, tokenNumber - 1, _nftURI);
        return tokenNumber - 1;
    }

    /// @notice Function to burn an NFT token
    /// @param _tokenId Token ID of the NFT token
    /// @return Burned tokenId
    function burn(uint256 _tokenId) public payable returns (uint256) {
        // Burn the NFT token
        if (burnFee > 0)
            SafeERC20.safeTransferFrom(
                USDC_token,
                msg.sender,
                factory,
                burnFee
            );
        require(msg.sender == ownerOf(_tokenId), "only owner can burn");
        _burn(_tokenId);
        emit burned(msg.sender, _tokenId);
        return _tokenId;
    }

    /// @notice Function to set the token URI path
    /// @param _nftURI URI of the NFT token
    function _setTokenURI(string memory _nftURI) private {
        nftURIPath[tokenNumber] = _nftURI;
        tokenNumber++;
    }

    // Function to get the token URI for a given token ID
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return nftURIPath[_tokenId];
    }
    /// @notice Function to set LoyaltyFee to a given token ID
    /// @param _tokenId Token ID of the NFT token
    /// @param _loyaltyFee Loyalty Fee percentage
    function setLoyaltyFee(uint256 _tokenId, uint256 _loyaltyFee) public {
        require(
            msg.sender == marketplace,
            "Only Marketplace can set Loyalty Fee."
        );
        loyaltyFee[_tokenId] = _loyaltyFee;
        emit LoyaltyFeeChanged(_tokenId, _loyaltyFee);
    }
    /// @notice Function to handle NFT transfers and record transfer history
    /// @param _from Previous owner of the NFT
    /// @param _to New owner of the NFT
    /// @param _tokenId Token ID of the NFT token
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        super.transferFrom(_from, _to, _tokenId);
        if (transferHistory[_tokenId].length > 1) {
            ICreatorGroup(creators[_tokenId]).alarmLoyaltyFeeReceived(
                _tokenId,
                loyaltyFee[_tokenId]
            );
            if (loyaltyFee[_tokenId] > 0)
                SafeERC20.safeTransferFrom(
                    USDC_token,
                    msg.sender,
                    creators[_tokenId],
                    loyaltyFee[_tokenId]
                );
        }
        transferHistory[_tokenId].push(
            TransferHistory(_from, _to, block.timestamp)
        );
    }

    // Function to get the transfer history for a given token ID
    function getTransferHistory(
        uint256 _tokenId
    ) public view returns (TransferHistory[] memory) {
        return transferHistory[_tokenId];
    }

    // Function to get the loyalty fee for a given token ID
    function getLoyaltyFee(uint256 _tokenId) public view returns (uint256) {
        return loyaltyFee[_tokenId];
    }
}
