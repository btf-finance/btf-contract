// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../interface/IMakerDAO.sol";
import "../../interface/IController.sol";
import "../../interface/IVault.sol";
import "../../interface/UniswapRouterV2.sol";

contract StrategyMKRETHVaultDAI {

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public constant token = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // weth
  address public constant want = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // weth
  address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);// weth
  address public constant dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  address public cdp_manager = address(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
  address public vat = address(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
  address public mcd_join_eth_a = address(0x2F0b23f53734252Bda2277357e97e1517d6B042A);
  address public mcd_join_dai = address(0x9759A6Ac90977b93B58547b4A71c78317f391A28);
  address public mcd_spot = address(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
  address public jug = address(0x19c0976f590D67707E62397C87829d896Dc0f1F1);

  address public eth_price_oracle = address(0xCF63089A8aD2a9D8BD6Bb8022f3190EB7e1eD0f1);

  address public constant unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  bytes32 public constant ilk = "ETH-A";

  
  uint256 public c = 20000;
  uint256 public c_safe = 30000; // Rate of liquidation prevention when withdraw
  uint256 public constant c_base = 10000;
  
  uint256 public withdrawalFee = 0;
  uint256 public constant withdrawalMax = 10000;

  uint256 public performanceFee = 200;
  uint256 public constant performanceMax = 10000;

  uint256 public cdpId;


  address public governance;
  address public controller;
  address public strategist;
  address public timelock;

  address public kDaiVault;

  constructor(address _kDaiVault, address _governance, address _strategist, address _controller, address _timelock) public {
    kDaiVault = _kDaiVault;
    governance = _governance;
    strategist = _strategist;
    controller = _controller;
    timelock = _timelock;
    cdpId = ManagerLike(cdp_manager).open(ilk, address(this));
  }

  function balanceOf() public view returns (uint256) {
    return balanceOfWant().add(balanceOfPool());
  }

  function balanceOfWant() public view returns (uint256) {
    return IERC20(want).balanceOf(address(this));
  }

  function balanceOfPool() public view returns (uint256) {
    uint256 ink;
    address urnHandler = ManagerLike(cdp_manager).urns(cdpId);
    (ink, ) = VatLike(vat).urns(ilk, urnHandler);
    return ink;//[wad] lc
  }

  function getName() external pure returns (string memory) {
    return "StrategyMKRETHVaultDAI";
  }

  function setStrategist(address _strategist) external {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function setGovernance(address _governance) external {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setTimelock(address _timelock) external {
    require(msg.sender == timelock, "!timelock");
    timelock = _timelock;
  }

  function setController(address _controller) external {
    require(msg.sender == timelock, "!timelock");
    controller = _controller;
  }

  function setOracle(address _oracle) external {
    require(msg.sender == governance, "!governance");
    eth_price_oracle = _oracle;
  }

  function setWithdrawalFee(uint256 _withdrawalFee) external {
    require(msg.sender == timelock, "!timelock");
    withdrawalFee = _withdrawalFee;
  }

  function setPerformanceFee(uint256 _performanceFee) external {
    require(msg.sender == timelock, "!timelock");
    performanceFee = _performanceFee;
  }

  function setBorrowCollateralizationRatio(uint256 _c) external {
    require(msg.sender == governance, "!governance");
    c = _c;
  }

  function setWithdrawCollateralizationRatio(uint256 _c_safe) external {
    require(msg.sender == governance, "!governance");
    c_safe = _c_safe;
  }

  // optional config
  function setMCDValue(address _manager, address _ethAdapter, address _daiAdapter, address _spot, address _jug) external {
    require(msg.sender == governance, "!governance");
    cdp_manager = _manager;
    vat = ManagerLike(_manager).vat();
    mcd_join_eth_a = _ethAdapter;
    mcd_join_dai = _daiAdapter;
    mcd_spot = _spot;
    jug = _jug;
  }

  // all debt
  function getTotalDebtAmount() public view returns (uint256) {
    uint256 art;
    uint256 rate;
    address urnHandler = ManagerLike(cdp_manager).urns(cdpId);
    (, art) = VatLike(vat).urns(ilk, urnHandler);
    (, rate, , , ) = VatLike(vat).ilks(ilk);
    return art.mul(rate).div(1e27);
  }

  function getmVaultRatio(uint256 amount) public view returns (uint256) {
    uint256 spot; // ray
    uint256 liquidationRatio; // ray
    uint256 denominator = getTotalDebtAmount();

    if (denominator == 0) {
      return uint256(-1);
    }

    (, , spot, , ) = VatLike(vat).ilks(ilk);
    (, liquidationRatio) = SpotLike(mcd_spot).ilks(ilk); // Liquidation ratio [ray]
    uint256 delayedCPrice = spot.mul(liquidationRatio).div(1e27); // ray

    uint256 _balance = balanceOfPool();//[rad]
    if (_balance < amount) {
      _balance = 0;
    } else {
      _balance = _balance.sub(amount);
    }

    uint256 numerator = _balance.mul(delayedCPrice).div(1e18); // ray
    return numerator.div(denominator).div(1e3);
  }

  function _checkDebtCeiling(uint256 _amt) internal view returns (bool) {
    (, , , uint256 _line, ) = VatLike(vat).ilks(ilk); // Debt Ceiling
    uint256 _debt = getTotalDebtAmount().add(_amt);
    if (_line.div(1e27) < _debt) {
        return false;
    }
    return true;
  }

  function deposit() public {
    uint256 _token = IERC20(token).balanceOf(address(this));
    if (_token > 0) {
      uint256 p = _getPrice();
      uint256 _draw = _token.mul(p).mul(c_base).div(c).div(1e18);
      require(_checkDebtCeiling(_draw), "debt ceiling is reached!");
      _lockWETHAndDrawDAI(_token, _draw);
    }

    uint256 _daiBal = balanceOfDai();
    if (_daiBal > 0) {
      IERC20(dai).safeApprove(kDaiVault, 0);
      IERC20(dai).safeApprove(kDaiVault, _daiBal);
      IVault(kDaiVault).deposit(_daiBal);
    }
  }

  // Contoller only function for withdrawing for free
  // This is used to swap between vaults
  function freeWithdraw(uint256 _amount) external {
    require(msg.sender == controller, "!controller");
    uint256 _balance = IERC20(want).balanceOf(address(this));
    if (_balance < _amount) {
      _amount = _withdrawSome(_amount.sub(_balance));
      _amount = _amount.add(_balance);
    }
    IERC20(want).safeTransfer(msg.sender, _amount);
  }

  // Controller only function for creating additional rewards from dust
  function withdraw(IERC20 _asset) external returns (uint256 balance) {
    require(msg.sender == controller, "!controller");
    require(want != address(_asset), "want");
    balance = _asset.balanceOf(address(this));
    _asset.safeTransfer(controller, balance);
  }

  // Withdraw partial funds, normally used with a vault withdrawal
  function withdraw(uint256 _amount) external {
    require(msg.sender == controller, "!controller");
    uint256 _balance = IERC20(want).balanceOf(address(this));
    if (_balance < _amount) {
      _amount = _withdrawSome(_amount.sub(_balance));
      _amount = _amount.add(_balance);
    }

    if (withdrawalFee > 0) {
      uint256 _fee = _amount.mul(withdrawalFee).div(withdrawalMax);
      IERC20(want).safeTransfer(IController(controller).comAddr(), _fee);
      _amount = _amount.sub(_fee);
    }

    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
    IERC20(want).safeTransfer(_vault, _amount);
  }  

  // Withdraw all funds, normally used when migrating strategies
  function withdrawAll() external returns (uint256 balance) {
    require(msg.sender == controller, "!controller");
    _withdrawAll();

    balance = IERC20(want).balanceOf(address(this));

    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), "!vault");
    // additional protection so we don't burn the funds
    IERC20(want).safeTransfer(_vault, balance);
  }

  function _withdrawAll() internal {
    uint256 balance = IERC20(dai).balanceOf(address(this));
    uint256 totalDebt = getTotalDebtAmount().add(1); // in case of edge case
    if (balance < totalDebt) {
      uint256 _diff = totalDebt.sub(balance);
      IVault(kDaiVault).withdraw(_diff);
    }

    _wipe(totalDebt);
    _freeWETH(balanceOfPool());
  }

  function _withdrawSome(uint256 _amount) internal returns (uint256) {
    if (getTotalDebtAmount() != 0 && getmVaultRatio(_amount) < c_safe.mul(1e2)) {
      uint256 p = _getPrice();
      _wipe(_withdrawDaiFromCompoundLeast(_amount.mul(p).div(1e18)));
    }

    _freeWETH(_amount);

    return _amount;
  }
  
  /**
    * Lock collateral in the system
    * Draw Dai
    * open->approve->join->frob->move->hope->exit
    */
  function _lockWETHAndDrawDAI(uint256 wad, uint256 wadD) internal {
    address urn = ManagerLike(cdp_manager).urns(cdpId);
    IERC20(token).safeApprove(mcd_join_eth_a, 0);
    IERC20(token).safeApprove(mcd_join_eth_a, wad);
    GemJoinLike(mcd_join_eth_a).join(urn, wad);
    ManagerLike(cdp_manager).frob(cdpId, toInt(wad), _getDrawDart(urn, wadD));
    ManagerLike(cdp_manager).move(cdpId, address(this), wadD.mul(1e27));
    // Allows adapter to access to proxy's DAI balance in the vat
    if (VatLike(vat).can(address(this), address(mcd_join_dai)) == 0) {
      VatLike(vat).hope(mcd_join_dai);
    }
    DaiJoinLike(mcd_join_dai).exit(address(this), wadD);
  }

  /**
    * jug. -> Dai Lending Rate
    * Returns a normalized debt _amount based on the current rate
    */
  function _getDrawDart(address urn, uint256 wad) internal returns (int256 dart) {
    uint256 rate = JugLike(jug).drip(ilk); // --- Stability Fee Collection ---
    // Gets DAI balance of the urn in the vat
    uint256 _dai = VatLike(vat).dai(urn);

    // If there was already enough DAI in the vat balance, just exits it without adding more debt
    if (_dai < wad.mul(1e27)) {
      dart = toInt(wad.mul(1e27).sub(_dai).div(rate)); // pay stability fee
      dart = toUint256(dart).mul(rate) < wad.mul(1e27) ? dart + 1 : dart;
    }
  }

  function _getWipeDart(uint256 _dai, address urn) internal view returns (int256 dart) {
    (, uint256 rate,,,) = VatLike(vat).ilks(ilk);
    (, uint256 art) = VatLike(vat).urns(ilk, urn);

    dart = toInt(_dai.div(rate));
    dart = toUint256(dart) <= art ? -dart : -toInt(art);
  }
  
  // pay back Dai approve->join->frob
  function _wipe(uint256 wad) internal {
    // wad in DAI
    address urn = ManagerLike(cdp_manager).urns(cdpId);

    IERC20(dai).safeApprove(mcd_join_dai, 0);
    IERC20(dai).safeApprove(mcd_join_dai, wad);
    DaiJoinLike(mcd_join_dai).join(urn, wad);
    ManagerLike(cdp_manager).frob(cdpId, 0, _getWipeDart(VatLike(vat).dai(urn), urn));
  }

  // Unlock collateral from system
  function _freeWETH(uint256 wad) internal {
    ManagerLike(cdp_manager).frob(cdpId, -toInt(wad), 0);
    ManagerLike(cdp_manager).flux(cdpId, address(this), wad);
    GemJoinLike(mcd_join_eth_a).exit(address(this), wad);
  }

  // not near price
  function _getPrice() internal view returns (uint256 p) {
    (uint256 _read, ) = OSMedianizer(eth_price_oracle).read();
    (uint256 _foresight, ) = OSMedianizer(eth_price_oracle).foresight();
    p = _foresight < _read ? _foresight : _read;
  }

  function _withdrawDaiFromCompoundLeast(uint256 _amount) internal returns (uint256) {
    uint256 dart = 0;
    if (_amount > IVault(kDaiVault).balanceOf(address(this))) {
      dart = IVault(kDaiVault).balanceOf(address(this));
    }
    uint256 _before = IERC20(dai).balanceOf(address(this));
    IVault(kDaiVault).withdraw(dart);
    uint256 _after = IERC20(dai).balanceOf(address(this));
    return _after.sub(_before);
  }

  function toInt(uint256 x) internal pure returns (int256 y) {
    require(x < 2**255, "SafeCast: value doesn't fit in an int256");
    y = int256(x);
    require(y >= 0, "int-overflow");
  }

  function toUint256(int256 value) internal pure returns (uint256) {
    require(value >= 0, "SafeCast: value must be positive");
    return uint256(value);
  }

  // Emergency function call
  function execute(address _target, bytes memory _data) public payable returns (bytes memory response) {
    require(msg.sender == timelock, "!timelock");
    require(_target != address(0), "!target");
    // call contract in current context
    assembly {
        let succeeded := delegatecall(
        sub(gas(), 5000),
        _target,
        add(_data, 0x20),
        mload(_data),
        0,
        0
        )
        let size := returndatasize()

        response := mload(0x40)
        mstore(
        0x40,
        add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
        )
        mstore(response, size)
        returndatacopy(add(response, 0x20), 0, size)

        switch iszero(succeeded)
        case 1 {
        // throw if delegatecall failed
            revert(add(response, 0x20), size)
        }
    }
  }

    // **** Internal functions ****
  function _swap(address _from, address _to, uint256 _amount) internal {
    // Swap with uniswap
    IERC20(_from).safeApprove(unirouter, 0);
    IERC20(_from).safeApprove(unirouter, _amount);

    address[] memory path;

    if (_from == weth || _to == weth) {
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;
    } else {
        path = new address[](3);
        path[0] = _from;
        path[1] = weth;
        path[2] = _to;
    }

    UniswapRouterV2(unirouter).swapExactTokensForTokens(
        _amount,
        0,
        path,
        address(this),
        now.add(60)
    );
  }

  function getPrice() public view returns (uint256) {
    return _getPrice();
  }

  function getmVaultAsserts() public view returns (uint256) {
    uint256 spot;
    (,, spot,,) = VatLike(vat).ilks(ilk);
    uint256 ink;
    address urnHandler = ManagerLike(cdp_manager).urns(cdpId);
    (ink, ) = VatLike(vat).urns(ilk, urnHandler);
    return ink.mul(spot);
  }

  function balanceOfDai() public view returns (uint256) {
    return IERC20(dai).balanceOf(address(this));
  }
}







