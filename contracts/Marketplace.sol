// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICreatorGroup.sol";
import "./interfaces/IContentNFT.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Marketplace {
    // Enum defining different sale types
    enum SaleType {
        ENGLISH_AUCTION,
        DUTCH_AUCTION,
        OFFERING_SALE
    }
    // Struct to represent a listed NFT
    struct listedNFT {
        SaleType _saleType;
        uint256 Id;
        address currentOwner;
        address nftContractAddress;
        uint256 nftId;
        uint256 startTime;
        uint256 endTime;
        bool endState;
    }
    // Struct to handle English auction details
    struct englishAuction {
        uint256 initialPrice;
        uint256 salePeriod;
        address currentWinner;
        uint256 currentPrice;
    }
    // Struct to handle Dutch auction details
    struct dutchAuction {
        uint256 initialPrice;
        uint256 reducingRate;
        uint256 salePeriod;
    }
    // Strcut to handle Offering Sale details
    struct offeringSale {
        uint256 initialPrice;
        uint256 bidNumber;
    }
    // State variables
    address public owner; // Address of the contract owner
    address public developmentTeam; // Address of the development team
    uint256 public balanceOfDevelopmentTeam; // Balance of the development team
    uint256 public percentForSeller; // Percentage of the Seller
    uint256 public percentForLoyaltyFee; // Percentage of the loyalty fee
    mapping(address => uint256) public balanceOfUser; // Balance of the user
    address public USDC; // Address of the USDC
    IERC20 public immutable USDC_token; // USDC token contract
    mapping(address => uint256) public balanceOfSeller; // Balance of the seller
    listedNFT[] public listedNFTs; // Array to store listed NFTs
    mapping(uint256 => bool) public cancelListingState; // Array to store state of cancelListing
    mapping(uint256 => mapping(address => uint256)) public englishAuction_balancesForWithdraw; // Mapping to store balances available for withdrawal in English auctions
    englishAuction[] public englishAuctions; // Array to store instances of English auction contracts
    mapping(uint256 => uint256) public englishAuction_listedNumber; // Mapping to track the number of items listed in each English auction
    dutchAuction[] public dutchAuctions; // Array to store instances of Dutch auction contracts
    mapping(uint256 => uint256) public dutchAuction_listedNumber; // Mapping to track the number of items listed in each Dutch auction
    mapping(uint256 => mapping(address => uint256)) public offeringSale_balancesForWithdraw; // Mapping to store balances available for withdrawal in offering sales
    mapping(uint256 => mapping(address => uint256)) offeringSale_currentBids; // Mapping to store current bids in offering sales
    offeringSale[] public offeringSales; // Array to store instances of offering sale contracts
    mapping(uint256 => uint256) public offeringSale_listedNumber; // Mapping to track the number of items listed in each offering sale
    //event
    event BuyEnglishAuction(
        address indexed buyer,
        address indexed contractAddress,
        uint256 indexed nftId,
        uint256 price,
        uint256 time
    );
    event BuyDutchAuction(
        address indexed buyer,
        address indexed contractAddress,
        uint256 indexed nftId,
        uint256 price,
        uint256 time
    );
    event BuyOfferingSale(
        address indexed buyer,
        address indexed contractAddress,
        uint256 indexed nftId,
        uint256 price,
        uint256 time
    );
    event Withdrawal(address indexed withdrawer, uint256 indexed amount);
    event DevelopmentTeamSet(address indexed _developmentTeam);
    event PercentForSellerSet(uint256 indexed _percentForSeller);
    event NewEnglishAuctionListing(
        address indexed _nftContractAddress,
        uint256 indexed _nftId,
        uint256 indexed _initialPrice,
        uint256 _salePeriod
    );
    event NewDutchAuctionListing(
        address indexed _nftContractAddress,
        uint256 indexed nftId,
        uint256 indexed initialPrice,
        uint256 reducingRate,
        uint256 salePeriod
    );
    event NewOfferingSaleListing(
        address indexed nftContractAddress,
        uint256 indexed nftId,
        uint256 indexed initialPrice
    );
    event NewBidToEnglishAuction(
        uint256 indexed id,
        uint256 indexed sendingValue,
        address indexed currentWinner
    );
    event NewWithdrawFromEnglishAuction(
        uint256 indexed id,
        address indexed from,
        uint256 indexed amount
    );
    event NewBidToOfferingSale(uint256 indexed id, address indexed from, uint256 indexed sendingValue);
    event NewWithdrawFromOfferingSale(uint256 indexed id, address indexed from, uint256 indexed amount);
    event CanceledListing(uint256 indexed id, address indexed from);
    event PercentForLoyaltyFeeSet(uint256 indexed value);
    // Modifier to restrict access to only the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    /// @notice Constructor to set the development team address
    /// @param _developmentTeam Address of the development team
    /// @param _percentForSeller Revenue Percentage for the seller of the sold NFT
    /// @param _USDC Address of the USDC token
    constructor(
        address _developmentTeam,
        uint256 _percentForSeller,
        address _USDC
    ) {
        owner = msg.sender;
        require(_developmentTeam!= address(0), "Invalid address");
        developmentTeam = _developmentTeam;
        require(_percentForSeller <= 100 && _percentForSeller >= 0, "Invalid percentage");
        percentForSeller = _percentForSeller;
        balanceOfDevelopmentTeam = 0;
         require(_USDC!= address(0), "Invalid address");
        USDC = _USDC;
        USDC_token = IERC20(USDC) ;
        percentForLoyaltyFee = 5;
    }

    /// @notice Function to get the balance of a specific user
    /// @param to Address to get the balance of user
    /// @return The balance of a specific user
    function getBalanceOfUser(address to) external view returns (uint256) {
        return balanceOfUser[to];
    }

    /// @notice Function to add balance to multiple users
    /// @param _members Array of addresses to add balance
    /// @param _values Array of values to add to the balance of each user
    /// @param contractAddress Address of the NFT contract
    /// @param nftId TokenId of the NFT contract
    function addBalanceOfUser(
        address[] memory _members,
        uint256[] memory _values,
        address contractAddress,
        uint256 nftId
    ) external {
        bool flag = false;
        for (uint256 i = 0; i < listedNFTs.length; i++) {
            if (
                listedNFTs[i].nftContractAddress == contractAddress &&
                listedNFTs[i].nftId == nftId &&
                listedNFTs[i].currentOwner == msg.sender &&
                listedNFTs[i].endState == true
            ) {
                flag = true;
                break;
            }
        }
        require(flag == true, "Invalid address for adding revenue");
        for (uint256 i = 0; i < _members.length; i++) {
            balanceOfUser[_members[i]] += _values[i];
        }
    }

    /// @notice Function to set the development team address
    /// @param _developmentTeam Address of the development team
    /// @dev Only callable by the owner
    function setDevelopmentTeam(address _developmentTeam) external onlyOwner {
        developmentTeam = _developmentTeam;
        emit DevelopmentTeamSet(developmentTeam);
    }

    /// @notice Function to set the percentage for seller
    /// @param _percentForSeller Revenue Percentage for the seller of the sold NFT
    /// @dev Only callable by the owner
    function setPercentForSeller(uint256 _percentForSeller) external onlyOwner {
        percentForSeller = _percentForSeller;
        emit PercentForSellerSet(percentForSeller);
    }

    /// @notice Function to set the percentage for Loyalty Fee
    /// @param _percentForLoyaltyFee Percentage for Loyalty Fee
    /// @dev Only callable by the owner
    function setPercentForLoyaltyFee(
        uint256 _percentForLoyaltyFee
    ) external onlyOwner {
        percentForLoyaltyFee = _percentForLoyaltyFee;
        emit PercentForLoyaltyFeeSet(percentForLoyaltyFee);
    }

    /// @notice Function to withdraw funds from the contract
    function withdraw() external {
        require(msg.sender == developmentTeam, "Invalid withdrawer");
        uint amount = balanceOfDevelopmentTeam;
        balanceOfDevelopmentTeam = 0;
        if(amount > 0) SafeERC20.safeTransfer(USDC_token, msg.sender, amount) ;
        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Function to withdraw funds from a seller's balance
    function withdrawFromSeller() external {
        require(balanceOfSeller[msg.sender] > 0, "Invalid withdrawer");
        uint amount = balanceOfSeller[msg.sender];
        balanceOfSeller[msg.sender] = 0;
        if(amount > 0) SafeERC20.safeTransfer(USDC_token, msg.sender, amount) ;
        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Function to record revenue from a sale
    /// @param seller Address of the seller
    /// @param price Price of the NFT
    /// @param contractAddress Address of the NFT contract
    /// @param nftId TokenId of the NFT contract
    function recordRevenue(
        address seller,
        uint256 price,
        address contractAddress,
        uint256 nftId
    ) private {
        uint256 value = (price * percentForSeller) / 100;
        balanceOfSeller[seller] += value;
        balanceOfDevelopmentTeam += price - value;
        ICreatorGroup(seller).alarmSoldOut(contractAddress, nftId, value);
    }

    /// @notice Function to list an NFT to an English auction
    /// @param nftContractAddress Address of the NFT contract
    /// @param nftId TokenId of the NFT contract
    /// @param initialPrice Initial price of the NFT
    /// @param salePeriod Sale period of the NFT
    function listToEnglishAuction(
        address nftContractAddress,
        uint256 nftId,
        uint256 initialPrice,
        uint256 salePeriod
    ) external {
        require(
            checkOwnerOfNFT(nftContractAddress, nftId) == true,
            "Invalid token owner"
        );
        uint256 id = englishAuctions.length;
        englishAuction memory newAuction = englishAuction(
            initialPrice,
            salePeriod,
            address(0),
            initialPrice
        );
        englishAuctions.push(newAuction);
        listedNFT memory newListing = listedNFT(
            SaleType.ENGLISH_AUCTION,
            id,
            msg.sender,
            nftContractAddress,
            nftId,
            block.timestamp,
            0,
            false
        );
        englishAuction_listedNumber[id] = listedNFTs.length;
        listedNFTs.push(newListing);
        emit NewEnglishAuctionListing(
            nftContractAddress,
            nftId,
            initialPrice,
            salePeriod
        );
    }

    /// @notice Function to list an NFT to a Dutch auction
    /// @param nftContractAddress Address of the NFT contract
    /// @param nftId TokenId of the NFT contract
    /// @param initialPrice Initial price of the NFT
    /// @param reducingRate The reducing rate per hour
    /// @param salePeriod Sale period of the NFT
    function listToDutchAuction(
        address nftContractAddress,
        uint256 nftId,
        uint256 initialPrice,
        uint256 reducingRate,
        uint256 salePeriod
    ) external {
        require(
            checkOwnerOfNFT(nftContractAddress, nftId) == true,
            "Invalid token owner"
        );
        uint256 id = dutchAuctions.length;
        dutchAuction memory newAuction = dutchAuction(
            initialPrice,
            reducingRate,
            salePeriod
        );
        dutchAuctions.push(newAuction);
        listedNFT memory newListing = listedNFT(
            SaleType.DUTCH_AUCTION,
            id,
            msg.sender,
            nftContractAddress,
            nftId,
            block.timestamp,
            0,
            false
        );
        dutchAuction_listedNumber[id] = listedNFTs.length;
        listedNFTs.push(newListing);
        emit NewDutchAuctionListing(
            nftContractAddress,
            nftId,
            initialPrice,
            reducingRate,
            salePeriod
        );
    }

    /// @notice Function to list an NFT for an offering sale
    /// @param nftContractAddress Address of the NFT contract
    /// @param nftId TokenId of the NFT contract
    /// @param initialPrice Initial price of the NFT
    function listToOfferingSale(
        address nftContractAddress,
        uint256 nftId,
        uint256 initialPrice
    ) external {
        require(
            checkOwnerOfNFT(nftContractAddress, nftId) == true,
            "Invalid token owner"
        );
        uint256 id = offeringSales.length;
        offeringSale memory newSale = offeringSale(initialPrice, 0);
        offeringSales.push(newSale);
        listedNFT memory newListing = listedNFT(
            SaleType.OFFERING_SALE,
            id,
            msg.sender,
            nftContractAddress,
            nftId,
            block.timestamp,
            0,
            false
        );
        offeringSale_listedNumber[id] = listedNFTs.length;
        listedNFTs.push(newListing);
        emit NewOfferingSaleListing(nftContractAddress, nftId, initialPrice);
    }

    /// @notice Function to check the owner of an NFT
    /// @param nftContractAddress Address of the NFT contract
    /// @param nftId Id of the NFT contract
    /// @return true if the owner is the sender, false otherwise
    function checkOwnerOfNFT(
        address nftContractAddress,
        uint256 nftId
    ) public view returns (bool) {
        address checkAddress = IERC721(nftContractAddress).ownerOf(nftId);
        return (checkAddress == msg.sender);
    }

    /// @notice Function for a user to bid in an English auction
    /// @param id The list id of the English Auction
    /// @param sendingValue Bid amount
    function makeBidToEnglishAuction(uint256 id, uint256 sendingValue) external {
        require(cancelListingState[id] == false, "Listing Cancelled.");
        require(
            englishAuctions.length > id,
            "Not listed in the english auction list."
        );
        uint256 listedId = englishAuction_listedNumber[id];
        require(listedNFTs[listedId].endState == false, "Already sold out.");
        // address contractAddress = listedNFTs[listedId].nftContractAddress;
        // uint256 nftId = listedNFTs[listedId].nftId;
        uint256 price = englishAuctions[id].currentPrice;
        address currentWinner = englishAuctions[id].currentWinner;
        require(
            sendingValue > price,
            "You should send a price that is more than current price."
        );
        if(sendingValue > 0) SafeERC20.safeTransferFrom(USDC_token, msg.sender, address(this), sendingValue) ;
        englishAuction_balancesForWithdraw[id][currentWinner] += price;
        englishAuctions[id].currentPrice = sendingValue;
        englishAuctions[id].currentWinner = msg.sender;
        emit NewBidToEnglishAuction(id, sendingValue, currentWinner);
    }

    /// @notice Function to withdraw funds from an English auction
    /// @param id The list id of the English Auction
    function withdrawFromEnglishAuction(uint256 id) external {
        require(
            englishAuctions.length > id,
            "Not listed in the english auction list."
        );
        uint256 amount = englishAuction_balancesForWithdraw[id][msg.sender];
        require(amount > 0, "You don't have any balance.");
        englishAuction_balancesForWithdraw[id][msg.sender] = 0;
        SafeERC20.safeTransfer(USDC_token, msg.sender, amount);
        emit NewWithdrawFromEnglishAuction(id, msg.sender, amount);
    }

    /// @notice Function to end an English auction
    /// @param _nftAddress Address of the NFT contract
    /// @param _nftId Id of the NFT contract
    function endEnglishAuction(address _nftAddress, uint256 _nftId) external {
        uint256 id;
        bool flg = false;
        for (uint256 i = 0; i < englishAuctions.length; i++) {
            uint256 tmp_Id = englishAuction_listedNumber[i];
            if (
                listedNFTs[tmp_Id].nftContractAddress == _nftAddress &&
                listedNFTs[tmp_Id].nftId == _nftId
            ) {
                id = i;
                flg = true;
                break;
            }
        }
        require(flg, "Wrong nft");
        require(cancelListingState[id] == false, "Listing Cancelled.");
        require(
            englishAuctions.length > id,
            "Not listed in the english auction list."
        );
        uint256 listedId = englishAuction_listedNumber[id];
        uint256 expectEndTime = listedNFTs[listedId].startTime +
            englishAuctions[id].salePeriod;
        require(expectEndTime < block.timestamp, "Auction is not ended!");
        address contractAddress = listedNFTs[listedId].nftContractAddress;
        uint256 nftId = listedNFTs[listedId].nftId;
        uint256 price = englishAuctions[id].currentPrice;
        address currentOwner = listedNFTs[listedId].currentOwner;
        require(
            msg.sender == currentOwner,
            "Only current Owner is allowed to end the auction."
        );
        uint256 loyaltyFee;
        loyaltyFee = (price * percentForLoyaltyFee) / 100;
        IContentNFT(contractAddress).setLoyaltyFee(nftId, loyaltyFee);
        if (IContentNFT(contractAddress).creators(nftId) == currentOwner)
            loyaltyFee = 0;
        IERC20(USDC).approve(address(contractAddress), loyaltyFee);
        IContentNFT(contractAddress).transferFrom(
            currentOwner,
            englishAuctions[id].currentWinner,
            nftId
        );
        recordRevenue(currentOwner, price - loyaltyFee, contractAddress, nftId);
        listedNFTs[listedId].endState = true;
        listedNFTs[listedId].endTime = block.timestamp;
        emit BuyEnglishAuction(
            englishAuctions[id].currentWinner,
            contractAddress,
            nftId,
            price,
            block.timestamp
        );
    }

    /// @notice Function for a user to buy in a Dutch auction
    /// @param id The list id of the Dutch Auction
    /// @param sendingValue Bid amount
    function buyDutchAuction(uint256 id, uint256 sendingValue) external {
        require(cancelListingState[id] == false, "Listing Cancelled.");
        require(
            dutchAuctions.length > id,
            "Not listed in the dutch auction list."
        );
        uint256 listedId = dutchAuction_listedNumber[id];
        require(listedNFTs[listedId].endState == false, "Already sold out.");
        address contractAddress = listedNFTs[listedId].nftContractAddress;
        uint256 nftId = listedNFTs[listedId].nftId;
        address currentOwner = listedNFTs[listedId].currentOwner;
        uint256 price = getDutchAuctionPrice(id);
        require(sendingValue == price, "Not exact fee");
        if(sendingValue > 0) SafeERC20.safeTransferFrom(USDC_token, msg.sender, address(this), sendingValue);
        uint256 loyaltyFee;
        loyaltyFee = (price * percentForLoyaltyFee) / 100;
        IContentNFT(contractAddress).setLoyaltyFee(nftId, loyaltyFee);
        if (IContentNFT(contractAddress).creators(nftId) == currentOwner)
            loyaltyFee = 0;
        IERC20(USDC).approve(address(contractAddress), loyaltyFee);
        IContentNFT(contractAddress).transferFrom(
            currentOwner,
            msg.sender,
            nftId
        );
        recordRevenue(currentOwner, price - loyaltyFee, contractAddress, nftId);
        listedNFTs[listedId].endState = true;
        listedNFTs[listedId].endTime = block.timestamp;
        emit BuyDutchAuction(
            msg.sender,
            contractAddress,
            nftId,
            price,
            block.timestamp
        );
    }

    /// @notice Function to get the current price in a Dutch auction
    /// @param id The list id of the Dutch Auction
    /// @return The current price in a Dutch auction of specified NFT

    function getDutchAuctionPrice(uint256 id) public view returns (uint256) {
        uint256 listedId = dutchAuction_listedNumber[id];
        uint256 duration = 3600;
        uint256 price = dutchAuctions[id].initialPrice -
            ((block.timestamp - listedNFTs[listedId].startTime) / duration) *
            dutchAuctions[id].reducingRate;
        return price;
    }

    /// @notice Function for a user to bid in an offering sale
    /// @param id The list id of the Offering Sale
    /// @param sendingValue Bid amount
    function makeBidToOfferingSale(uint256 id, uint256 sendingValue) external {
        require(cancelListingState[id] == false, "Listing Cancelled.");
        require(
            offeringSales.length > id,
            "Not listed in the offering sale list."
        );
        uint256 listedId = offeringSale_listedNumber[id];
        require(listedNFTs[listedId].endState == false, "Already sold out.");
        address contractAddress = listedNFTs[listedId].nftContractAddress;
        uint256 nftId = listedNFTs[listedId].nftId;
        address currentOwner = listedNFTs[listedId].currentOwner;
        uint256 price = offeringSales[id].initialPrice;
        require(
            sendingValue >= price,
            "You should send a price that is more than current price."
        );
        offeringSales[id].bidNumber++;
        if(sendingValue > 0) SafeERC20.safeTransferFrom(USDC_token, msg.sender, address(this), sendingValue);
        offeringSale_currentBids[id][msg.sender] = sendingValue;
        offeringSale_balancesForWithdraw[id][msg.sender] += sendingValue;
        // call the CreatorGroup's function
        ICreatorGroup(currentOwner).submitOfferingSaleTransaction(
            id,
            contractAddress,
            nftId,
            msg.sender,
            sendingValue
        );
        emit NewBidToOfferingSale(id, msg.sender, sendingValue);
    }

    /// @notice Function to withdraw funds from an offering sale
    /// @param id The list id of the Offering Sale
    function withdrawFromOfferingSale(uint256 id) external {
        require(
            offeringSales.length > id,
            "Not listed in the offering sale list."
        );
        // uint256 listedId = offeringSale_listedNumber[id];
        uint256 listedId = offeringSale_listedNumber[id];
        require(listedNFTs[listedId].endState == true, "Not finished yet");
        uint256 amount = offeringSale_balancesForWithdraw[id][msg.sender];
        require(amount > 0, "You don't have any balance.");
        offeringSale_balancesForWithdraw[id][msg.sender] = 0;
        if(amount > 0) SafeERC20.safeTransfer(USDC_token, msg.sender, amount) ;
        emit NewWithdrawFromOfferingSale(id, msg.sender, amount);
    }

    /// @notice Function to end an offering sale
    /// @param id The list id of the Offering Sale
    /// @param buyer The address of the buyer
    function endOfferingSale(uint256 id, address buyer) external {
        require(cancelListingState[id] == false, "Listing Cancelled.");
        require(
            offeringSales.length > id,
            "Not listed in the offering sale list."
        );
        uint256 listedId = offeringSale_listedNumber[id];
        uint256 price = offeringSale_currentBids[id][buyer];
        require(price > 0, "Buyer doesn't have any bid.");
        address contractAddress = listedNFTs[listedId].nftContractAddress;
        uint256 nftId = listedNFTs[listedId].nftId;
        require(
            checkOwnerOfNFT(contractAddress, nftId) == true,
            "only the nft owner can call this function"
        );
        uint256 loyaltyFee;
        loyaltyFee = (price * percentForLoyaltyFee) / 100;
        IContentNFT(contractAddress).setLoyaltyFee(nftId, loyaltyFee);
        if (IContentNFT(contractAddress).creators(nftId) == msg.sender)
            loyaltyFee = 0;
        IERC20(USDC).approve(address(contractAddress), loyaltyFee);
        IContentNFT(contractAddress).transferFrom(msg.sender, buyer, nftId);
        recordRevenue(msg.sender, price - loyaltyFee, contractAddress, nftId);
        listedNFTs[listedId].endState = true;
        listedNFTs[listedId].endTime = block.timestamp;
        offeringSale_balancesForWithdraw[id][buyer] -= price;
        emit BuyOfferingSale(
            buyer,
            contractAddress,
            nftId,
            price,
            block.timestamp
        );
    }

    /// @notice Function to cancel a listing
    /// @param _nftContractAddress The address of the NFT contract
    /// @param _nftId The ID of the NFT
    function cancelListing(address _nftContractAddress, uint256 _nftId) external {
        require(
            checkOwnerOfNFT(_nftContractAddress, _nftId) == true,
            "only the nft owner can call this function"
        );
        uint256 id;
        for (uint256 i = 0; i < listedNFTs.length; i++) {
            if (
                listedNFTs[i].nftContractAddress == _nftContractAddress &&
                listedNFTs[i].nftId == _nftId
            ) {
                id = i;
                break;
            }
        }
        require(listedNFTs[id].endState == false, "Already sold out!");
        uint256 listId = listedNFTs[id].Id;
        require(
            !(listedNFTs[id]._saleType == SaleType.ENGLISH_AUCTION &&
                englishAuctions[listId].currentPrice !=
                englishAuctions[listId].initialPrice),
            "Already english auction started!"
        );
        require(
            !(listedNFTs[id]._saleType == SaleType.OFFERING_SALE &&
                offeringSales[listId].bidNumber > 0),
            "Already sale offering started!"
        );
        cancelListingState[id] = true;
        emit CanceledListing(id, msg.sender);
    }

    /// @notice Function to get the number of Listed NFTs
    /// @return The number of Listed NFTs
    function getListedNumber() external view returns (uint256) {
        return listedNFTs.length;
    }

    /// @notice Function to get the number of English Auctions
    /// @return The number of English Auctions
    function getListedEnglishAuctionNumber() external view returns (uint256) {
        return englishAuctions.length;
    }

    /// @notice Function to get the number of Dutch Auctions
    /// @return The number of Dutch Auctions
    function getListedDutchAuctionNumber() external view returns (uint256) {
        return dutchAuctions.length;
    }

    /// @notice Function to get the number of Offering Sales
    /// @return The number of Offering Sales
    function getOfferingSaleAuctionNumber() external view returns (uint256) {
        return offeringSales.length;
    }

    /// @notice Function to get withdraw balance for English Auction
    /// @param id The id of the listed English Auction
    /// @param to The address of the withdrawal account
    /// @return The amount of withdraw for English Auction
    function withdrawBalanceForEnglishAuction(
        uint256 id,
        address to
    ) external view returns (uint256) {
        return englishAuction_balancesForWithdraw[id][to];
    }

    /// @notice Function to get withdraw balance for Offering Sale
    /// @param id The id of the listed Offering Sale
    /// @param to The address of the withdrawal account
    /// @return The amount of withdraw for Offering Sale
    function withdrawBalanceForOfferingSale(
        uint256 id,
        address to
    ) external view returns (uint256) {
        return offeringSale_balancesForWithdraw[id][to];
    }
}
