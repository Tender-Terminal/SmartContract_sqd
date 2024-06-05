// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICreatorGroup.sol";
import "./interfaces/IContentNFT.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract Marketplace is ReentrancyGuard {
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
        require(_percentForSeller <= 100 && _percentForSeller != 0, "Invalid percentage");
        percentForSeller = _percentForSeller;
        balanceOfDevelopmentTeam = 0;
         require(_USDC!= address(0), "Invalid address");
        USDC = _USDC;
        USDC_token = IERC20(USDC) ;
        percentForLoyaltyFee = 5;
    }

    /// @notice Function to list an NFT to an English auction
    /// @param _nftContractAddress Address of the NFT contract
    /// @param _nftId TokenId of the NFT contract
    /// @param _initialPrice Initial price of the NFT
    /// @param _salePeriod Sale period of the NFT
    function listToEnglishAuction(
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _initialPrice,
        uint256 _salePeriod
    ) external {
        require(
            checkOwnerOfNFT(_nftContractAddress, _nftId) == true,
            "Invalid token owner"
        );
        uint256 id = englishAuctions.length;
        englishAuction memory newAuction = englishAuction(
            _initialPrice,
            _salePeriod,
            address(0),
            _initialPrice
        );
        englishAuctions.push(newAuction);
        listedNFT memory newListing = listedNFT(
            SaleType.ENGLISH_AUCTION,
            id,
            msg.sender,
            _nftContractAddress,
            _nftId,
            block.timestamp,
            0,
            false
        );
        englishAuction_listedNumber[id] = listedNFTs.length;
        listedNFTs.push(newListing);
        emit NewEnglishAuctionListing(
            _nftContractAddress,
            _nftId,
            _initialPrice,
            _salePeriod
        );
    }

    /// @notice Function to list an NFT to a Dutch auction
    /// @param _nftContractAddress Address of the NFT contract
    /// @param _nftId TokenId of the NFT contract
    /// @param _initialPrice Initial price of the NFT
    /// @param _reducingRate The reducing rate per hour
    /// @param _salePeriod Sale period of the NFT
    function listToDutchAuction(
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _initialPrice,
        uint256 _reducingRate,
        uint256 _salePeriod
    ) external {
        require(
            checkOwnerOfNFT(_nftContractAddress, _nftId) == true,
            "Invalid token owner"
        );
        require(
            _initialPrice > _reducingRate * (_salePeriod / 3600),
            "Invalid information for Dutch Auction!"
        );
        uint256 id = dutchAuctions.length;
        dutchAuction memory newAuction = dutchAuction(
            _initialPrice,
            _reducingRate,
            _salePeriod
        );
        dutchAuctions.push(newAuction);
        listedNFT memory newListing = listedNFT(
            SaleType.DUTCH_AUCTION,
            id,
            msg.sender,
            _nftContractAddress,
            _nftId,
            block.timestamp,
            0,
            false
        );
        dutchAuction_listedNumber[id] = listedNFTs.length;
        listedNFTs.push(newListing);
        emit NewDutchAuctionListing(
            _nftContractAddress,
            _nftId,
            _initialPrice,
            _reducingRate,
            _salePeriod
        );
    }

    /// @notice Function to list an NFT for an offering sale
    /// @param _nftContractAddress Address of the NFT contract
    /// @param _nftId TokenId of the NFT contract
    /// @param _initialPrice Initial price of the NFT
    function listToOfferingSale(
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _initialPrice
    ) external {
        require(
            checkOwnerOfNFT(_nftContractAddress, _nftId) == true,
            "Invalid token owner"
        );
        uint256 id = offeringSales.length;
        offeringSale memory newSale = offeringSale(_initialPrice, 0);
        offeringSales.push(newSale);
        listedNFT memory newListing = listedNFT(
            SaleType.OFFERING_SALE,
            id,
            msg.sender,
            _nftContractAddress,
            _nftId,
            block.timestamp,
            0,
            false
        );
        offeringSale_listedNumber[id] = listedNFTs.length;
        listedNFTs.push(newListing);
        emit NewOfferingSaleListing(_nftContractAddress, _nftId, _initialPrice);
    }

    /// @notice Function to check the owner of an NFT
    /// @param _nftContractAddress Address of the NFT contract
    /// @param _nftId Id of the NFT contract
    /// @return true if the owner is the sender, false otherwise
    function checkOwnerOfNFT(
        address _nftContractAddress,
        uint256 _nftId
    ) public view returns (bool) {
        address checkAddress = IERC721(_nftContractAddress).ownerOf(_nftId);
        return (checkAddress == msg.sender);
    }

    /// @notice Function for a user to bid in an English auction
    /// @param _id The list id of the English Auction
    /// @param _sendingValue Bid amount
    function makeBidToEnglishAuction(uint256 _id, uint256 _sendingValue) external {
        require(
            englishAuctions.length > _id && _id >= 0,
            "Not listed in the english auction list."
        );
        uint256 listedId = englishAuction_listedNumber[_id];
        require(cancelListingState[listedId] == false, "Listing Cancelled.");
        uint256 expectEndTime = listedNFTs[listedId].startTime +
        englishAuctions[_id].salePeriod;
        require(expectEndTime > block.timestamp, "Auction ended!");
        require(listedNFTs[listedId].endState == false, "Already sold out.");
        uint256 price = englishAuctions[_id].currentPrice;
        address currentWinner = englishAuctions[_id].currentWinner;
        require(
            _sendingValue > price,
            "You should send a price that is more than current price."
        );
        if(_sendingValue != 0) SafeERC20.safeTransferFrom(USDC_token, msg.sender, address(this), _sendingValue) ;
        englishAuction_balancesForWithdraw[_id][currentWinner] += price;
        englishAuctions[_id].currentPrice = _sendingValue;
        englishAuctions[_id].currentWinner = msg.sender;
        emit NewBidToEnglishAuction(_id, _sendingValue, msg.sender);
    }

    /// @notice Function to withdraw funds from an English auction
    /// @param _id The list id of the English Auction
    function withdrawFromEnglishAuction(uint256 _id) external nonReentrant {
        require(
            englishAuctions.length > _id && _id >= 0,
            "Not listed in the english auction list."
        );
        uint256 amount = englishAuction_balancesForWithdraw[_id][msg.sender];
        require(amount != 0, "You don't have any balance.");
        englishAuction_balancesForWithdraw[_id][msg.sender] = 0;
        SafeERC20.safeTransfer(USDC_token, msg.sender, amount);
        emit NewWithdrawFromEnglishAuction(_id, msg.sender, amount);
    }

    /// @notice Function to end an English auction
    /// @param _nftContractAddress Address of the NFT contract
    /// @param _nftId Id of the NFT contract
    function endEnglishAuction(address _nftContractAddress, uint256 _nftId) external {
        uint256 id;
        bool flg = false;
        for (uint256 i = 0; i < englishAuctions.length; ++i) {
            uint256 tmp_Id = englishAuction_listedNumber[i];
            if (
                listedNFTs[tmp_Id].nftContractAddress == _nftContractAddress &&
                listedNFTs[tmp_Id].nftId == _nftId
            ) {
                id = i;
                flg = true;
                break;
            }
        }
        require(flg, "Wrong nft");
        require(
            englishAuctions.length > id && id >= 0,
            "Not listed in the english auction list."
        );
        uint256 listedId = englishAuction_listedNumber[id];
        require(cancelListingState[listedId] == false, "Listing Cancelled.");
        uint256 expectEndTime = listedNFTs[listedId].startTime +
            englishAuctions[id].salePeriod;
        require(expectEndTime < block.timestamp, "Auction is not ended!");
        address contractAddress = _nftContractAddress;
        uint256 nftId = _nftId;
        uint256 price = englishAuctions[id].currentPrice;
        uint256 initialPrice= englishAuctions[id].initialPrice;
        address currentOwner = listedNFTs[listedId].currentOwner;
        require(
            msg.sender == currentOwner,
            "Only current Owner is allowed to end the auction."
        );
        require(
            price > initialPrice,
            "No bidder!"
        );
        uint256 loyaltyFee;
        loyaltyFee = (price * percentForLoyaltyFee) / 100;
        IContentNFT(contractAddress).setLoyaltyFee(nftId, loyaltyFee);
        if (IContentNFT(contractAddress).creators(nftId) == currentOwner)
            loyaltyFee = 0;
        if(loyaltyFee != 0) {
            SafeERC20.forceApprove(USDC_token, contractAddress, loyaltyFee);
        }
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

    /// @notice Function to record revenue from a sale
    /// @param _seller Address of the seller
    /// @param _price Price of the NFT
    /// @param _nftContractAddress Address of the NFT contract
    /// @param _nftId TokenId of the NFT contract
    function recordRevenue(
        address _seller,
        uint256 _price,
        address _nftContractAddress,
        uint256 _nftId
    ) private {
        uint256 value = (_price * percentForSeller) / 100;
        balanceOfSeller[_seller] += value;
        balanceOfDevelopmentTeam += _price - value;
        ICreatorGroup(_seller).alarmSoldOut(_nftContractAddress, _nftId, value);
    }

    /// @notice Function for a user to buy in a Dutch auction
    /// @param _id The list id of the Dutch Auction
    /// @param _sendingValue Bid amount
    function buyDutchAuction(uint256 _id, uint256 _sendingValue) external {
        require(
            dutchAuctions.length > _id && _id >= 0,
            "Not listed in the dutch auction list."
        );
        uint256 listedId = dutchAuction_listedNumber[_id];
        require(cancelListingState[listedId] == false, "Listing Cancelled.");
        require(listedNFTs[listedId].endState == false, "Already sold out.");
        uint256 expectEndTime = listedNFTs[listedId].startTime +
        dutchAuctions[_id].salePeriod;
        require(expectEndTime > block.timestamp, "Auction ended!");
        address contractAddress = listedNFTs[listedId].nftContractAddress;
        uint256 nftId = listedNFTs[listedId].nftId;
        address currentOwner = listedNFTs[listedId].currentOwner;
        uint256 price = getDutchAuctionPrice(_id);
        require(_sendingValue == price, "Not exact fee");
        if(_sendingValue != 0) SafeERC20.safeTransferFrom(USDC_token, msg.sender, address(this), _sendingValue);
        uint256 loyaltyFee;
        loyaltyFee = (price * percentForLoyaltyFee) / 100;
        IContentNFT(contractAddress).setLoyaltyFee(nftId, loyaltyFee);
        if (IContentNFT(contractAddress).creators(nftId) == currentOwner)
            loyaltyFee = 0;
        if(loyaltyFee != 0) {
            SafeERC20.forceApprove(USDC_token, contractAddress, loyaltyFee);
        }
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

    /// @notice Function for a user to bid in an offering sale
    /// @param _id The list id of the Offering Sale
    /// @param _sendingValue Bid amount
    function makeBidToOfferingSale(uint256 _id, uint256 _sendingValue) external {
        require(
            offeringSales.length > _id && _id >= 0,
            "Not listed in the offering sale list."
        );
        uint256 listedId = offeringSale_listedNumber[_id];
        require(cancelListingState[listedId] == false, "Listing Cancelled.");
        require(listedNFTs[listedId].endState == false, "Already sold out.");
        address contractAddress = listedNFTs[listedId].nftContractAddress;
        uint256 nftId = listedNFTs[listedId].nftId;
        address currentOwner = listedNFTs[listedId].currentOwner;
        uint256 price = offeringSales[_id].initialPrice;
        require(
            _sendingValue >= price,
            "You should send a price that is more than current price."
        );
        offeringSales[_id].bidNumber++;
        if(_sendingValue != 0) SafeERC20.safeTransferFrom(USDC_token, msg.sender, address(this), _sendingValue);
        offeringSale_currentBids[_id][msg.sender] = _sendingValue;
        offeringSale_balancesForWithdraw[_id][msg.sender] += _sendingValue;
        // call the CreatorGroup's function
        ICreatorGroup(currentOwner).submitOfferingSaleTransaction(
            _id,
            contractAddress,
            nftId,
            msg.sender,
            _sendingValue
        );
        emit NewBidToOfferingSale(_id, msg.sender, _sendingValue);
    }

    /// @notice Function to withdraw funds from an offering sale
    /// @param _id The list id of the Offering Sale
    function withdrawFromOfferingSale(uint256 _id) external nonReentrant{
        require(
            offeringSales.length > _id && _id >= 0,
            "Not listed in the offering sale list."
        );
        uint256 listedId = offeringSale_listedNumber[_id];
        require(listedNFTs[listedId].endState == true, "Not finished yet");
        uint256 amount = offeringSale_balancesForWithdraw[_id][msg.sender];
        require(amount != 0, "You don't have any balance.");
        offeringSale_balancesForWithdraw[_id][msg.sender] = 0;
        if(amount != 0) SafeERC20.safeTransfer(USDC_token, msg.sender, amount) ;
        emit NewWithdrawFromOfferingSale(_id, msg.sender, amount);
    }

    /// @notice Function to end an offering sale
    /// @param _id The list id of the Offering Sale
    /// @param _buyer The address of the buyer
    function endOfferingSale(uint256 _id, address _buyer) external {
        require(
            offeringSales.length > _id && _id >= 0,
            "Not listed in the offering sale list."
        );
        uint256 listedId = offeringSale_listedNumber[_id];
        require(cancelListingState[listedId] == false, "Listing Cancelled.");
        require(listedNFTs[listedId].endState == false, "Already sold out!");
        uint256 price = offeringSale_currentBids[_id][_buyer];
        require(price != 0, "Buyer doesn't have any bid.");
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
        if(loyaltyFee != 0) {
            SafeERC20.forceApprove(USDC_token, contractAddress, loyaltyFee);
        }
        IContentNFT(contractAddress).transferFrom(msg.sender, _buyer, nftId);
        recordRevenue(msg.sender, price - loyaltyFee, contractAddress, nftId);
        listedNFTs[listedId].endState = true;
        listedNFTs[listedId].endTime = block.timestamp;
        offeringSale_balancesForWithdraw[_id][_buyer] -= price;
        emit BuyOfferingSale(
            _buyer,
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
        bool flag = false ;
        for (uint256 i = 0; i < listedNFTs.length; ++i) {
            if (
                listedNFTs[i].nftContractAddress == _nftContractAddress &&
                listedNFTs[i].nftId == _nftId
            ) {
                id = i;
                flag = true ;
                break;
            }
        }
        require(flag == true, "Not listed yet");
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
                offeringSales[listId].bidNumber != 0),
            "Already sale offering started!"
        );
        cancelListingState[id] = true;
        emit CanceledListing(id, msg.sender);
    }

    /// @notice Function to add balance to multiple users
    /// @param _members Array of addresses to add balance
    /// @param _values Array of values to add to the balance of each user
    /// @param _nftContractAddress Address of the NFT contract
    /// @param _nftId TokenId of the NFT contract
    function addBalanceOfUser(
        address[] memory _members,
        uint256[] memory _values,
        address _nftContractAddress,
        uint256 _nftId
    ) external {
        bool flag = false;
        for (uint256 i = 0; i < listedNFTs.length; ++i) {
            if (
                listedNFTs[i].nftContractAddress == _nftContractAddress &&
                listedNFTs[i].nftId == _nftId &&
                listedNFTs[i].currentOwner == msg.sender &&
                listedNFTs[i].endState == true
            ) {
                flag = true;
                break;
            }
        }
        require(flag == true, "Invalid address for adding revenue");
        for (uint256 i = 0; i < _members.length; ++i) {
            balanceOfUser[_members[i]] += _values[i];
        }
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
    function withdraw() external nonReentrant{
        require(msg.sender == developmentTeam, "Invalid withdrawer");
        uint amount = balanceOfDevelopmentTeam;
        balanceOfDevelopmentTeam = 0;
        if(amount != 0) SafeERC20.safeTransfer(USDC_token, msg.sender, amount) ;
        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Function to withdraw funds from a seller's balance
    function withdrawFromSeller() external nonReentrant{
        require(balanceOfSeller[msg.sender] != 0, "Invalid withdrawer");
        uint amount = balanceOfSeller[msg.sender];
        balanceOfSeller[msg.sender] = 0;
        if(amount != 0) SafeERC20.safeTransfer(USDC_token, msg.sender, amount) ;
        emit Withdrawal(msg.sender, amount);
    }
    /// @notice Function to get the balance of a specific user
    /// @param to Address to get the balance of user
    /// @return The balance of a specific user
    function getBalanceOfUser(address to) external view returns (uint256) {
        return balanceOfUser[to];
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
