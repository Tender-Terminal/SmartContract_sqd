import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from 'chai';
import creatorGroupABI from "./creatorGroup.json";
import contentNFTABI from "./contentNFT.json";
let USDC_Address: any;
let USDC_Contract: any;
let Marketplace: any;
let Marketplace_Address: any;
let Factory: any;
let Factory_Address: any;
let owner: any;
let user1: any;
let user2: any;
let user3:  any;
let developmentTeam: any;
let buyer1: any ;
let buyer2: any ;
const percentForSeller:number = 85;
const mintFee:number = 0;
const burnFee:number = 0;
describe("Create Initial Contracts of all types", function () {
     
    it("get accounts", async function () {
        [owner, user1, user2, developmentTeam, buyer1, buyer2, user3] = await ethers.getSigners();
        console.log("\tAccount address\t", await owner.getAddress());
    })
    it("should deploy USDC Contract", async function () {
        const instanceUSDC = await ethers.getContractFactory("USDCToken");
        USDC_Contract = await instanceUSDC.deploy(1e6);
        USDC_Address = await USDC_Contract.getAddress();
        console.log('\tUSDC Contract deployed at:', USDC_Address);
    })
    it("should deploy Marketplace Contract", async function () {
        const instanceMarketplace = await ethers.getContractFactory("Marketplace");
        Marketplace = await instanceMarketplace.deploy(developmentTeam, percentForSeller, USDC_Address);
        Marketplace_Address = await Marketplace.getAddress();
        console.log('\tMarketplace Contract deployed at:', Marketplace_Address);
    })
    it("should deploy Factory Contract", async function () {
        const instanceGroup = await ethers.getContractFactory("CreatorGroup");
        const Group = await instanceGroup.deploy();
        const Group_Address = await Group.getAddress();
        const instanceContent = await ethers.getContractFactory("ContentNFT");
        const Content = await instanceContent.deploy();
        const Content_Address = await Content.getAddress();
        const instanceFactory = await ethers.getContractFactory("Factory");
        Factory = await instanceFactory.deploy(Group_Address, Content_Address, Marketplace_Address, developmentTeam, mintFee, burnFee, USDC_Address);
        Factory_Address = await Factory.getAddress();
        console.log('\tFactory Contract deployed at:', Factory_Address);
    })
})
let group_address:any ;
let creatorGroup:any;
const amount:number = 5000;
let firstNFTAddress:any;
describe("test creating CreatorGroup contracts and mint & burn NFTs", async function(){
    
    it("Create first CreatorGroup", async function(){

        await Factory.createGroup("Top_Artists", "We are all NFT artists", [user2, user1], 2);
        group_address = await Factory.getCreatorGroupAddress(0);
        console.log("\tCreatorGroup address\t", group_address);
        creatorGroup = new ethers.Contract(group_address, creatorGroupABI, ethers.provider) ;
    })
    
    it("sending USDC to the users", async function(){
        await USDC_Contract.approve(user1, amount) ;
        await USDC_Contract.approve(user2, amount) ;
        await USDC_Contract.approve(buyer1, amount) ;
        await USDC_Contract.approve(buyer2, amount) ;

        await USDC_Contract.connect(user1).transferFrom(owner, user1, amount) ;
        await USDC_Contract.connect(user2).transferFrom(owner, user2, amount) ;
        await USDC_Contract.connect(buyer1).transferFrom(owner, buyer1, amount) ;
        await USDC_Contract.connect(buyer2).transferFrom(owner, buyer2, amount) ;
        await USDC_Contract.connect(user1).approve(user1, 200) ;
        await USDC_Contract.connect(user1).transferFrom(user1, group_address, 200) ;

        console.log("\tUSDC sent to user1\t", await USDC_Contract.balanceOf(user1));
        console.log("\tUSDC sent to user2\t", await USDC_Contract.balanceOf(user2));
        console.log("\tUSDC sent to group_address\t", await USDC_Contract.balanceOf(group_address));
    })

    it("set Director First", async function(){
        await creatorGroup.connect(user1).submitDirectorSettingTransaction(user1) ;
        await creatorGroup.connect(user1).confirmDirectorSettingTransaction(0, true) ;
        await creatorGroup.connect(user2).confirmDirectorSettingTransaction(0, true) ;
        await creatorGroup.connect(user2).excuteDirectorSettingTransaction(0) ;
        const addresOfDirector = await creatorGroup.director() ;
        console.log("\taddress of user1\t", await user1.getAddress());
        console.log("\taddress of director\t", addresOfDirector);
    })

    it("mint First NFT in the CreatorGroup", async function(){
        await creatorGroup.connect(user1).mintNew("ipfs://firstToken", "Nature", "DDD", "Oh my god, it's beautiful") ;
        const nftId = await creatorGroup.getNftOfId(0) ;
        console.log("\tNFT id\t", nftId);
        firstNFTAddress = await creatorGroup.getNftAddress(0) ;
        console.log("\tNFT address\t", firstNFTAddress);
    })

    it("check nft values in nft contract", async function(){
        const nft = new ethers.Contract(firstNFTAddress, contentNFTABI, ethers.provider) ;
        const name = await nft.name() ;
        console.log("\tNFT name\t", name);
        const symbol = await nft.symbol() ;
        console.log("\tNFT symbol\t", symbol);
        const description = await nft.description() ;
        console.log("\tNFT description\t", description);
        const imageURI = await nft.tokenURI(1) ;
        console.log("\t1 NFT imageURI\t", imageURI);
    })

    it("mint second NFT to the Nature NFT Collection", async function(){
        await creatorGroup.connect(user1).mint("ipfs://secondToken",firstNFTAddress) ;
    })

    it("check nft values in nft contract", async function(){
        const nft = new ethers.Contract(firstNFTAddress, contentNFTABI, ethers.provider) ;
        const imageURI = await nft.tokenURI(2) ;
        console.log("\t2 NFT imageURI\t", imageURI);
    })

    it("mint third NFT to the Nature NFT Collection", async function(){
        await creatorGroup.connect(user1).mint("ipfs://thirdToken",firstNFTAddress) ;
    })

    it("check nft values in nft contract", async function(){
        const nft = new ethers.Contract(firstNFTAddress, contentNFTABI, ethers.provider) ;
        const imageURI = await nft.tokenURI(3) ;
        console.log("\t3 NFT imageURI\t", imageURI);
    })

    // it("burn second NFT to the Nature NFT Collection", async function(){
    //     const before_numberOfNFT = await creatorGroup.numberOfNFT() ;
    //     console.log("\tBefore Burn -> NFT number\t", before_numberOfNFT);
    //     await creatorGroup.connect(user1).burn(1) ;
    //     const after_numberOfNFT = await creatorGroup.numberOfNFT() ;
    //     console.log("\tfter Burn -> tNFT number\t", after_numberOfNFT);
    // })

    it("check USDC balance of each addresses", async function(){
        const user1_balance = await USDC_Contract.balanceOf(user1) ;
        console.log("\tUSDC balance of user1\t", user1_balance);
        const user2_balance = await USDC_Contract.balanceOf(user2) ;
        console.log("\tUSDC balance of user2\t", user2_balance);
        const group_address_balance = await USDC_Contract.balanceOf(group_address) ;
        console.log("\tUSDC balance of group_address\t", group_address_balance);
        const factory_address_balance = await USDC_Contract.balanceOf(Factory_Address) ;
        console.log("\tUSDC balance of factory_address\t", factory_address_balance);
    })
})

describe("listing EnglishAuction & biding & endAuction", async function(){
    it("list to English Auction", async function(){
        await creatorGroup.connect(user1).listToEnglishAuction(0, 200, 300) ;
    })
    it("make a bid to the NFT", async function(){
        await USDC_Contract.connect(buyer1).approve(Marketplace_Address, 350) ;
        await Marketplace.connect(buyer1).makeBidToEnglishAuction(0, 350) ;
        await USDC_Contract.connect(buyer2).approve(Marketplace_Address, 400) ;
        await Marketplace.connect(buyer2).makeBidToEnglishAuction(0, 400) ;
    })
    it("end English Auction", async function(){
        await time.increaseTo(await time.latest() + 3600) ;
        await creatorGroup.connect(user1).endEnglishAuction(0) ;
    })
    it("withdraw after english Auctin ended", async function(){
        await Marketplace.connect(buyer1).withdrawFromEnglishAuction(0) ;
        await creatorGroup.connect(user1).withdrawFromMarketplace();
    })
    it("check USDC balance of each addresses", async function(){
        const buyer1_balance = await USDC_Contract.balanceOf(buyer1) ;
        console.log("\tUSDC balance of buyer1\t", buyer1_balance);
        const buyer2_balance = await USDC_Contract.balanceOf(buyer2) ;
        console.log("\tUSDC balance of buyer2\t", buyer2_balance);
        const group_address_balance = await USDC_Contract.balanceOf(group_address) ;
        console.log("\tUSDC balance of group_address\t", group_address_balance);
        const factory_address_balance = await USDC_Contract.balanceOf(Factory_Address) ;
        console.log("\tUSDC balance of factory_address\t", factory_address_balance);
    })
})
describe("listing DutchAuction & biding", async function(){
    it("list to Dutch Auction", async function(){
        await creatorGroup.connect(user1).listToDutchAuction(1, 1000, 100, 28800) ;
    })
    it("buyer1 buy Dutch Auction", async function(){
        await time.increaseTo(await time.latest() + 3650) ;
        const value = await Marketplace.getDutchAuctionPrice(0) ;
        USDC_Contract.connect(buyer1).approve(Marketplace_Address, value) ;
        await Marketplace.connect(buyer1).buyDutchAuction(0, value) ;
    })
    it("check USDC balance of each addresses", async function(){
        const buyer1_balance = await USDC_Contract.balanceOf(buyer1) ;
        console.log("\tUSDC balance of buyer1\t", buyer1_balance);
    })
})

describe("listing SaleOffering & biding & endAuction", async function(){
    it("list to Sale Offering", async function(){
        await creatorGroup.connect(user1).listToOfferingSale(2, 1500) ;
    })
    it("buyer1 make a bid to the Offering", async function(){
        await USDC_Contract.connect(buyer1).approve(Marketplace_Address, 1600) ;
        await Marketplace.connect(buyer1).makeBidToOfferingSale(0, 1600) ;
    })
    it("buyer2 make a bid to the Offering", async function(){
        await USDC_Contract.connect(buyer2).approve(Marketplace_Address, 1700) ;
        await Marketplace.connect(buyer2).makeBidToOfferingSale(0, 1700) ;
    })
    it("confirm transactions", async function(){
        await creatorGroup.connect(user1).confirmOfferingSaleTransaction(1, true) ;
        await creatorGroup.connect(user2).confirmOfferingSaleTransaction(1, true) ;
        await creatorGroup.connect(user1).excuteOfferingSaleTransaction(1) ;
    })
    it("withdraw after english Auctin ended", async function(){
        await Marketplace.connect(buyer1).withdrawFromOfferingSale(0) ;
    })
    it("check USDC balance of each addresses", async function(){
        const buyer1_balance = await USDC_Contract.balanceOf(buyer1) ;
        console.log("\tUSDC balance of buyer1\t", buyer1_balance);
        const buyer2_balance = await USDC_Contract.balanceOf(buyer2) ;
        console.log("\tUSDC balance of buyer2\t", buyer2_balance);
    })
})

describe("Check how to distributed revenues", async function(){
    it("withdraw from Marketplace", async function(){
        await creatorGroup.connect(user1).withdrawFromMarketplace() ;
    })
    it("check the balance of each address", async function(){
        const user1_balance = await creatorGroup.balance(user1) ;
        console.log("\tuser1_balance: " + user1_balance) ;
        const user2_balance = await creatorGroup.balance(user2) ;
        console.log("\tuser2_balance: " + user2_balance) ;
    })
    it("check sold value and each earning", async function(){
        const count = await creatorGroup.getSoldNumber() ;
        console.log("\tcount: " + count) ;
        let id:number ;
        for(id = 0 ; id < count ; id ++){
            const soldInformation = await creatorGroup.getSoldInfor(id) ;
            console.log("\tid: " + soldInformation.id) ;
            console.log("\tprice: " + soldInformation.price) ;
            console.log("\tdistributeState: " + soldInformation.distributeState) ;
        }
        const groupNumber = await creatorGroup.numberOfMembers() ;
        for(id = 0 ; id < groupNumber ; id ++){
            const member = await creatorGroup.members(id) ;
            console.log("\taddress: " + member) ;
            let each:number ;
            for(each = 0 ; each < count ; each ++){
                const value = await creatorGroup.getRevenueDistribution(member, each) ;
                console.log("\tvalue: " + value) ;
            }
        }
    })
})
describe("check cancel listing", async function () {
    it("mint fourth NFT to the Nature NFT Collection", async function () {
        await creatorGroup.connect(user1).mint("ipfs://fourthToken", firstNFTAddress);
    })
    it("list to English Auction", async function () {
        await creatorGroup.connect(user1).listToEnglishAuction(3, 200, 300);
    })
    it("make a bid to the NFT", async function () {
        await USDC_Contract.connect(buyer1).approve(Marketplace_Address, 350);
        await Marketplace.connect(buyer1).makeBidToEnglishAuction(1, 350);
        await USDC_Contract.connect(buyer2).approve(Marketplace_Address, 400);
        await Marketplace.connect(buyer2).makeBidToEnglishAuction(1, 400);
    })
    it("cancel listing fourth nft", async function () {
        try {
            await creatorGroup.connect(user1).cancelListing(3);
        } catch (error: any) {
            expect(error.message).contain("Already english auction started!");
        }
    })

})
describe("In creatorGroup contract, withdraw all balances", async function(){
    it("check the balance of each address", async function(){
        const user1_balance = await creatorGroup.balance(user1) ;
        console.log("\tuser1_balance: " + user1_balance) ;
        const user2_balance = await creatorGroup.balance(user2) ;
        console.log("\tuser2_balance: " + user2_balance) ;
    })
    it("withdraw all balances", async function(){
        await creatorGroup.connect(user1).withdraw() ;
        await creatorGroup.connect(user2).withdraw() ;
    })
    it("check the balance of each address", async function(){
        const user1_balance = await creatorGroup.balance(user1) ;
        console.log("\tuser1_balance: " + user1_balance) ;
        const user2_balance = await creatorGroup.balance(user2) ;
        console.log("\tuser2_balance: " + user2_balance) ;
    })
    it("check balance of CreatorGroup Contract", async function(){
        const group_balance = await USDC_Contract.balanceOf(group_address) ;
        console.log("\tUSDC balance of group\t", group_balance);
    })
})
describe("withdraw all of balances in Factory and Marketplace Contract from Development Team", async function(){
    it("check current balance of development Team wallet", async function(){
        const developmentTeam_balance = await USDC_Contract.balanceOf(developmentTeam) ;
        console.log("\tUSDC balance of developmentTeam\t", developmentTeam_balance);
    })
    it("withdraw from Marketplace", async function(){
        await Marketplace.connect(developmentTeam).withdraw() ;
        const developmentTeam_balance = await USDC_Contract.balanceOf(developmentTeam) ;
        console.log("\tUSDC balance of developmentTeam\t", developmentTeam_balance);
    })
    it("withdraw from Factory", async function(){
        await Factory.connect(developmentTeam).withdraw() ;
        const developmentTeam_balance = await USDC_Contract.balanceOf(developmentTeam) ;
        console.log("\tUSDC balance of developmentTeam\t", developmentTeam_balance);
    })
})

describe("add member to the group processing happen", async function(){
    it("add member to the group", async function(){
        await creatorGroup.connect(user1).addMember(user3) ;
    })
    it("end the EnglishAuction of Fourth NFT", async function(){
        await time.increaseTo(await time.latest() + 3600) ;
        await creatorGroup.connect(user1).endEnglishAuction(3) ;
    })
    it("mint fifth nft", async function(){
        await creatorGroup.connect(user1).mint("ipfs://fifthToken",firstNFTAddress) ;
    })
    it("lits fifth nft to the Dutch Auction", async function(){
        await creatorGroup.connect(user1).listToDutchAuction(4, 1000, 100, 28800) ;
    })
    it("buyer1 buy DutchAuction nft", async function(){
        await time.increaseTo(await time.latest() + 3650) ;
        const value = await Marketplace.getDutchAuctionPrice(1) ;
        USDC_Contract.connect(buyer1).approve(Marketplace_Address, value) ;
        await Marketplace.connect(buyer1).buyDutchAuction(1, value) ;
    })
    // it("check current balance", async function(){
    //     const user1_balance = await USDC_Contract.balanceOf(user1) ;
    //     console.log("\tUSDC balance of user1\t", user1_balance);
    //     const user2_balance = await USDC_Contract.balanceOf(user2) ; 
    //     console.log("\tUSDC balance of user2\t", user2_balance);
    //     const user3_balance = await USDC_Contract.balanceOf(user3) ;
    //     console.log("\tUSDC balance of user3\t", user3_balance);
    // })
    it("check the balance of each address", async function(){
        const user1_balance = await creatorGroup.balance(user1) ;
        console.log("\tuser1_balance: " + user1_balance) ;
        const user2_balance = await creatorGroup.balance(user2) ;
        console.log("\tuser2_balance: " + user2_balance) ;
    })
    it("withdraw from Marketplace", async function(){
        await creatorGroup.connect(user1).withdrawFromMarketplace() ;
    })
    
    it("check sold value and each earning", async function(){
        const count = await creatorGroup.getSoldNumber() ;
        console.log("\tcount: " + count) ;
        let id:number ;
        for(id = 0 ; id < count ; id ++){
            const soldInformation = await creatorGroup.getSoldInfor(id) ;
            console.log("\tid: " + soldInformation.id) ;
            console.log("\tprice: " + soldInformation.price) ;
            console.log("\tdistributeState: " + soldInformation.distributeState) ;
        }
        const groupNumber = await creatorGroup.numberOfMembers() ;
        for(id = 0 ; id < groupNumber ; id ++){
            const member = await creatorGroup.members(id) ;
            console.log("\taddress: " + member) ;
            let each:number ;
            for(each = 0 ; each < count ; each ++){
                const value = await creatorGroup.getRevenueDistribution(member, each) ;
                console.log("\tvalue: " + value) ;
            }
        }       
    })
    it("check the balance of each address", async function(){
        const user1_balance = await creatorGroup.balance(user1) ;
        console.log("\tuser1_balance: " + user1_balance) ;
        const user2_balance = await creatorGroup.balance(user2) ;
        console.log("\tuser2_balance: " + user2_balance) ;
        const balance_user3 = await creatorGroup.balance(user3) ;
        console.log("\tbalance_user3: " + balance_user3);
    })
})