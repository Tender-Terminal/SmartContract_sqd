// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICreatorGroup {
    struct soldInfor{
        uint256 id ;
        uint256 price ;
        bool distributeState ;
    }
    function initialize(string memory _name, string memory _description, address[] memory _members,  
        uint256 _numConfirmationRequired, address _marketplace, uint256 _mintFee, uint256 _burnFee, address _USDC) external;
    
    function addAgency(address _agency) external;

    function removeAgency() external;
    
    function setTeamScore(uint256 value) external;
    
    function alarmSoldOut(address contractAddress, uint256 nftId, uint256 price) external;
    
    function mintNew(string memory _nftURI, string memory _name, string memory _symbol, string memory _description) external;
    
    function mint(string memory _nftURI, address _targetNFT) external;
    
    function listToEnglishAuction(uint256 id, uint256 initialPrice, uint256 salePeriod) external;
    
    function listToDutchAuction(uint256 id, uint256 initialPrice, uint256 reducingRate, uint256 salePeriod) external;
    
    function listToOfferingSale(uint256 id, uint256 initialPrice) external;
    
    function endEnglishAuction(uint256 id) external;
    
    function withdrawFromMarketplace() external;
    
    function submitDirectorSettingTransaction(address _candidate) external;
    
    function confirmDirectorSettingTransaction(uint256 index, bool state) external;
    
    function excuteDirectorSettingTransaction(uint256 index) external;
    
    function submitOfferingSaleTransaction(uint256 _marketId, address _tokenContractAddress, uint256 tokenId, address _buyer, uint256 _price) external;
    
    function confirmOfferingSaleTransaction(uint256 index, bool state) external;
    
    function excuteOfferingSaleTransaction(uint256 index) external;
    
    function setConfirmationRequiredNumber(uint256 confirmNumber) external;

    function getNftOfId(uint256 index) external view returns (uint256);

    function getNftAddress(uint256 index) external view returns (address);

    function getSoldNumber() external view returns(uint256) ;

    function getRevenueDistribution(address one, uint256 id) external view returns (uint256) ;

    function getSoldInfor(uint256 index) external view returns (soldInfor memory);

    function withdraw() external  ;
    
    function addMember(address _newMember) external ;

    function removeMember(address _removeMember) external ;

    function alarmLoyaltyFeeReceived(uint256 nftId, uint256 price) external ;

    function getNumberOfCandidateTransaction() external view returns(uint256) ;

    function getNumberOfSaleOfferingTransaction() external view returns(uint256)  ;

    function getConfirmNumberOfOfferingSaleTransaction(uint256 index) external view returns(uint256) ;

    function getConfirmNumberOfDirectorSettingTransaction(uint256 index) external view returns(uint256) ;
    function submitBurnTransaction(uint256 id) external;
    function confirmBurnTransaction(uint256 index, bool state) external;
    function excuteBurnTransaction(uint256 index) external;
    function getConfirmNumberOfBurnTransaction(uint256 index) external view returns (uint256);
    function getNumberOfBurnTransaction() external view returns(uint256) ;
}