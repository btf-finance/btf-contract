const { expectRevert, time } = require('@openzeppelin/test-helpers');
const ethers = require('ethers');
const BTFToken = artifacts.require("BTFToken");
const MasterChef = artifacts.require("MasterChef");
const MockERC20 = artifacts.require('MockERC20');


contract("MasterChef", ([master, owner, nancy, alicy, dev, dev2, dev3, dev4]) => {
    beforeEach(async () => {
        this.btf = await BTFToken.at("0x222FE577420B3dB9031495FCB423da333e8c4e96");
        this.masterChef = await MasterChef.at("0x151D9D9466916B622eEDd4F95f42ce9c0F063009");
        console.log("owner: " + owner);
        console.log("<<<<<<<<MasterChef>>>>>>>>: " + (await this.btf.balanceOf(this.masterChef.address)));
    });

    it('should set correct state variables', async () => {
        // await this.btf.transferOwnership(this.masterChef.address, { from: owner });
        const btf = await this.masterChef.btf();
        const ownerForBtf = await this.btf.owner();
        console.log("btf: " + btf + ", btf's owner: " + ownerForBtf);
        console.log("nancy btf balance of: " + (await this.btf.balanceOf(nancy)));
    });

    context('With ERC20/LP token added to the field', () => {
        beforeEach(async () => {
            this.lp = await MockERC20.at("0x0673A6DB20fdFd8b44A8088A4E2d0df6adf2E102");
            // await this.lp.transfer(nancy, '1000000', { from: owner });
        });

        it('should allow emergency withdraw', async () => {
            console.log("nancy LP: " + (await this.lp.balanceOf(nancy)));
            // await this.masterChef.add('20', this.lp.address, {from: owner}); // add pool
            // await this.lp.approve(this.masterChef.address, 100, { from: nancy });
            // await this.masterChef.deposit(0, '10', { from: nancy });

            let amount = (await this.masterChef.userInfo(0, nancy)).amount;
            let rewardPerTokenPaid = (await this.masterChef.userInfo(0, nancy)).rewardPerTokenPaid;
            let rewards = (await this.masterChef.userInfo(0, nancy)).rewards;
            console.log("amount: " + amount + ", rewardPerTokenPaid: " + rewardPerTokenPaid + ", rewards: " + rewards);

            await this.masterChef.emergencyWithdraw(0, { from: nancy });
        });
    });
});
