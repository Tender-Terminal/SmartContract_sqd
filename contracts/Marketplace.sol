// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './interfaces/ICreatorGroup.sol';
import "./interfaces/IContentNFT.sol" ;
contract Marketplace {
    address public owner; // Address of the contract owner
    address public developmentTeam; // Address of the development team
    uint256 public balanceOfDevelopmentTeam ; // Balance of the development team
    uint256 public percentForSeller; // Percentage of the Seller
    uint256 public percentForLoyaltyFee ; // Percentage of the loyalty fee
    mapping(address => uint256) balanceOfUser ; // Balance of the user
    address public USDC ; // Address of the USDC
    mapping(address => uint256) balanceOfSeller ; // Balance of the seller
    // Enum defining different sale types
    enum SaleType {
        ENGLISH_AUCTION,
        DUTCH_AUCTION,
        OFFERING_SALE
    }

    // Struct to represent a listed NFT
    struct listedNFT{                         
        SaleType _saleType;
        uint256 Id;
        address currentOwner;
        address nftContractAddress;
        uint256 nftId;
        uint256 startTime;
        uint256 endTime;
        bool endState;
    }

    listedNFT[] public listedNFTs; // Array to store listed NFTs
    mapping(uint256 => bool) cancelListingState ; // Array to store state of cancelListing
    mapping(uint256 => bool) recordAddRevenueState ; // Array to store state of recordAddRevenue

    // Struct to handle English auction details
    struct englishAuction {
        uint256 initialPrice;
        uint256 salePeriod;
        address currentWinner;
        uint256 currentPrice;
        
    }
    mapping(uint256 => mapping(address => uint256)) englishAuction_balancesForWithdraw; // Mapping to store balances available for withdrawal in English auctions
    englishAuction[] public englishAuctions; // Array to store instances of English auction contracts
    mapping(uint256 => uint256) public englishAuction_listedNumber; // Mapping to track the number of items listed in each English auction

    // Struct to handle Dutch auction details
    struct dutchAuction {
        uint256 initialPrice;
        uint256 reducingRate;
        uint256 salePeriod;
    }

    dutchAuction[] public dutchAuctions; // Array to store instances of Dutch auction contracts
    mapping(uint256 => uint256) public dutchAuction_listedNumber; // Mapping to track the number of items listed in each Dutch auction

    // Strcut to handle Offering Sale details
    struct offeringSale{
        uint256 initialPrice;
        
    }
    mapping(uint256 => mapping(address => uint256)) offeringSale_balancesForWithdraw; // Mapping to store balances available for withdrawal in offering sales
    mapping(uint256 => mapping(address => uint256)) offeringSale_currentBids; // Mapping to store current bids in offering sales
    offeringSale[] public offeringSales; // Array to store instances of offering sale contracts
    mapping(uint256 => uint256) public offeringSale_listedNumber; // Mapping to track the number of items listed in each offering sale


    // Modifier to restrict access to only the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    event BuyEnglishAuction(address buyer, address contractAddress, uint256 nftId, uint256 price, uint256 time);
    event BuyDutchAuction(address buyer, address contractAddress, uint256 nftId, uint256 price, uint256 time);
    event BuyOfferingSale(address buyer, address contractAddress, uint256 nftId, uint256 price, uint256 time);
    event Withdrawal(address indexed withdrawer, uint256 amount);
    event developmentTeamSet(address indexed _developmentTeam);
    event percentForSellerSet(uint256 _percentForSeller);
    event newEnglishAuctionListing(address _nftContractAddress, uint256 _nftId, uint256 _initialPrice, uint256 _salePeriod) ;
    event newDutchAuctionListing(address _nftContractAddress, uint256 nftId, uint256 initialPrice, uint256 reducingRate, uint256 salePeriod) ;
    event newOfferingSaleListing(address nftContractAddress, uint256 nftId, uint256 initialPrice) ;
    event newBidToEnglishAuction(uint256 id, uint256 sendingValue, address currentWinner) ;
    event newWithdrawFromEnglishAuction(uint256 id, address from, uint256 amount) ;
    event newBidToOfferingSale(uint256 id, address from, uint256 sendingValue);
    event newWithdrawFromOfferingSale(uint256 id, address from, uint256 amount) ;
    event canceledListing(uint256 id, address from) ;
    event percentForLoyaltyFeeSet(uint256 value) ;

    // Constructor to set the development team address
    constructor(address _developmentTeam, uint256 _percentForSeller, address _USDC) {
        owner = msg.sender ;
        developmentTeam = _developmentTeam;
        percentForSeller = _percentForSeller;
        balanceOfDevelopmentTeam = 0 ;
        USDC = _USDC ;
        percentForLoyaltyFee = 5 ;
    }

    // Function to get the balance of a specific user
    function getBalanceOfUser(address to) public view returns(uint256){
        return balanceOfUser[to] ;
    }

    // Function to add balance to multiple users
    function addBalanceOfUser(address[] memory _members, uint256[] memory _values, address contractAddress, uint256 nftId) public {
        bool flag = false ;
        for(uint256 i = 0 ; i < listedNFTs.length ; i ++){
            if(listedNFTs[i].nftContractAddress == contractAddress && listedNFTs[i].nftId == nftId && 
                listedNFTs[i].currentOwner == msg.sender && listedNFTs[i].endState == true && recordAddRevenueState[i] == false){
                    flag = true ; break ;
            }
        }
        require(flag == true, "Invalid address for adding revenue") ;
        for(uint256 i = 0 ; i < _members.length ; i ++){
            balanceOfUser[_members[i]] += _values[i] ;
        }
    }

    // Function to set the development team address (only callable by the owner)
    function setDevelopmentTeam(address _developmentTeam) public onlyOwner {
        developmentTeam = _developmentTeam;
        emit developmentTeamSet(developmentTeam);
    }

    // Function to set the percentage for seller (only callable by the owner)
    function setPercentForSeller(uint256 _percentForSeller) public onlyOwner {
        percentForSeller = _percentForSeller;
        emit percentForSellerSet(percentForSeller);
    }

    function setPercentForLoyaltyFee(uint256 _percentForLoyaltyFee) public onlyOwner {
        percentForLoyaltyFee = _percentForLoyaltyFee ;
        emit percentForLoyaltyFeeSet(percentForLoyaltyFee);
    }

    // Function to withdraw funds from the contract (only callable by the development team)
    function withdraw() public {
        require(msg.sender == developmentTeam, "Invalid withdrawer");
        uint amount = balanceOfDevelopmentTeam;
        balanceOfDevelopmentTeam = 0 ;
        IERC20(USDC).approve(address(this), amount) ;
        IERC20(USDC).transferFrom(address(this), msg.sender, amount) ;
        emit Withdrawal(msg.sender, amount);
    }

    // Function to withdraw funds from a seller's balance
    function withdrawFromSeller() public {
        require(balanceOfSeller[msg.sender] > 0, "Invalid withdrawer");
        uint amount = balanceOfSeller[msg.sender] ;
        balanceOfSeller[msg.sender] = 0 ;
        IERC20(USDC).approve(address(this), amount) ;
        IERC20(USDC).transferFrom(address(this), msg.sender, amount) ;
        emit Withdrawal(msg.sender, amount);
    }

    // Function to record revenue from a sale
    function recordRevenue(address seller, uint256 price, address contractAddress, uint256 nftId) private{
        uint256 value = price * percentForSeller / 100 ;
        balanceOfSeller[seller] += value ;
        balanceOfDevelopmentTeam += price - value ;
        ICreatorGroup(seller).alarmSoldOut(contractAddress, nftId, value);
    }

    // Function to list an NFT to an English auction
    function listToEnglishAuction(address nftContractAddress, uint256 nftId, uint256 initialPrice, uint256 salePeriod) public {
        require(checkOwnerOfNFT(nftContractAddress, nftId) == true, "Invalid token owner");
        uint256 id = englishAuctions.length;
        englishAuction memory newAuction = englishAuction(initialPrice, salePeriod, address(0), initialPrice);
        englishAuctions.push(newAuction);
        listedNFT memory newListing = listedNFT(SaleType.ENGLISH_AUCTION, id, msg.sender, nftContractAddress, nftId, block.timestamp, 0, false);
        englishAuction_listedNumber[id] = listedNFTs.length;
        listedNFTs.push(newListing);
        emit newEnglishAuctionListing(nftContractAddress, nftId, initialPrice, salePeriod) ;
    }

    // Function to list an NFT to a Dutch auction
    function listToDutchAuction(address nftContractAddress, uint256 nftId, uint256 initialPrice, uint256 reducingRate, uint256 salePeriod) public{
        require(checkOwnerOfNFT(nftContractAddress, nftId) == true, "Invalid token owner");
        uint256 id = dutchAuctions.length;
        dutchAuction memory newAuction = dutchAuction(initialPrice, reducingRate, salePeriod);
        dutchAuctions.push(newAuction);
        listedNFT memory newListing = listedNFT(SaleType.DUTCH_AUCTION, id, msg.sender, nftContractAddress, nftId, block.timestamp, 0, false);
        dutchAuction_listedNumber[id] = listedNFTs.length;
        listedNFTs.push(newListing);
        emit newDutchAuctionListing(nftContractAddress, nftId, initialPrice, reducingRate, salePeriod) ;
    }

    // Function to list an NFT for an offering sale
    function listToOfferingSale(address nftContractAddress, uint256 nftId, uint256 initialPrice) public{
        require(checkOwnerOfNFT(nftContractAddress, nftId) == true, "Invalid token owner");
        uint256 id = offeringSales.length;
        offeringSale memory newSale = offeringSale(initialPrice);
        offeringSales.push(newSale);
        listedNFT memory newListing = listedNFT(SaleType.OFFERING_SALE, id, msg.sender, nftContractAddress, nftId, block.timestamp, 0, false);
        offeringSale_listedNumber[id] = listedNFTs.length;
        listedNFTs.push(newListing);
        emit newOfferingSaleListing(nftContractAddress, nftId, initialPrice) ;
    }

    // Function to check the owner of an NFT
    function checkOwnerOfNFT(address nftContractAddress, uint256 nftId) public view returns (bool) {
        address checkAddress = IERC721(nftContractAddress).ownerOf(nftId);
        return (checkAddress == msg.sender) ;
    }

    // Function for a user to bid in an English auction
    function makeBidToEnglishAuction(uint256 id, uint256 sendingValue) public{ 
        require(cancelListingState[id] == false, "Listing Cancelled.");
        require(englishAuctions.length > id, "Not listed in the english auction list.");
        uint256 listedId = englishAuction_listedNumber[id];
        require(listedNFTs[listedId].endState == false, "Already sold out.");
        // address contractAddress = listedNFTs[listedId].nftContractAddress;
        // uint256 nftId = listedNFTs[listedId].nftId;
        uint256 price = englishAuctions[id].currentPrice;
        address currentWinner = englishAuctions[id].currentWinner;
        require(sendingValue > price, "You should send a price that is more than current price.");
        IERC20(USDC).transferFrom(msg.sender, address(this), sendingValue) ;
        englishAuction_balancesForWithdraw[id][currentWinner] += price;
        englishAuctions[id].currentPrice = sendingValue ;
        englishAuctions[id].currentWinner = msg.sender;
        emit newBidToEnglishAuction(id, sendingValue, currentWinner) ;
    }

    // Function to withdraw funds from an English auction
    function withdrawFromEnglishAuction(uint256 id) public{
        require(englishAuctions.length > id, "Not listed in the english auction list.");
        // uint256 listedId = englishAuction_listedNumber[id];
        uint256 amount = englishAuction_balancesForWithdraw[id][msg.sender] ;
        require(amount > 0, "You don't have any balance.");
        englishAuction_balancesForWithdraw[id][msg.sender] = 0 ;
        IERC20(USDC).approve(address(this), amount) ;
        IERC20(USDC).transferFrom(address(this), msg.sender, amount) ;
        emit newWithdrawFromEnglishAuction(id, msg.sender, amount) ;
    }
    
    // Function to end an English auction
    function endEnglishAuction(address _nftAddress, uint256 _nftId) public{
        uint256 id ;
        bool flg = false ;
        for(uint256 i = 0 ; i < englishAuctions.length ; i ++){
            uint256 tmp_Id = englishAuction_listedNumber[i] ;
            if(listedNFTs[tmp_Id].nftContractAddress == _nftAddress &&  listedNFTs[tmp_Id].nftId == _nftId) {
                id = i ; flg = true ; break ;
            }
        }
        require(flg, "Wrong nft") ;
        require(cancelListingState[id] == false, "Listing Cancelled.");
        require(englishAuctions.length > id, "Not listed in the english auction list.");
        uint256 listedId = englishAuction_listedNumber[id];
        uint256 expectEndTime = listedNFTs[listedId].startTime + englishAuctions[id].salePeriod;
        require(expectEndTime < block.timestamp, "Auction is not ended!");
        address contractAddress = listedNFTs[listedId].nftContractAddress;
        uint256 nftId = listedNFTs[listedId].nftId;
        uint256 price = englishAuctions[id].currentPrice;  
        address currentOwner = listedNFTs[listedId].currentOwner;
        require(msg.sender == currentOwner, "Only current Owner is allowed to end the auction.");
        uint256 loyaltyFee ;
        loyaltyFee = price * percentForLoyaltyFee / 100;
        IContentNFT(contractAddress).setLoyaltyFee(nftId, loyaltyFee);
        if(IContentNFT(contractAddress).creators(nftId) == currentOwner) loyaltyFee = 0 ;
        IERC20(USDC).approve(address(contractAddress), loyaltyFee) ;
        IContentNFT(contractAddress).transferFrom(currentOwner, englishAuctions[id].currentWinner, nftId);
        recordRevenue(currentOwner, price - loyaltyFee, contractAddress, nftId) ;
        listedNFTs[listedId].endState = true;
        listedNFTs[listedId].endTime = block.timestamp;
        emit BuyEnglishAuction(englishAuctions[id].currentWinner, contractAddress, nftId, price, block.timestamp);
    }

    // Function for a user to buy in a Dutch auction
    function buyDutchAuction(uint256 id, uint256 sendingValue) public{
        require(cancelListingState[id] == false, "Listing Cancelled.");
        require(dutchAuctions.length > id, "Not listed in the dutch auction list.");
        uint256 listedId = dutchAuction_listedNumber[id];
        require(listedNFTs[listedId].endState == false, "Already sold out.");
        address contractAddress = listedNFTs[listedId].nftContractAddress;
        uint256 nftId = listedNFTs[listedId].nftId;
        address currentOwner = listedNFTs[listedId].currentOwner;
        
        uint256 price = getDutchAuctionPrice(id);
        require(sendingValue == price, "Not exact fee");
        IERC20(USDC).transferFrom(msg.sender, address(this), sendingValue) ;
        uint256 loyaltyFee ;
        loyaltyFee = price * percentForLoyaltyFee / 100;
        IContentNFT(contractAddress).setLoyaltyFee(nftId, loyaltyFee);
        if(IContentNFT(contractAddress).creators(nftId) == currentOwner) loyaltyFee = 0 ;
        IERC20(USDC).approve(address(contractAddress), loyaltyFee) ;
        IContentNFT(contractAddress).transferFrom(currentOwner, msg.sender, nftId);
        recordRevenue(currentOwner, price - loyaltyFee, contractAddress, nftId) ;
        listedNFTs[listedId].endState = true;
        listedNFTs[listedId].endTime = block.timestamp;
        emit BuyDutchAuction(msg.sender, contractAddress, nftId, price, block.timestamp);
    }

    // Function to get the current price in a Dutch auction
    function getDutchAuctionPrice(uint256 id) public view returns (uint256){
        uint256 listedId = dutchAuction_listedNumber[id];
        uint256 duration = 3600 ;
        uint256 price = dutchAuctions[id].initialPrice - (block.timestamp - listedNFTs[listedId].startTime) / duration * dutchAuctions[id].reducingRate ;
        return price ;
    }

    // Function for a user to bid in an offering sale
    function makeBidToOfferingSale(uint256 id, uint256 sendingValue) public{
        require(cancelListingState[id] == false, "Listing Cancelled.");
        require(offeringSales.length > id, "Not listed in the offering sale list.");
        uint256 listedId = offeringSale_listedNumber[id];
        require(listedNFTs[listedId].endState == false, "Already sold out.");
        address contractAddress = listedNFTs[listedId].nftContractAddress;
        uint256 nftId = listedNFTs[listedId].nftId;
        address currentOwner = listedNFTs[listedId].currentOwner;
        uint256 price = offeringSales[id].initialPrice ;
        require(sendingValue >= price, "You should send a price that is more than current price.") ;
        IERC20(USDC).transferFrom(msg.sender, address(this), sendingValue) ;
        offeringSale_currentBids[id][msg.sender] = sendingValue;
        offeringSale_balancesForWithdraw[id][msg.sender] += sendingValue;
        // call the CreatorGroup's function
        ICreatorGroup(currentOwner).submitOfferingSaleTransaction(id, contractAddress, nftId, msg.sender, sendingValue) ;
        emit newBidToOfferingSale(id, msg.sender, sendingValue);
    }

    // Function to withdraw funds from an offering sale
    function withdrawFromOfferingSale(uint256 id) public{
        require(offeringSales.length > id, "Not listed in the offering sale list.");
        // uint256 listedId = offeringSale_listedNumber[id];
        uint256 amount = offeringSale_balancesForWithdraw[id][msg.sender] ;
        require(amount > 0, "You don't have any balance.");
        offeringSale_balancesForWithdraw[id][msg.sender] = 0 ;
        IERC20(USDC).approve(address(this), amount) ;
        IERC20(USDC).transferFrom(address(this), msg.sender, amount) ;
        emit newWithdrawFromOfferingSale(id, msg.sender, amount) ;
    }

    // Function to end an offering sale
    function endOfferingSale(uint256 id, address buyer) public{
        require(cancelListingState[id] == false, "Listing Cancelled.");
        require(offeringSales.length > id, "Not listed in the offering sale list.");
        uint256 listedId = offeringSale_listedNumber[id];
        uint256 price = offeringSale_currentBids[id][buyer];
        require(price > 0, "Buyer doesn't have any bid.");
        address contractAddress = listedNFTs[listedId].nftContractAddress;
        uint256 nftId = listedNFTs[listedId].nftId;
        require(checkOwnerOfNFT(contractAddress, nftId) == true, "only the nft owner can call this function");
        uint256 loyaltyFee ;
        loyaltyFee = price * percentForLoyaltyFee / 100;
        IContentNFT(contractAddress).setLoyaltyFee(nftId, loyaltyFee);
        if(IContentNFT(contractAddress).creators(nftId) == msg.sender) loyaltyFee = 0 ;
        IERC20(USDC).approve(address(contractAddress), loyaltyFee) ;
        IContentNFT(contractAddress).transferFrom(msg.sender, buyer, nftId);
        recordRevenue(msg.sender, price - loyaltyFee, contractAddress, nftId) ;
        listedNFTs[listedId].endState = true;
        listedNFTs[listedId].endTime = block.timestamp;
        emit BuyOfferingSale(buyer, contractAddress, nftId, price, block.timestamp);
    }

    // Function to cancel a listing
    function cancelListing(address _nftContractAddress, uint256 _nftId) public{
        require(checkOwnerOfNFT(_nftContractAddress, _nftId) == true, "only the nft owner can call this function");
        uint256 id ;
        for(uint256 i = 0 ; i < listedNFTs.length ; i++){
            if(listedNFTs[i].nftContractAddress == _nftContractAddress && listedNFTs[i].nftId == _nftId){
                id = i ; break ;
            }
        }
        require(listedNFTs[id].endState == false, "Already sold out!") ;
        require(!(listedNFTs[id]._saleType == SaleType.ENGLISH_AUCTION && englishAuctions.length > 0), "Already english auction started!") ;
        cancelListingState[id] = false ;
        emit canceledListing(id, msg.sender) ;
    }

    function getListedNumber() public view returns(uint256){
        return listedNFTs.length ;
    }
    function getListedEnglishAuctionNumber() public view returns(uint256){
        return englishAuctions.length ;
    }
    function getListedDutchAuctionNumber() public view returns(uint256){
        return dutchAuctions.length;
    }
    function getOfferingSaleAuctionNumber() public view returns(uint256){
        return offeringSales.length;
    }

}
