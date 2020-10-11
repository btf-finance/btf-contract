require('dotenv-flow').config();

// ============ Contracts ============
const BTFToken = artifacts.require("BTFToken");

const BTFReferral = artifacts.require("BTFReferral");
const MasterChef = artifacts.require("MasterChef");
const Timelock = artifacts.require("Timelock");

// ============ Main Migration ============
const migration = async (deployer, network, accounts) => {
    await Promise.all([
        deployMasterChef(deployer, network),
    ]);
};

module.exports = migration;

// ============ Deploy Functions ============
async function deployMasterChef(deployer, network) {
    let admin = process.env.GNOSIS_MULTISIG;
    // 2 day
    let delay = 86400 * 2;
    let btf = await BTFToken.deployed();
    let startBlock = process.env.START_BLOCK;

    await deployer.deploy(BTFReferral);
    console.log("BTFReferral address is " + BTFReferral.address);

    await deployer.deploy(Timelock, admin, delay);
    console.log("Timelock address is " + Timelock.address);

    await deployer.deploy(MasterChef, BTFToken.address, startBlock);
    console.log("MasterChef address is " + MasterChef.address);
    
    // change owner of token
    await btf.transferOwnership(MasterChef.address);

    let btfReferral = await BTFReferral.deployed();
    await btfReferral.setAdminStatus(MasterChef.address, true);

    let masterChef = await MasterChef.deployed();
    await masterChef.setRewardReferral(MasterChef.address);

    // // mainnet
    // let bDAI = "x";
    // let bUSDC = "x";
    // let bUSDT = "x";
    //
    // if (network === 'rinkeby') {
    //     bDAI = "0xc59ba443c0173dd2a06dafbe037e50f6345c69c4"; //0 pool
    //     bUSDC = "0xe9c8b3f629f8a0f215c99180a06cc8b9f3eba3e0";
    //     bUSDT = "0x7065ac39f7e9590e77f963177dafeaad7be776d1";
    // }
    //
    // // add stake pools
    // let masterChef = await MasterChef.deployed();
    // await Promise.all([
    //     masterChef.add(100, bDAI),
    //     // masterChef.add(200, bUSDC),
    //     // masterChef.add(200, bUSDT)
    // ]);
    // console.log("MasterChef add pools success.");
}