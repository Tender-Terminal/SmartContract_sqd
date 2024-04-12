// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/ICreatorGroup.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IMarketplace.sol";
import "./interfaces/IContentNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract CreatorGroup is Initializable, ICreatorGroup {
    // State variables
    address public USDC; // USDC token address
    string public name; // Name of the CreatorGroup
    string public description; // Description of the CreatorGroup
    uint256 public mintFee; // Fee for minting NFTs
    uint256 public burnFee; // Fee for burning NFTs
    uint256 public numberOfMembers; // Number of members in the group
    address[] public members; // Array to store member addresses
    mapping(address => address) public agency; // Array to store agency members
    mapping(address => uint256) public agencyPercentForRevenue; // Array to store agency percent for Revenue
    mapping(address => bool) public isHavingAgency; // Flag indicating if a member has an agency
    address public factory; // Address of the factory contract
    address public marketplace; // Address of the marketplace contract
    mapping(address => uint256) public balance; // Mapping to store balances of members
    mapping(address => bool) public isOwner; // Mapping to track ownership status of addresses
    mapping(address => bool) public isAgency; // Flag indicating if an address is an agency
    uint256 public numConfirmationRequired; // Number of confirmations required for transactions
    address public director; // Address of the director for certain functions
    mapping(address => mapping(uint256 => bool)) public transactionsConfirmState; // Mapping to track transaction confirmation state
    mapping(address => uint256) public memberFromNFTId;   // Mapping to track member from NFT id
    soldInfor[] public soldInformation;  // Array to store sold NFT information
    uint256 public currentDistributeNumber; // Current distribution number
    uint256 public teamScore; // Team score
    uint256 public totalEarning;

    uint256 public numberOfNFT; // Number of NFTs in the group
    mapping(uint256 => uint256) public nftIdArr; // Mapping of NFT IDs
    mapping(uint256 => address) public nftAddressArr; // Mapping of NFT addresses
    mapping(uint256 => bool) public listedState; // Mapping to track the listing state of NFTs
    mapping(uint256 => bool) public soldOutState; // Mapping to track the listing state of NFTs

    mapping(address => mapping(uint256 => uint256)) public revenueDistribution; // Mapping for revenue distribution of NFTs
    mapping(address => mapping(uint256 => uint256)) public getNFTId; // Mapping for getting NFT IDs
    
    // Struct for transaction candidates
    struct transaction_candidate {
        address candidate;
        bool endState;
    }
    transaction_candidate[] public transactions_candidate; // Array of transaction candidates
    
    mapping(address => mapping(uint256 => bool)) public confirmTransaction_Candidate; // Mapping for confirm transaction

    // Struct for offering transactions
    struct transaction_offering {
        uint256 marketId;
        uint256 id;
        address buyer;
        uint256 price;
        bool endState;
    }
    transaction_offering[] public transactions_offering; // Array of  offering transaction
    
    mapping(address => mapping(uint256 => bool)) public confirmTransaction_Offering; // Mapping for offering transaction confirmed state

    // Struct for offering transactions
    struct transaction_burn {
        uint256 id;
        bool endState;
    }
    transaction_burn[] public transactions_burn; // Array of  offering transaction
    
    mapping(address => mapping(uint256 => bool)) public confirmTransaction_Burn; // Mapping for offering transaction confirmed state


    struct record_member{
        address _member ;
        uint256 _percent ;
        uint256 _sum ;
    }
    mapping(uint256 => record_member[]) public Recording ;


    // Modifier to restrict access to only director
    modifier onlyDirector(){
        require(msg.sender == director, "Only delegated member can call this function");
        _;
    }

    // Modifier to restrict access to only members
    modifier onlyMembers(){
        require(isOwner[msg.sender] == true || isAgency[msg.sender] == true, "Only members can call this function");
        _;
    }
    
    // Modifier to restrict access to only marketplace contract
    modifier onlyMarketplace(){
        require(msg.sender == marketplace, "only Marketplace can Call this function.") ;
        _;
    }

    modifier onlyFactory(){
        require(msg.sender == factory, "Only factory can call this function.") ;
        _;
    }

    // events
    event AgencyAdded(address indexed member, address agency);
    event AgencyRemoved(address indexed member, address agency);
    event TeamScoreSet(uint256 value);
    event NFTMinted(address indexed nftAddress, uint256 indexed nftId);
    event NFTBurned(uint256 indexed nftId);
    event EnglishAuctionListed(uint256 indexed nftId, uint256 initialPrice, uint256 salePeriod);
    event DutchAuctionListed(uint256 indexed nftId, uint256 initialPrice, uint256 reducingRate, uint256 salePeriod);
    event OfferingSaleListed(uint256 indexed nftId, uint256 initialPrice);
    event EnglishAuctionEnded(uint256 indexed nftId);
    event WithdrawalFromMarketplace();
    event DirectorSettingProposed(address indexed _candidate);
    event DirectorSettingExecuted(address indexed _director);
    event DirectorSettingConfirmed(uint256 indexed index, address from, bool state);
    event OfferingSaleTransactionProposed(address indexed _tokenContractAddress, uint256 tokenId, address _buyer, uint256 _price);
    event OfferingSaleTransactionConfirmed(uint256 indexed index, address from, bool state) ;
    event OfferingSaleTransactionExecuted(uint256 indexed index) ;
    event ConfirmationRequiredNumberSet(uint256 indexed confirmNumber);
    event withdrawHappened(address indexed from, uint256 balanceToWithdraw) ;
    event LoyaltyFeeReceived(uint256 id, uint256 price) ;
    event BurnTransactionProposed(uint256 id);
    event BurnTransactionConfirmed(uint256 index, address from, bool state) ;

    // Function to initialize the CreatorGroup contract with member addresses and other parameters
    function initialize(string memory _name, string memory _description, address[] memory _members, 
        uint256 _numConfirmationRequired, address _marketplace, uint256 _mintFee, uint256 _burnFee, address _USDC) public initializer {
        name = _name;
        description = _description;
        for(uint256 i = 0; i < _members.length; i++){
            members.push(_members[i]);
            memberFromNFTId[_members[i]] = 0;
            isOwner[_members[i]] = true;
        }
        numberOfMembers = _members.length;
        numConfirmationRequired = _numConfirmationRequired;
        marketplace = _marketplace;
        mintFee = _mintFee;
        burnFee = _burnFee;
        factory = msg.sender;
        director = members[0];
        numberOfNFT = 0 ;
        currentDistributeNumber = 0 ;
        teamScore = 20 ;
        USDC = _USDC;
    }

    // Function to add a new member to the CreatorGroup
    function addMember(address _newMember) onlyDirector public{
        members.push(_newMember);
        isOwner[_newMember] = true;
        memberFromNFTId[_newMember] = numberOfNFT ;
        numberOfMembers ++ ;
    }

    // Function to remove a member from the CreatorGroup
    function removeMember(address _removeMember) onlyDirector public{
        require(isOwner[_removeMember] == true, "It's not a member!") ;
        delete isOwner[_removeMember];
        delete memberFromNFTId[_removeMember] ;
        uint256 id ;
        for(uint256 i = 0 ; i < members.length ; i ++){
            if(members[i] == _removeMember) id = i ;
        }
        members[id] = members[numberOfMembers-1] ;
        delete members[numberOfMembers-1] ;
        numberOfMembers -- ;
    }

    // Function to add an agency to a member
    function addAgency(address _agency) onlyMembers public{
        require(IFactory(factory).isInAgencies(_agency), "Invalid agency") ;
        agency[msg.sender] = _agency;
        isAgency[_agency] = true;
        agencyPercentForRevenue[_agency] = IFactory(factory).getAgencyRevenuePercent(_agency);
        isHavingAgency[msg.sender] = true ;
        emit AgencyAdded(msg.sender, _agency);
    }

    // Function to remove an agency from a member
    function removeAgency() onlyMembers public{
        require(agency[msg.sender] != address(0), "Not added any agency") ;
        delete agencyPercentForRevenue[agency[msg.sender]];
        emit AgencyRemoved(msg.sender, agency[msg.sender]);
        delete agency[msg.sender];
        isHavingAgency[msg.sender] = false ; 
    }

    // Function to set the team score
    function setTeamScore(uint256 value) onlyFactory public{
        teamScore = value ;
        emit TeamScoreSet(value);
    }

    function alarmLoyaltyFeeReceived(uint256 nftId, uint256 price) public {
        uint256 id = getNFTId[msg.sender][nftId] ;
        eachDistribution(id, price) ;
        emit LoyaltyFeeReceived(id, price);
    }

    // Function to handle a sold-out event
    function alarmSoldOut(address contractAddress, uint256 nftId, uint256 price) onlyMarketplace public {
        uint256 id = getNFTId[contractAddress][nftId] ;
        record_member[] memory temp = Recording[id] ;
        uint256 sum = 0 ;
        for(uint256 i = 0 ; i < temp.length ; i ++){
            uint256 value = IMarketplace(marketplace).getBalanceOfUser(temp[i]._member) ;
            Recording[id][i]._percent = value ;
            sum += value ;
        }
        for(uint256 i = 0 ; i < temp.length ; i ++){
            Recording[id][i]._sum = sum ;
        }
        soldOutState[id] = true ;
        soldInformation.push(soldInfor(id, price, false)) ;
    }

    // Function to mint a new NFT
    function mintNew(string memory _nftURI, string memory _name, string memory _symbol, string memory _description) onlyDirector public{
        IERC20(USDC).approve(factory, mintFee);
        address nftAddress = IFactory(factory).mintNew(_nftURI, _name, _symbol, _description);
        nftAddressArr[numberOfNFT] = nftAddress;
        nftIdArr[numberOfNFT] = 1 ;
        getNFTId[nftAddress][1] = numberOfNFT ;
        for(uint256 i = 0 ; i < members.length ; i ++){
            record_member memory tmp = record_member(members[i], 0, 0) ;
            Recording[numberOfNFT].push(tmp) ;
        }
        numberOfNFT ++ ;
        emit NFTMinted(nftAddress, numberOfNFT - 1);
    }

    // Function to mint an existing NFT Collection
    function mint(string memory _nftURI, address _targetNFT) onlyDirector public{
        IERC20(USDC).approve(_targetNFT, mintFee);
        nftIdArr[numberOfNFT] = IContentNFT(_targetNFT).mint(_nftURI);
        nftAddressArr[numberOfNFT] = _targetNFT;
        getNFTId[_targetNFT][nftIdArr[numberOfNFT]] = numberOfNFT ;
        for(uint256 i = 0 ; i < members.length ; i ++){
            record_member memory tmp = record_member(members[i], 0, 0) ;
            Recording[numberOfNFT].push(tmp) ;
        }
        numberOfNFT ++ ;
        emit NFTMinted(_targetNFT, numberOfNFT - 1);
    }

    // Function to list an NFT for an English auction
    function listToEnglishAuction(uint256 id, uint256 initialPrice, uint256 salePeriod) onlyDirector public{
        require(listedState[id] == false, "Already listed!");
        listedState[id] = true;
        IERC721(nftAddressArr[id]).approve(marketplace, nftIdArr[id]);
        IMarketplace(marketplace).listToEnglishAuction(nftAddressArr[id], nftIdArr[id], initialPrice, salePeriod);
        emit EnglishAuctionListed(id, initialPrice, salePeriod) ;
    }

    // Function to list an NFT for a Dutch auction
    function listToDutchAuction(uint256 id, uint256 initialPrice, uint256 reducingRate, uint256 salePeriod) onlyDirector public{
        require(listedState[id] == false, "Already listed!");
        listedState[id] = true;
        IERC721(nftAddressArr[id]).approve(marketplace, nftIdArr[id]);
        IMarketplace(marketplace).listToDutchAuction(nftAddressArr[id], nftIdArr[id], initialPrice, reducingRate, salePeriod);
        emit DutchAuctionListed(id, initialPrice, reducingRate, salePeriod) ;
    }

    // Function to list an NFT for an offering sale
    function listToOfferingSale(uint256 id, uint256 initialPrice) onlyDirector public{
        require(listedState[id] == false, "Already listed!");
        listedState[id] = true;
        IERC721(nftAddressArr[id]).approve(marketplace, nftIdArr[id]);
        IMarketplace(marketplace).listToOfferingSale(nftAddressArr[id], nftIdArr[id], initialPrice);
        emit OfferingSaleListed(id, initialPrice);
    }

    // Function to end an English auction
    function endEnglishAuction(uint256 id) onlyDirector public{
        require(listedState[id] == true, "Not listed!");
        IMarketplace(marketplace).endEnglishAuction(nftAddressArr[id], nftIdArr[id]);
        emit EnglishAuctionEnded(id) ;
    }

    // Function to withdraw funds from the marketplace
    function withdrawFromMarketplace() onlyDirector public{
        IMarketplace(marketplace). withdrawFromSeller();
        uint256 startNumber = currentDistributeNumber ;
        for(uint256 i = startNumber ; i < soldInformation.length ; i ++){
            if(!soldInformation[i].distributeState) eachDistribution(soldInformation[i].id, soldInformation[i].price) ;
            soldInformation[i].distributeState = true ;
        }
        currentDistributeNumber = soldInformation.length ;
        emit WithdrawalFromMarketplace() ;
    }

    // Function to distribute revenue from sold NFTs
    function eachDistribution(uint256 id, uint256 value) internal {
        totalEarning += value ;
        console.log("eachDistribution: id-> %d  value-> %d", id, value) ;
        uint256 count = Recording[id].length ;
        uint256 eachTeamScore = (value * teamScore / 100) / count ;
        value = value - eachTeamScore * count;
        uint256[] memory _revenues = new uint256[](count) ;
        for(uint256 i = 0 ; i < count ; i ++){
            _revenues[i] += eachTeamScore ;
            if(Recording[id][i]._sum == 0){
                _revenues[i] += value / count ;
            }
            else{
                _revenues[i] += (value * Recording[id][i]._percent) / Recording[id][i]._sum ;
            }
        }
        address[] memory _members = new address[](count) ;
        for(uint256 i = 0 ; i < count ; i ++){
            address tmp_address = Recording[id][i]._member ;
            revenueDistribution[tmp_address][id] += _revenues[i] ;
            _members[i] = tmp_address ;
            if(isHavingAgency[tmp_address] == false) balance[tmp_address] += _revenues[i] ;
            else{
                address _agency = agency[tmp_address] ;
                balance[_agency] += _revenues[i] * agencyPercentForRevenue[_agency] / 100 ;
                balance[tmp_address] += _revenues[i] * (100 - agencyPercentForRevenue[_agency]) / 100 ;
            }
        }
        IMarketplace(marketplace).addBalanceOfUser(_members, _revenues, nftAddressArr[id], nftIdArr[id]);
    }

    // Function to cancel the listing of an NFT
    function cancelListing(uint256 id) onlyDirector public{
        require(listedState[id] == true, "Not Listed!") ;
        IMarketplace(marketplace).cancelListing(nftAddressArr[id], nftIdArr[id]) ;
        listedState[id] = false ;
    }

    // Function to submit a director setting transaction
    function submitDirectorSettingTransaction(address _candidate) onlyMembers public{
        require(isOwner[_candidate] == true && _candidate != director, "Select right candidate") ;
        transactions_candidate.push(transaction_candidate(_candidate, false)) ;
        emit DirectorSettingProposed(_candidate);
    }

    // Function to confirm a director setting transaction
    function confirmDirectorSettingTransaction(uint256 index, bool state) onlyMembers public{
        confirmTransaction_Candidate[msg.sender][index] = state;
        emit DirectorSettingConfirmed(index, msg.sender, state);
    }

    // Function to execute a director setting transaction
    function excuteDirectorSettingTransaction(uint256 index) onlyMembers public{
        uint256 count = getConfirmNumberOfDirectorSettingTransaction(index);
        require(count >= numConfirmationRequired, "Not confirmed enough!!!") ;
        director = transactions_candidate[index].candidate ;
        transactions_candidate[index].endState = true ;
        emit DirectorSettingExecuted(director);
    }

    function getConfirmNumberOfDirectorSettingTransaction(uint256 index) public view returns(uint256){
        uint256 count = 0 ;
        for(uint256 i = 0 ; i < numberOfMembers ; i ++){
            if(confirmTransaction_Candidate[members[i]][index] == true || confirmTransaction_Candidate[agency[members[i]]][index] == true){
                count ++ ;
            }
        }
        return count ;
    }
    // Function to submit an offering sale transaction
    function submitOfferingSaleTransaction(uint256 _marketId, address _tokenContractAddress, uint256 tokenId, address _buyer, uint256 _price) onlyMarketplace public {

        uint256 id = getNFTId[_tokenContractAddress][tokenId] ;
        require(listedState[id] == true, "Not listed");
        transactions_offering.push(transaction_offering(_marketId, id, _buyer, _price, false));
        emit OfferingSaleTransactionProposed(_tokenContractAddress, tokenId, _buyer, _price);
    }

    // Function to confirm an offering sale transaction
    function confirmOfferingSaleTransaction(uint256 index, bool state) onlyMembers public{
        confirmTransaction_Offering[msg.sender][index] = state;
        emit OfferingSaleTransactionConfirmed(index, msg.sender, state) ;
    }

    // Function to execute an offering sale transaction
    function excuteOfferingSaleTransaction(uint256 index) onlyMembers public{
        uint256 count = getConfirmNumberOfOfferingSaleTransaction(index);
        require(count >= numConfirmationRequired, "Not confirmed enough!!!") ;
        transactions_offering[index].endState = true ;
        for(uint256 i = 0 ; i < transactions_offering.length ; i ++){
            if(transactions_offering[i].id == transactions_offering[index].id){
                transactions_offering[i].endState = true ;
            }
        }
        address buyer = transactions_offering[index].buyer;
        IMarketplace(marketplace).endOfferingSale(transactions_offering[index].marketId, buyer) ;
        emit OfferingSaleTransactionExecuted(index) ;
    }

    function getConfirmNumberOfOfferingSaleTransaction(uint256 index) public view returns(uint256){
        uint256 count = 0 ;
        for(uint256 i = 0 ; i < numberOfMembers ; i ++){
            if(confirmTransaction_Offering[members[i]][index] == true || confirmTransaction_Offering[agency[members[i]]][index] == true){
                count ++ ;
            }
        }
        return count ;
    }


    function submitBurnTransaction(uint256 id) onlyMembers public {
        require(listedState[id] == false, "Not listed");
        transactions_burn.push(transaction_burn(id, false));
        emit BurnTransactionProposed(id);
    }

    // Function to confirm an offering sale transaction
    function confirmBurnTransaction(uint256 index, bool state) onlyMembers public{
        confirmTransaction_Burn[msg.sender][index] = state;
        emit BurnTransactionConfirmed(index, msg.sender, state) ;
    }

    // Function to execute an offering sale transaction
    function excuteBurnTransaction(uint256 index) onlyMembers public{
        uint256 count = getConfirmNumberOfBurnTransaction(index);
        require(count >= numConfirmationRequired, "Not confirmed enough!!!") ;
        transactions_burn[index].endState = true ;
        for(uint256 i = 0 ; i < transactions_burn.length ; i ++){
            if(transactions_burn[i].id == transactions_burn[index].id){
                transactions_burn[i].endState = true ;
            }
        }
        uint256 id = transactions_burn[index].id ;
        address nftAddress = nftAddressArr[id] ;
        uint256 tokenId = nftIdArr[id] ;
        IERC20(USDC).approve(nftAddress, burnFee);
        IContentNFT(nftAddress).burn(tokenId);
        nftIdArr[id] = nftIdArr[numberOfNFT - 1] ;
        delete nftIdArr[numberOfNFT - 1] ;
        nftAddressArr[id] = nftAddressArr[numberOfNFT - 1] ;
        delete nftAddressArr[numberOfNFT - 1];
        getNFTId[nftAddressArr[id]][nftIdArr[id]] = id ;
        delete getNFTId[nftAddress][tokenId] ;
        numberOfNFT -- ;
        emit NFTBurned(id);
    }

    function getConfirmNumberOfBurnTransaction(uint256 index) public view returns(uint256){
        uint256 count = 0 ;
        for(uint256 i = 0 ; i < numberOfMembers ; i ++){
            if(confirmTransaction_Burn[members[i]][index] == true || confirmTransaction_Burn[agency[members[i]]][index] == true){
                count ++ ;
            }
        }
        return count ;
    }

    // Function to set the number of confirmations required for transactions
    function setConfirmationRequiredNumber(uint256 confirmNumber) onlyDirector public{
        require(confirmNumber <= numberOfMembers && confirmNumber >= 1, "Invalid Number") ;
        numConfirmationRequired = confirmNumber;
        emit ConfirmationRequiredNumberSet(confirmNumber);
    }

    // Function to get the NFT ID of a specific index
    function getNftOfId(uint256 index) public view returns (uint256) {
        return nftIdArr[index];
    }

    // Function to get the NFT address of a specific index
    function getNftAddress(uint256 index) public view returns (address) {
        return nftAddressArr[index];
    }

    // Function to get the revenue distribution for a member and NFT ID
    function getRevenueDistribution(address one, uint256 id) public view returns (uint256) {
        return revenueDistribution[one][id];
    }

    // Function to get the number of sold NFTs
    function getSoldNumber() public view returns(uint256){
        return soldInformation.length;
    }

    // Function to get information about a sold NFT at a specific index
    function getSoldInfor(uint256 index) public view returns (soldInfor memory) {
        return soldInformation[index] ;
    }

    // Function to withdraw funds from the contract
    function withdraw() public {
        uint256 balanceToWithdraw = balance[msg.sender] ;
        require(balanceToWithdraw > 0, "No balance to withdraw");
        balance[msg.sender] = 0;
        IERC20(USDC).approve(address(this), balanceToWithdraw);
        IERC20(USDC).transferFrom(address(this), msg.sender, balanceToWithdraw);
        emit withdrawHappened(msg.sender, balanceToWithdraw) ;
    }

    function getNumberOfCandidateTransaction() public view returns(uint256) {
        return transactions_candidate.length ;
    }

    function getNumberOfSaleOfferingTransaction() public view returns(uint256) {
        return transactions_offering.length ;
    }
    function getNumberOfBurnTransaction() public view returns(uint256) {
        return transactions_burn.length ;
    }
}
