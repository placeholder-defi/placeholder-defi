// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { run, ethers, upgrades } from "hardhat";
import {
  PriceOracle,
  IERC20__factory,
  ERC20,
  SafeModule,
  Factory,
  ShortTermFund__factory
} from "../typechain";
import { chainIdToAddresses } from "./networkVariables";
// let fs = require("fs");
const ETHERSCAN_TX_URL = "https://testnet.bscscan.io/tx/";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await run("compile");
  const delay = (ms: number | undefined) =>
    new Promise((res) => setTimeout(res, ms));

  // get current chainId
  const { chainId } = await ethers.provider.getNetwork();
  const forkChainId: any = process.env.FORK_CHAINID;

  const addresses = chainIdToAddresses[forkChainId];
  const accounts = await ethers.getSigners();

  //console.log("accounts",accounts);

  console.log(
    "------------------------------ Initial Setup Ended ------------------------------"
  );

  console.log("--------------- Contract Deployment Started ---------------");
  const PriceOracle = await ethers.getContractFactory("PriceOracle");
  const priceOracle = await PriceOracle.deploy();
  await priceOracle.deployed();

  console.log("--------------- Contract Deployment Started ---------------");
  // const PriceOracle = await ethers.getContractFactory("PriceOracle");
  // const priceOracle = await PriceOracle.attach(
  //   "0xA812C7aCB1e6f41e7B4dE2d7CaF9F2fc176c6Bc7"
  // );

  await delay(15000);
  console.log("Waited 5s");

  let velvetSafeModule: SafeModule;

  const VelvetSafeModule = await ethers.getContractFactory("SafeModule");
  velvetSafeModule = await VelvetSafeModule.deploy();
  await velvetSafeModule.deployed();

  const IndexFactory = await ethers.getContractFactory("FactoryPlogon");
  const indexFactory = await IndexFactory.deploy(
    priceOracle.address,
    addresses.gnosisSingleton,
    addresses.gnosisFallbackLibrary,
    addresses.gnosisMultisendLibrary,
    addresses.gnosisSafeProxyFactory,
    velvetSafeModule.address,
    addresses.postionRoter
  )
  

  await indexFactory.deployed();

  await delay(5000);
  console.log("Waited 5s");

  console.log("Contract indexFactory deployed to: ", indexFactory.address);

  console.log(
    "------------------------------ Contract Deployment Ended ------------------------------"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
