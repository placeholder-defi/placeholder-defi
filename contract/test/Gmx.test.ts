import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { BigNumber } from "ethers";
import {
  PriceOracle,
  ERC20Upgradeable,
  SafeModule,
  Factory,
  ShortTermFund__factory,
  ShortTermFund,
  OneInchHandler,
} from "../typechain";
import { chainIdToAddresses } from "../scripts/networkVariables";
const axios = require("axios");
const qs = require("qs");
var chai = require("chai");
//use default BigNumber
chai.use(require("chai-bignumber")());
describe.only("Tests for shortTermFund", async () => {
  let accounts;
  let priceOracle: PriceOracle;
  let txObject;
  let owner: SignerWithAddress;
  let nonOwner: SignerWithAddress;
  let investor1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addrs: SignerWithAddress[];
  let safeModule: SafeModule;
  let oneInchHandler: OneInchHandler;
  //const APPROVE_INFINITE = ethers.BigNumber.from(1157920892373161954235); //115792089237316195423570985008687907853269984665640564039457
  let approve_amount = ethers.constants.MaxUint256; //(2^256 - 1 )
  let token;
  //   const forkChainId: any = process.env.FORK_CHAINID;
  const provider = ethers.provider;
  const chainId: any = 42161;
  const addresses = chainIdToAddresses[chainId];
  let swapHandler: any;
  let contractFactory: Factory;
  let shortTermFund: any;
  describe("Tests for PlaceHolderDefi contract", () => {
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
      const SafeModule = await ethers.getContractFactory("SafeModule");
      safeModule = await SafeModule.deploy();
      await safeModule.deployed();
      const PancakeSwapHandler = await ethers.getContractFactory(
        "PancakeSwapHandler"
      );
      swapHandler = await PancakeSwapHandler.deploy();
      await swapHandler.deployed();
      await swapHandler.init(
        "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506",
        priceOracle.address
      );
      const OneInchSwapHandler = await ethers.getContractFactory(
        "OneInchHandler"
      );
      oneInchHandler = await OneInchSwapHandler.deploy();
      await oneInchHandler.deployed();
      oneInchHandler.init(
        "0x1111111254EEB25477B68fb85Ed929f73A960582",
        priceOracle.address
      );
      const Factory = await ethers.getContractFactory("Factory");
      const contractFactory = await Factory.deploy(
        priceOracle.address,
        addresses.gnosisSingleton,
        addresses.gnosisFallbackLibrary,
        addresses.gnosisMultisendLibrary,
        addresses.gnosisSafeProxyFactory,
        safeModule.address,
        "0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064",
        "0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868"
      );
      console.log("Factory Address", contractFactory.address);
      await contractFactory.createNonCustodialVault(
        "TRADERS",
        "TDR",
        "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
        "200"
      );
      const fundAddress = await contractFactory.getFundList(0);
      shortTermFund = await ethers.getContractAt(
        ShortTermFund__factory.abi,
        fundAddress
      );
    });
    describe("PlaceHolderDefi Contract", function () {
      it("user invest usdc", async () => {
        await swapHandler.swapETHToTokens(
          "200",
          "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
          owner.address,
          {
            value: "100000000000000000",
          }
        );
      });
      it("priceORacle", async () => {
        const price = await priceOracle.getPrice(
          "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
          "0x0000000000000000000000000000000000000348"
        );
        console.log(price);
      });
      it("should deposit in vault", async () => {
        const balanceBefore = await shortTermFund.totalSupply();
        const ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        await ERC20.attach(
          "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"
        ).approve(shortTermFund.address, "10000000");
        await shortTermFund.deposit(
          "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
          "10000000"
        );
        const balanceAfter = await shortTermFund.totalSupply();
        expect(Number(balanceAfter)).to.be.greaterThan(Number(balanceBefore));
      });
      it("should withdraw from vault", async () => {
        const balanceBefore = await shortTermFund.totalSupply();
        await shortTermFund.withdraw("1000");
        const balanceAfter = await shortTermFund.totalSupply();
        expect(Number(balanceBefore)).to.be.greaterThan(Number(balanceAfter));
      });
      it("trade", async () => {
        const ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        await shortTermFund.startTrade(
          "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
          ["0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"],
          "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
          "1000000",
          "true",
          "0x0000000000000000000000000000000000000000000000000000000000000000",
          "0x0000000000000000000000000000000000000000",
          {
            value: "215000000000000",
          }
        );
      });
      it("should requestWithdraw", async () => {
        await ethers.provider.send("evm_increaseTime", [1900]);
        const ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        await ERC20.attach(shortTermFund.address).approve(
          shortTermFund.address,
          "1000000"
        );
        await shortTermFund.requestWithdraw("100");
        await shortTermFund.closeTrade();
      });
      it("should swap using 1inch handler", async () => {
        const oneInchParams = {
          fromTokenAddress: "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
          toTokenAddress: "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f",
          amount: "1000",
          fromAddress: oneInchHandler.address.toString(),
          slippage: 6,
          disableEstimate: true,
          compatibilityMode: true,
        };
        const oneInchResponse = await axios.get(
          addresses.oneInchUrl + `${qs.stringify(oneInchParams)}`
        );
        var fee = oneInchResponse.data.protocolFee
          ? oneInchResponse.data.protocolFee
          : 0;
        const ERC20 = await ethers.getContractFactory("ERC20Upgradeable");
        await ERC20.attach(shortTermFund.address).approve(
          shortTermFund.address,
          "1000000"
        );
        await shortTermFund.swapUsingOnceInchHandler(
          "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
          "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f",
          owner.address,
          oneInchHandler.address,
          "10000",
          oneInchResponse.data.tx.data
        );
      });
    });
  });
});