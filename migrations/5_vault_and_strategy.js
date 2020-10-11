require('dotenv-flow').config();

// ============ Contracts ============
const BTFToken = artifacts.require("BTFToken");
const Timelock = artifacts.require("Timelock");
const MasterChef = artifacts.require("MasterChef");
const Controller = artifacts.require("Controller");
const IUniswapV2Factory = artifacts.require("IUniswapV2Factory");

const Vault = artifacts.require("Vault");

const StrategyUniEthDaiLp = artifacts.require("StrategyUniEthDaiLp");
const StrategyUniEthUsdcLp = artifacts.require("StrategyUniEthUsdcLp");
const StrategyUniEthUsdtLp = artifacts.require("StrategyUniEthUsdtLp");
const StrategyUniEthWbtcLp = artifacts.require("StrategyUniEthWbtcLp");
const StrategyYfvDai = artifacts.require("StrategyYfvDai");
const StrategyYfvTusd = artifacts.require("StrategyYfvTusd");
const StrategyYfvUsdc = artifacts.require("StrategyYfvUsdc");
const StrategyYfvUsdt = artifacts.require("StrategyYfvUsdt");
const StrategySwerve = artifacts.require("StrategySwerve");

// ============ Main Migration ============
const migration = async (deployer, network, accounts) => {
    await Promise.all([
        deployVault(deployer, network),
    ]);
};

module.exports = migration;

// ============ Deploy Functions ============
async function deployVault(deployer, network) {
    let governance = process.env.GNOSIS_MULTISIG;
    let strategist = process.env.GNOSIS_MULTISIG;

    // mainnet
    let dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    let usdt = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
    let usdc = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    let tusd = "0x0000000000085d4780B73119b644AE5ecd22b376";
    let uniEthDai = "0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11";
    let uniEthUsdc = "0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc";
    let uniEthUsdt = "0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852";
    let uniEthWbtc = "0xBb2b8038a1640196FbE3e38816F3e67Cba72D940";
    let swusd = "0x77C6E4a580c0dCE4E5c7a17d0bc077188a83A059";
    // create eth/btf uniswap pair
    let factoryAddr = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
    let weth = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

    if (network === 'rinkeby') {
        dai = "0xef77ce798401dac8120f77dc2debd5455eddacf9";
        usdt = "0x1a37dd375096820a5fde14342720102c07100f26";
        usdc = "0xb7dbd69de83e7ed358c7687c1c1970e5dd121818";
        tusd = "0x3b2231b1846a7f6e0dde358f3b40888795d55333";
        uniEthDai = "0xe9edd1fa66bf5a0778eb964d38b31e4a2b4243cd";
        uniEthUsdc = "0xe9edd1fa66bf5a0778eb964d38b31e4a2b4243cd";
        uniEthUsdt = "0xe9edd1fa66bf5a0778eb964d38b31e4a2b4243cd";
        uniEthWbtc = "0xe9edd1fa66bf5a0778eb964d38b31e4a2b4243cd";
        swusd = "0xe9edd1fa66bf5a0778eb964d38b31e4a2b4243cd";

        factoryAddr = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
        weth = "0x0181c1dd8817810370e60b55e30808880dd69027";
    }

    let masterChef = await MasterChef.deployed();
    let controller = await Controller.deployed();

    // vault
    let daiVault = await deployer.deploy(Vault, dai, governance, Controller.address);
    let usdtVault = await deployer.deploy(Vault, usdt, governance, Controller.address);
    let usdcVault = await deployer.deploy(Vault, usdc, governance, Controller.address);
    let tusdVault = await deployer.deploy(Vault, tusd, governance, Controller.address);
    let uniEthDaiVault = await deployer.deploy(Vault, uniEthDai, governance, Controller.address);
    let uniEthUsdcVault = await deployer.deploy(Vault, uniEthUsdc, governance, Controller.address);
    let uniEthUsdtVault = await deployer.deploy(Vault, uniEthUsdt, governance, Controller.address);
    let uniEthWbtcVault = await deployer.deploy(Vault, uniEthWbtc, governance, Controller.address);
    let swusdVault = await deployer.deploy(Vault, swusd, governance, Controller.address);
    console.log("daiVault(bDai) address is " + daiVault.address + "\n"
        + "usdtVault(bUsdt) address is " + usdtVault.address + "\n"
        + "usdcVault(bUsdc) address is " + usdcVault.address + "\n"
        + "tusdVault(bTusd) address is " + tusdVault.address + "\n"
        + "uniEthDaiVault(bUniDai) address is " + uniEthDaiVault.address + "\n"
        + "uniEthUsdcVault(bUniUsdc) address is " + uniEthUsdcVault.address + "\n"
        + "uniEthUsdtVault(bUniUsdt) address is " + uniEthUsdtVault.address + "\n"
        + "uniEthWbtcVault(bUniWbtc) address is " + uniEthWbtcVault.address+ "\n"
        + "swusdVault(bswUSD) address is " + swusdVault.address);

    // create pair
    let uniEthBtf;
    await IUniswapV2Factory.at(factoryAddr).then(function (instance) {
        return instance.getPair(weth, BTFToken.address);
    }).then(function (value) {
        uniEthBtf = value;
    });

    if (uniEthBtf === "0x0000000000000000000000000000000000000000") {
        await IUniswapV2Factory.at(factoryAddr).then(function (instance) {
            return instance.createPair(weth, BTFToken.address)
        }).then(function (value) {
            uniEthBtf = value.logs[0].args.pair;
        });
    }
    console.log("uniEthBtf address is " + uniEthBtf);

    // vault(staking pool) which will be add to masterChef
    await Promise.all([
        // uniEthBtf(about 23%)
        masterChef.add(600, uniEthBtf),
        // daiVault -> bDai
        masterChef.add(100, daiVault.address),
        // usdtVault -> bUsdt
        masterChef.add(100, usdtVault.address),
        // usdcVault -> bUsdc
        masterChef.add(100, usdcVault.address),
        // tusdVault -> bTusd
        masterChef.add(100, tusdVault.address),
        // uniEthDaiVault -> bUniDai
        masterChef.add(400, uniEthDaiVault.address),
        // uniEthUsdcVault -> bUniUsdc
        masterChef.add(400, uniEthUsdcVault.address),
        // uniEthUsdtVault -> bUniUsdt
        masterChef.add(400, uniEthUsdtVault.address),
        // uniEthWbtcVault -> bUniWbtc
        masterChef.add(400, uniEthWbtcVault.address),
        // swusdVault -> bswUSD
        masterChef.add(400, swusdVault.address),
    ]);

    // change owner of masterchef
    await masterChef.transferOwnership(Timelock.address);

    // farming strategy
    await deployer.deploy(StrategyYfvDai, governance, strategist, Controller.address, Timelock.address, BTFToken.address);
    await deployer.deploy(StrategyYfvUsdt, governance, strategist, Controller.address, Timelock.address, BTFToken.address);
    await deployer.deploy(StrategyYfvUsdc, governance, strategist, Controller.address, Timelock.address, BTFToken.address);
    await deployer.deploy(StrategyYfvTusd, governance, strategist, Controller.address, Timelock.address, BTFToken.address);
    await deployer.deploy(StrategyUniEthDaiLp, governance, strategist, Controller.address, Timelock.address, BTFToken.address);
    await deployer.deploy(StrategyUniEthUsdcLp, governance, strategist, Controller.address, Timelock.address, BTFToken.address);
    await deployer.deploy(StrategyUniEthUsdtLp, governance, strategist, Controller.address, Timelock.address, BTFToken.address);
    await deployer.deploy(StrategyUniEthWbtcLp, governance, strategist, Controller.address, Timelock.address, BTFToken.address);
    await deployer.deploy(StrategySwerve, governance, strategist, Controller.address, Timelock.address, BTFToken.address);

    console.log("StrategyYfvDai address is " + StrategyYfvDai.address + "\n"
        + "StrategyYfvUsdt address is " + StrategyYfvUsdt.address + "\n"
        + "StrategyYfvUsdc address is " + StrategyYfvUsdc.address + "\n"
        + "StrategyYfvTusd address is " + StrategyYfvTusd.address + "\n"
        + "StrategyUniEthDaiLp address is " + StrategyUniEthDaiLp.address + "\n"
        + "StrategyUniEthUsdcLp address is " + StrategyUniEthUsdcLp.address + "\n"
        + "StrategyUniEthUsdtLp address is " + StrategyUniEthUsdtLp.address + "\n"
        + "StrategyUniEthWbtcLp address is " + StrategyUniEthWbtcLp.address+ "\n"
        + "StrategySwerve address is " + StrategySwerve.address);

    // relations between pool token and pool
    await Promise.all([
        controller.setVault(dai, daiVault.address),
        controller.setVault(usdt, usdtVault.address),
        controller.setVault(usdc, usdcVault.address),
        controller.setVault(tusd, tusdVault.address),
        controller.setVault(uniEthDai, uniEthDaiVault.address),
        controller.setVault(uniEthUsdc, uniEthUsdcVault.address),
        controller.setVault(uniEthUsdt, uniEthUsdtVault.address),
        controller.setVault(uniEthWbtc, uniEthWbtcVault.address),
        controller.setVault(swusd, swusdVault.address)
    ]);

    // relations between pool token and strategy
    await Promise.all([
        controller.approveStrategy(dai, StrategyYfvDai.address),
        controller.approveStrategy(usdt, StrategyYfvUsdt.address),
        controller.approveStrategy(usdc, StrategyYfvUsdc.address),
        controller.approveStrategy(tusd, StrategyYfvTusd.address),
        controller.approveStrategy(uniEthDai, StrategyUniEthDaiLp.address),
        controller.approveStrategy(uniEthUsdc, StrategyUniEthUsdcLp.address),
        controller.approveStrategy(uniEthUsdt, StrategyUniEthUsdtLp.address),
        controller.approveStrategy(uniEthWbtc, StrategyUniEthWbtcLp.address),
        controller.approveStrategy(swusd, StrategySwerve.address)
    ]);
    await Promise.all([
        controller.setStrategy(dai, StrategyYfvDai.address),
        controller.setStrategy(usdt, StrategyYfvUsdt.address),
        controller.setStrategy(usdc, StrategyYfvUsdc.address),
        controller.setStrategy(tusd, StrategyYfvTusd.address),
        controller.setStrategy(uniEthDai, StrategyUniEthDaiLp.address),
        controller.setStrategy(uniEthUsdc, StrategyUniEthUsdcLp.address),
        controller.setStrategy(uniEthUsdt, StrategyUniEthUsdtLp.address),
        controller.setStrategy(uniEthWbtc, StrategyUniEthWbtcLp.address),
        controller.setStrategy(swusd, StrategySwerve.address)
    ]);

    await controller.setTimelock(Timelock.address)
}