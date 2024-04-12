// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IFactory {
    function createGroup(string memory name, string memory description, address[] memory owners, uint256[] memory roles, uint256 numConfirmationRequired) external;
    
    function mintNew(string memory _nftURI, string memory _name, string memory _symbol, string memory _description) external returns (address);
    
    function getAgencyRevenuePercent(address _agency) external view returns (uint256);
    
    function addAgency(uint256 percent) external;
    function getCreatorGroupAddress(uint256 id) external view returns(address);
    function isInAgencies(address _agency) external view returns(bool) ;
    function withdraw() external;
    function setTeamScoreForCreatorGroup(uint256 id, uint256 score) external ;
}