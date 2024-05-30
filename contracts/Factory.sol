// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ICreatorGroup.sol";
import "./interfaces/IContentNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


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
    IERC20 public immutable USDC_token;
    address[] public agencies; // Array to store addresses of agencies associated with the contract
    // Events
    event GroupCreated(
        address indexed creator,
        string name,
        string description,
        address newDeployedAddress
    );
    event NewNFTMinted(address indexed creator, address indexed nftAddress);
    event WithdrawalFromDevelopmentTeam(address indexed withdrawer, uint256 indexed amount);
        // Modifier to restrict access to only the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    modifier onlyGroup() {
        bool flg = false;
        for(uint256 i = 0; i < numberOfCreators; i++) {
            if (msg.sender == Creators[i]) {
                flg = true; break;
            }
        }
        require(flg == true, "Only group can call this function");
        _;
    }
    // Constructor to initialize contract variables
    constructor(
        address _implementGroup,
        address _implementContent,
        address _marketplace,
        address _developmentTeam,
        uint256 _mintFee,
        uint256 _burnFee,
        address _USDC
    ) {
        owner = msg.sender;
        marketplace = _marketplace;
        developmentTeam = _developmentTeam;
        numberOfCreators = 0;
        mintFee = _mintFee;
        burnFee = _burnFee;
        implementGroup = _implementGroup;
        implementContent = _implementContent;
        USDC = _USDC;
        USDC_token = IERC20(_USDC);
    }

    // Function to create a new group
    function createGroup(
        string memory name,
        string memory description,
        address[] memory owners,
        uint256 numConfirmationRequired
    ) external {
        require(owners.length > 0, "At least one owner is required");
        address newDeployedAddress = Clones.clone(implementGroup);
        ICreatorGroup(newDeployedAddress).initialize(
            name,
            description,
            owners,
            numConfirmationRequired,
            marketplace,
            mintFee,
            burnFee,
            USDC
        );
        Creators.push(newDeployedAddress);
        numberOfCreators = Creators.length;
        emit GroupCreated(msg.sender, name, description, newDeployedAddress);
    }

    // Function to mint a new NFT
    function mintNew(
        string memory _nftURI,
        string memory _name,
        string memory _symbol,
        string memory _description
    ) external onlyGroup returns (address) {

        if(mintFee > 0) {
            SafeERC20.safeTransferFrom(USDC_token, msg.sender, address(this), mintFee);
        }
        address newDeployedAddress = Clones.clone(implementContent);
        IContentNFT(newDeployedAddress).initialize(
            _name,
            _symbol,
            _description,
            _nftURI,
            msg.sender,
            mintFee,
            burnFee,
            USDC,
            marketplace
        );
        emit NewNFTMinted(msg.sender, newDeployedAddress);
        return newDeployedAddress;
    }

    // Function to get the address of a creator group at a specific index
    function getCreatorGroupAddress(uint256 id) external view returns (address) {
        return Creators[id];
    }

    // Function for the development team to withdraw funds
    function withdraw() external {
        require(msg.sender == developmentTeam, "Invalid withdrawer");
        uint256 amount = IERC20(USDC).balanceOf(address(this));
        if(amount > 0) {
            SafeERC20.safeTransfer(USDC_token, msg.sender, amount) ;
        }
        emit WithdrawalFromDevelopmentTeam(msg.sender, amount);
    }

    function setTeamScoreForCreatorGroup(
        uint256 id,
        uint256 score
    ) external onlyOwner {
        ICreatorGroup(Creators[id]).setTeamScore(score);
    }
}
