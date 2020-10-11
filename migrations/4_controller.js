require('dotenv-flow').config();

// ============ Contracts ============
const Timelock = artifacts.require("Timelock");
const Controller = artifacts.require("Controller");

// ============ Main Migration ============
const migration = async (deployer, network, accounts) => {
    await Promise.all([
        deployController(deployer, network),
    ]);
};

module.exports = migration;

// ============ Deploy Functions ============
async function deployController(deployer, network) {
    // todo
    let governance = process.env.GNOSIS_MULTISIG;
    let strategist = process.env.DEPLOYER_ACCOUNT;
    let comAddr = process.env.GNOSIS_MULTISIG;
    let devAddr = process.env.DEPLOYER_ACCOUNT;
    let burnAddr = process.env.GNOSIS_MULTISIG;
    // should be changed to TimeLock
    let timelock = process.env.DEPLOYER_ACCOUNT;

    await deployer.deploy(Controller, governance, strategist, comAddr, devAddr, burnAddr, timelock);
    console.log("Controller address is " + Controller.address)
}