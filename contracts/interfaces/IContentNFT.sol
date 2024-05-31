// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IContentNFT {
    struct TransferHistory {
        address from;
        address to;
        uint256 timestamp;
    }
    function owner() external view returns (address);
    function ownerOf(uint256 tokenId) external view returns (address);
    function factory() external view returns (address);
    function description() external view returns (string memory);
    function tokenNumber() external view returns (uint256);
    function mintFee() external view returns (uint256);
    function burnFee() external view returns (uint256);
    function creators(uint256) external view returns (address);
    function initialize(string memory _name, string memory _symbol, string memory _description, string memory _nftURI,
        address _target, uint256 _mintFee, uint256 _burnFee, address _USDC, address _marketplace) external;
    function mint(string memory _nftURI) external payable returns (uint256);
    function burn(uint256 tokenId) external payable returns (uint256);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function getTransferHistory(uint256 tokenId) external view returns (TransferHistory[] memory);
    function getLoyaltyFee(uint256 tokenId) external view returns (uint256);
    function setLoyaltyFee(uint256 _tokenId, uint256 _loyaltyFee) external;
}