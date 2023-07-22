import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { BigNumber } from "ethers";
import {
  PriceOracle,
  IERC20__factory,
  ERC20,
  VelvetSafeModule,
  Factory,
  VelvetShortTermFund__factory
} from "../typechain";

import { chainIdToAddresses } from "../scripts/networkVariables";

var chai = require("chai");
//use default BigNumber
chai.use(require("chai-bignumber")());

describe.only("Tests for IndexSwap", async() => {
  let accounts;
  let priceOracle: PriceOracle;
  let txObject;
  let owner: SignerWithAddress;
  let nonOwner: SignerWithAddress;
  let investor1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addrs: SignerWithAddress[];
  let velvetSafeModule: VelvetSafeModule;
  //const APPROVE_INFINITE = ethers.BigNumber.from(1157920892373161954235); //115792089237316195423570985008687907853269984665640564039457
  let approve_amount = ethers.constants.MaxUint256; //(2^256 - 1 )
  let token;
//   const forkChainId: any = process.env.FORK_CHAINID;
  const provider = ethers.provider;
  const chainId: any = 42161;
  const addresses = chainIdToAddresses[chainId];
  let index:any;
  let swapHandler:any;
  let contractFactory: Factory;
  let shortTermFund : any;
  describe("Tests for IndexSwap contract", () => {
    before(async () => {
      accounts = await ethers.getSigners();
      [owner, investor1, nonOwner, addr1, addr2, ...addrs] = accounts;

      const provider = ethers.getDefaultProvider();
      const PriceOracle = await ethers.getContractFactory("PriceOracle");
      priceOracle = await PriceOracle.deploy();
      await priceOracle.deployed();
    
      await priceOracle._addFeed(
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        "0x0000000000000000000000000000000000000348",
        "0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612"
      ); // ETH / USD

      await priceOracle._addFeed(
        "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
        "0x0000000000000000000000000000000000000348",
        "0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612"
      ); // ETH / USD

      await priceOracle._addFeed(
        "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
        "0x0000000000000000000000000000000000000348",
        "0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3"
      ); // USDC / USD

      await priceOracle._addFeed(
        "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
        "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
        "0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612"
      ); // ETH / USDC
    
      const Index = await ethers.getContractFactory("Index");
      index = await Index.deploy("First", "FF", priceOracle.address, "0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064", "0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868", "0x22199a49A999c351eF7927602CFB187ec3cae489");
      await index.deployed();
    
      const VelvetSafeModule = await ethers.getContractFactory("VelvetSafeModule");
      velvetSafeModule = await VelvetSafeModule.deploy();
      await velvetSafeModule.deployed();


      const Factory = await ethers.getContractFactory("Factory");
      const contractFactory = await Factory.deploy(priceOracle.address,addresses.gnosisSingleton,addresses.gnosisFallbackLibrary,addresses.gnosisMultisendLibrary,addresses.gnosisSafeProxyFactory,velvetSafeModule.address);
      console.log("Factory Address",contractFactory.address);

      const PancakeSwapHandler = await ethers.getContractFactory("PancakeSwapHandler");
      swapHandler = await PancakeSwapHandler.deploy();
      await swapHandler.deployed();
    
      await swapHandler.init("0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506", priceOracle.address);
      await contractFactory.createNonCustodialVault("TRADERS","TDR","0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8","200");
      const fundAddress = await contractFactory.getFundList(0);
      shortTermFund = await ethers.getContractAt(VelvetShortTermFund__factory.abi,fundAddress);
    });
      

    describe("IndexSwap Contract", function () {
        it("user invest usdc", async () =>{
            await swapHandler.swapETHToTokens("200", "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8", owner.address, {
                value: "100000000000000000",
              });
        });
        it("priceORacle",async()=>{
            const price = await priceOracle.getPrice(
                "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
                "0x0000000000000000000000000000000000000348"
              );
              console.log(price);
        });
        it("should deposit in vault",async() => {
          const balanceBefore = await shortTermFund.totalSupply();
          const ERC20 = await ethers.getContractFactory("ERC20");
          await ERC20.attach("0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8").approve(shortTermFund.address,"1000000");
          await shortTermFund.deposit("0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8","10000");
          const balanceAfter = await shortTermFund.totalSupply();
          expect(Number(balanceAfter)).to.be.greaterThan(Number(balanceBefore));
        })
        it("should withdraw from vault",async() => {
          const balanceBefore = await shortTermFund.totalSupply();
          // const ERC20 = await ethers.getContractFactory("ERC20");
          // await ERC20.attach("0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8").approve(shortTermFund.address,"1000000");
          await shortTermFund.withdraw("10000");
          const balanceAfter = await shortTermFund.totalSupply();
          expect(Number(balanceBefore)).to.be.greaterThan(Number(balanceAfter));
        })
        it("invests", async() =>{
            const oldSupply = await index.totalSupply();
            const ERC20 = await ethers.getContractFactory("ERC20");
            await ERC20.attach("0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8").approve(index.address,"1000000");
            await index.invest("1000000","0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8");
            const newSupply = await index.totalSupply();
            expect(Number(newSupply)).to.be.greaterThan(Number(oldSupply));
        });
        it("trade", async() =>{
            const ERC20 = await ethers.getContractFactory("ERC20");
            const balBefore = await ERC20.attach("0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8").balanceOf(index.address);
            await index.tradeGMX("0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8", ["0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"], "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1", "1000000", "true", "0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000", {
                value: "215000000000000",
              })
            const balAfter = await ERC20.attach("0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8").balanceOf(index.address);
            console.log("balBefore",balBefore);
            console.log("balAfter",balAfter);
        })  

        it("checks positions", async() =>{
            // const reader = await ethers.getContractAt("IReader","0x22199a49A999c351eF7927602CFB187ec3cae489");
            // console.log(await reader.callStatic.getPositions("0x489ee077994B6658eAfA855C308275EAd8097C4A", index.address, ["0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"], ["0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"],[true]))

            console.log(await index.callStatic.getPositions(["0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"],["0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"],["true"]))
        })
    });
  });
});
