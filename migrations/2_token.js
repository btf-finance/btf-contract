// ============ Contracts ============
const BTFToken = artifacts.require("BTFToken");

// ============ Main Migration ============
const migration = async (deployer, network, accounts) => {
    await Promise.all([
        deployToken(deployer, network),
    ]);
};

module.exports = migration;

// ============ Deploy Functions ============
async function deployToken(deployer, network) {
    await deployer.deploy(BTFToken);
    console.log("BTFToken address is " + BTFToken.address)
}
