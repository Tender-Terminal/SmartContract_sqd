// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ICreatorGroup.sol";
import "./interfaces/IContentNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Factory {
    // State variables
    address public owner; // Address of the contract owner
    address public developmentTeam; // Address of the development team associated with the contract
    address public marketplace; // Address of the marketplace contract
    uint256 public numberOfCreators; // Number of creators associated with the contract
    address[] public Creators; // Array to store addresses of creators
    address public implementGroup; // Address of the implementation contract for creating groups
    address public implementContent; // Address of the implementation contract for creating content
    uint256 public mintFee; // Fee required for minting NFTs
    uint256 public burnFee; // Fee required for burning NFTs
    address public USDC; // Address of the USDC token contract
    mapping(address => uint256) public agencyRevenuePercent; // Mapping to store agency revenue percentage for each agency address
    address[] public agencies; // Array to store addresses of agencies associated with the contract

    // Modifier to restrict access to only the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Events
    event GroupCreated(address indexed creator, string name, string description);
    event NFTMinted(address indexed creator, address indexed nftAddress);
    event AgencyAdded(address indexed agency, uint256 percent);
    event Withdrawal(address indexed withdrawer, uint256 amount);

    // Constructor to initialize contract variables
    constructor(address _implementGroup, address _implementContent, address _marketplace, address _developmentTeam, uint256 _mintFee, uint256 _burnFee, address _USDC) {
        owner = msg.sender;
        marketplace = _marketplace;
        developmentTeam = _developmentTeam;
        numberOfCreators = 0;
        mintFee = _mintFee; 
        burnFee = _burnFee;
        implementGroup = _implementGroup;
        implementContent = _implementContent;
        USDC = _USDC;
    }

    // Function to create a new group
    function createGroup(string memory name, string memory description, address[] memory owners, uint256[] memory roles, uint256 numConfirmationRequired) external {
        require(owners.length > 0, "At least one owner is required");
        address newDeployedAddress = Clones.clone(implementGroup);
        ICreatorGroup(newDeployedAddress).initialize(name, description, owners, roles, numConfirmationRequired, marketplace, mintFee, burnFee, USDC);
        Creators.push(newDeployedAddress);
        numberOfCreators = Creators.length;
        emit GroupCreated(msg.sender, name, description);
    }

    // Function to mint a new NFT
    function mintNew(string memory _nftURI, string memory _name, string memory _symbol, string memory _description, uint256 _loyaltyFee) public returns(address) {
        IERC20(USDC).transferFrom(msg.sender, address(this), mintFee);
        address newDeployedAddress = Clones.clone(implementContent);
        IContentNFT(newDeployedAddress).initialize(_name, _symbol, _description, _nftURI, msg.sender, mintFee, burnFee, _loyaltyFee, USDC);
        emit NFTMinted(msg.sender, newDeployedAddress);
        return newDeployedAddress ;
    }

    // Function to get agency revenue percentage
    function getAgencyRevenuePercent(address _agency) public view returns(uint256){
        return agencyRevenuePercent[_agency];
    }

    // Function to add an agency
    function addAgency(uint256 percent) public {
        agencies.push(msg.sender);
        agencyRevenuePercent[msg.sender] = percent;
        emit AgencyAdded(msg.sender, percent);
    }

    // Function to check if an address is in agencies
    function isInAgencies(address _agency) public view returns(bool) {
        for(uint256 i = 0; i < agencies.length; i++) {
            if(agencies[i] == _agency) return true;
        }
        return false;
    }

    // Function to get the address of a creator group at a specific index
    function getCreatorGroupAddress(uint256 id) public view returns(address) {
        return Creators[id];
    }

    // Function for the development team to withdraw funds
    function withdraw() public {
        require(msg.sender == developmentTeam, "Invalid withdrawer");
        uint256 amount = IERC20(USDC).balanceOf(address(this));
        IERC20(USDC).approve(address(this), amount);
        IERC20(USDC).transferFrom(address(this), msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }
}
