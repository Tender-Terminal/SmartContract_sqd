
// Importing necessary functionalities from the Hardhat package.
import { ethers } from 'hardhat'

async function main() {
    // Retrieve the first signer, typically the default account in Hardhat, to use as the deployer.
    const [deployer] = await ethers.getSigners()
    const percentForSeller: number = 85;
    console.log('Contract is deploying...')
    // Deploying the My404 contract, passing the deployer's address as a constructor argument.
    const instanceUSDC = await ethers.deployContract('USDCToken', [1e10]);

    // Waiting for the contract deployment to be confirmed on the blockchain.
    await instanceUSDC.waitForDeployment()

    // Logging the address of the deployed My404 contract.
    console.log(`USDC contract is deployed. Token address: ${instanceUSDC.target}`)

    const USDC_Address = await instanceUSDC.getAddress();
    const developmentTeam: string = "0x9319Ec01DcB2086dc828C9A23Fa32DFb2FE10143";
    const Marketplace = await ethers.deployContract('Marketplace', [developmentTeam, percentForSeller, USDC_Address]);
    await Marketplace.waitForDeployment()
    const Marketplace_Address = await Marketplace.getAddress();
    console.log(`Marketplace is deployed. ${Marketplace.target}`);

    const instanceGroup = await ethers.deployContract("CreatorGroup");
    await instanceGroup.waitForDeployment() ;
    console.log(`instance Group is deployed. ${instanceGroup.target}`);
    const Group_Address = await instanceGroup.getAddress();
    const instanceContent = await ethers.deployContract("ContentNFT");
    await instanceContent.waitForDeployment()
    console.log(`instance Content is deployed. ${instanceContent.target}`);
    const Content_Address = await instanceContent.getAddress();
    const mintFee:number = 0;
    const burnFee:number = 0;
    const instanceFactory = await ethers.deployContract("Factory", [Group_Address, Content_Address, Marketplace_Address, developmentTeam, mintFee, burnFee, USDC_Address]);
    await instanceFactory.waitForDeployment()
    const Factory_Address = await instanceFactory.getAddress();
    console.log(`Factory is deployed. ${instanceFactory.target}`);
    // const tx = await my404.setWhitelist(deployer.address, true)
    // await tx.wait() // Waiting for the transaction to be mined.
    // console.log(`Tx hash for whitelisting deployer address: ${tx.hash}`)
}

// This pattern allows the use of async/await throughout and ensures that errors are caught and handled properly.
main().catch(error => {
    console.error(error)
    process.exitCode = 1
})