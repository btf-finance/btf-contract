const { expectRevert, time } = require('@openzeppelin/test-helpers');
const ethers = require('ethers');

const BTFToken = artifacts.require("BTFToken");

contract("BTFToken", accounts => {
    const owner = '0x37043E78a12D1D508F98CF842440F2F0B129A9bA';
    const dev = '0x66261A0237fe7f82C1F5f4a4c26d2FA5F2931B74';
    const dev2 = '0x412117d241a796C9DEb03B6eE227b0Cd85CFDE30';
  	beforeEach(async () => {
        this.btf = await BTFToken.at("0x5165C22c37DCfe149c98829991D86294e97324Be");
    });

    // it token info
    it('should have correct name and symbol and decimal.➺', async () => {
    	const name = await this.btf.name();
        const symbol = await this.btf.symbol();
        const decimals = await this.btf.decimals();
        assert.equal(name.valueOf(), "BTFToken");
        assert.equal(symbol.valueOf(), "BTF");
        assert.equal(decimals.valueOf(), "18");
    });

    // it token mint
    it('should only allow owner to mint token', async () => {
        await this.btf.mint(dev, '100', { from: owner });
        const totalSupply = await this.btf.totalSupply();
        const devBal = await this.btf.balanceOf(dev);
        console.log(totalSupply + ", " + devBal);
    });

    // it token transfers
    it('should supply token transfers properly', async () => {
        await this.btf.mint(dev, '100', { from: owner });
        await this.btf.transfer(dev2, '10', { from: dev });
        const totalSupply = await this.btf.totalSupply();
        const devBal = await this.btf.balanceOf(dev);
        const dev2Bal = await this.btf.balanceOf(dev2);
        console.log(totalSupply + ", devBal=" + devBal + ", dev2Bal=" + dev2Bal);
    });

    // it to do bad transfers
    it('should fail if you try to do bad transfers', async () => {
        await this.btf.mint(dev, '100', { from: owner });
        await expectRevert(
            this.btf.transfer(dev2, '10000000', { from: dev }),
            'ERC20: transfer amount exceeds balance 😭',
        );
    });
});