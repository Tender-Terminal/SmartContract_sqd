// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMarketplace {
    function getBalanceOfUser(address to) external view returns (uint256);
    
    function addBalanceOfUser(address[] memory _members, uint256[] memory _values, address contractAddress, uint256 nftId) external;
    
    function setDevelopmentTeam(address _developmentTeam) external;
    
    function setPercentForSeller(uint256 _percentForSeller) external;
    
    function withdraw() external ;
    
    function withdrawFromSeller() external;
    
    function listToEnglishAuction(address nftContractAddress, uint256 nftId, uint256 initialPrice, uint256 salePeriod) external;
    
    function listToDutchAuction(address nftContractAddress, uint256 nftId, uint256 initialPrice, uint256 reducingRate, uint256 salePeriod) external;
    
    function listToOfferingSale(address nftContractAddress, uint256 nftId, uint256 initialPrice) external;
    
    function makeBidToEnglishAuction(uint256 id, uint256 sendingValue) external;
    
    function withdrawFromEnglishAuction(uint256 id) external;
    
    function endEnglishAuction(address _contractAddress, uint256 _nftId) external;
    
    function buyDutchAuction(uint256 id, uint256 sendingValue) external ;
    
    function makeBidToOfferingSale(uint256 id, uint256 sendingValue) external ;
    
    function withdrawFromOfferingSale(uint256 id) external;
    
    function endOfferingSale(uint256 id, address buyer) external;
    
    function cancelListing(address _nftContractAddress, uint256 _nftId) external;
    
    function getDutchAuctionPrice(uint256 id) external view returns (uint256);

    function setPercentForLoyaltyFee(uint256 _percentForLoyaltyFee) external ;

    function getOfferingSaleAuctionNumber() external view returns(uint256)  ;

    function getListedDutchAuctionNumber() external view returns(uint256) ;

    function getListedEnglishAuctionNumber() external view returns(uint256) ;

    function getListedNumber() external view returns(uint256) ;

    function withdrawBalanceForEnglishAuction(uint256 id, address to) external view returns(uint256) ;

    function withdrawBalanceForOfferingSale(uint256 id, address to) external view returns(uint256) ;
}