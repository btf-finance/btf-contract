## Btf-protocol Smart Contracts
BTFToken: [0xa80C32c721d06c91DcEFfEa78f184503c9046940](https://etherscan.io/address/0xa80C32c721d06c91DcEFfEa78f184503c9046940)

BTF-USDC PAIR: [0x82802853d01b0264282Dd0cB9738E9B6Ad8bEDEC](https://etherscan.io/address/0x82802853d01b0264282Dd0cB9738E9B6Ad8bEDEC)

BTF-ETH PAIR: [0xc2fd29279a063Ea7E83Ed6B2F20E67AFd4A95820](https://etherscan.io/address/0xc2fd29279a063Ea7E83Ed6B2F20E67AFd4A95820)

BTFReferral: [0x8214f52E56B66Bb797b6003188d8Fb920F8c41ad](https://etherscan.io/address/0x8214f52E56B66Bb797b6003188d8Fb920F8c41ad)

Timelock (12 hours): [0x6D4aA65af839813Fac3195dC2e44e8C539AC4a89](https://etherscan.io/address/0x6D4aA65af839813Fac3195dC2e44e8C539AC4a89)

Masterchef: [0xe550bfdb3f4de5a19f85d56f40394803e70b3e69](https://etherscan.io/address/0xe550bfdb3f4de5a19f85d56f40394803e70b3e69)

Controller: [0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)

Governance/Strategist (multi-sig 01): [0xd6ca32B782497a52a0F0E172Da9Ae28c1Df83B5A](https://etherscan.io/address/0xd6ca32B782497a52a0F0E172Da9Ae28c1Df83B5A)

DevAddr (multi-sig 02): [0x33611Dc53870456776bFe10ed9dfe5ceeB2A60E6](https://etherscan.io/address/0x33611Dc53870456776bFe10ed9dfe5ceeB2A60E6)

ComAddr (multi-sig 03): [0xBA67F3b52a7C15F8abeb99d4BA9ccCDb5C664ee8](https://etherscan.io/address/0xBA67F3b52a7C15F8abeb99d4BA9ccCDb5C664ee8)

Vault ProfitBooster: [0xC24Ecc381faA4C467a373239e8aFb5de940922eA](https://etherscan.io/address/0xC24Ecc381faA4C467a373239e8aFb5de940922eA)

Profit Share Pool: [0x978d16a76942bdc93ad3c884ff82a574c1b0038c](https://etherscan.io/address/0x978d16a76942bdc93ad3c884ff82a574c1b0038c)


## FARM LEVEL

### 1）stableCoin mining strategie
| Vault  |  Lock Token | Receive Instead | VaultStrategies  | Vault Contract Address | controller |
|  ----  |  ----  | ----  |  ----  |  ----  |  ----  |
| DAI   | DAI   | bDAI   |  StrategyCmpdDaiV1 |  [0xB3Bc9600D1a4238193382Bb762f1d1f68f687DcD](https://etherscan.io/address/0xB3Bc9600D1a4238193382Bb762f1d1f68f687DcD)  | [Controller](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)|
| USDC  | USDC  | bUSDC  |  StrategyCmpdUsdcV1 |  [0x7F6f66E66c5728dd2B53c642C78c009A80110f09](https://etherscan.io/address/0x7F6f66E66c5728dd2B53c642C78c009A80110f09)  | [Controller](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)|

### 2）LP stake mining strategie
| Vault  |  Lock Token | LP Token Name | VaultStrategies  | Vault Contract Address | controller |
| ----  |  ----       | ----      |  ----  |  ----  |  ----  |
| DAI Vault   | DAI-ETH     | bUniDAI   |  StrategyUniEthDaiLp  |  [0x2c0d8B83B95A7CD809b2615bB76DcBecF8dBaAC8](https://etherscan.io/address/0x2c0d8B83B95A7CD809b2615bB76DcBecF8dBaAC8)  | [Controller](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)|
| USDC Vault  | USDC-ETH    | bUniUSDC  |  StrategyUniEthUsdcLp |  [0xB21CA0E0628356a326787616D8D62C2188BFF445](https://etherscan.io/address/0xB21CA0E0628356a326787616D8D62C2188BFF445)  | [Controller](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)|
| USDT Vault  | USDT-ETH    | bUniUSDT  |  StrategyUniEthUsdtLp |  [0x16f644Df844F95F21B445D9f38379F6E38118621](https://etherscan.io/address/0x16f644Df844F95F21B445D9f38379F6E38118621)  | [Controller](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)|
| WBTC Vault  | WBTC-ETH    | bUniWBTC  |  StrategyUniEthWbtcLp |  [0xCc9Bc2E388FFC79Ea0FEC84F8e857b968F6Ed0ee](https://etherscan.io/address/0xCc9Bc2E388FFC79Ea0FEC84F8e857b968F6Ed0ee)  | [Controller](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)|
| 3CRV Vault  | 3CRV    | b3CRV  |  StrategyCurve3CRV |  [0xD178c9099731aA3CD60804ce889eDe34da8310de](https://etherscan.io/address/0xD178c9099731aA3CD60804ce889eDe34da8310de)  | [Controller](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)|
| CCRV Vault  | CCRV    | bCCRV  |  StrategyCurveCCRV |  [0x5be5620dfb655a85262ab2b8700fe2085530f49f](https://etherscan.io/address/0x5be5620dfb655a85262ab2b8700fe2085530f49f)  | [Controller](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)|
| SCRV Vault  | SCRV    | bSCRV  |  StrategyCurveSCRV |  [0x44472e63c7c17761806da1ee07e3abe1937b1961](https://etherscan.io/address/0x44472e63c7c17761806da1ee07e3abe1937b1961)  | [Controller](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)|
| YCRV Vault  | YCRV    | bYCRV  |  StrategyCurveYCRV |  [0x15b1c273732734a93e4e233f6dfce4b64ca325f3](https://etherscan.io/address/0x15b1c273732734a93e4e233f6dfce4b64ca325f3)  | [Controller](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)|



## STAKE LEVEL
|  Pool Name | Stake Token | Reward Token | Weight | PID |  Contract of Staking Token Contract  |
|  ----       | ----   |  ----  |  ----  |  ----  | ----  |
| Profit Share Pool  | BTF | BTF |  -|  -|  [0x978d16a76942bdc93ad3c884ff82a574c1b0038c](https://etherscan.io/address/0x978d16a76942bdc93ad3c884ff82a574c1b0038c) |
| BTF-USDC Pool  | uni-v2-BTF-USDC LP | BTF | 0x | x |  [0x82802853d01b0264282Dd0cB9738E9B6Ad8bEDEC](https://etherscan.io/address/0x82802853d01b0264282Dd0cB9738E9B6Ad8bEDEC)|
| BTF-ETH Pool  | uni-v2-BTF-ETH LP | BTF |  8x |  0 |  [0xc2fd29279a063Ea7E83Ed6B2F20E67AFd4A95820](https://etherscan.io/address/0xc2fd29279a063Ea7E83Ed6B2F20E67AFd4A95820) |
| bDAI Pool   | bDAI   | BTF |  3x |  1 |  [0x285544E16944fb2d24Ae1d83e6111D33d2eC1C80](https://etherscan.io/address/0x285544E16944fb2d24Ae1d83e6111D33d2eC1C80) |
| bUSDC Pool  | bUSDC  | BTF |  3x |  2 |  [0xa1720c0146a1cEC87B6A99cdEB7FF47145ed4f84](https://etherscan.io/address/0xa1720c0146a1cEC87B6A99cdEB7FF47145ed4f84) |
| -----  | -----   | ----- |  ----- | ----- | ----- | 
| bUniDAI Pool  | bUniDAI | BTF |  1x |  7 |  [0xED95F14AFAF2495D3096DC26De825bC7CBcc6abC](https://etherscan.io/address/0xED95F14AFAF2495D3096DC26De825bC7CBcc6abC) |
| bUniUSDC Pool  | bUniUSDC | BTF |  1x |  6 |  [0x92545517C90c10FB36cA4Ec23590413106105bf4](https://etherscan.io/address/0x92545517C90c10FB36cA4Ec23590413106105bf4) |
| bUniUSDT Pool  | bUniUSDT | BTF |  1x |  5 |  [0xc0b7611533c32182D06837fDeab2778B3952a2c4](https://etherscan.io/address/0xc0b7611533c32182D06837fDeab2778B3952a2c4) |
| bUniWBTC Pool  | bUniWBTC | BTF |  1x|  4 |  [0x326c37e35175c5869afF0730a617aaCC95dE595F](https://etherscan.io/address/0x326c37e35175c5869afF0730a617aaCC95dE595F) |
| b3CRV Pool  | b3CRV | BTF |  2x |  3 |  [0x0b99CBd081B588bB75D7388Ab07bdE31Afb018f1](https://etherscan.io/address/0x0b99CBd081B588bB75D7388Ab07bdE31Afb018f1) |
| bCCRV Pool  | bCCRV | BTF |  4x |  8 |  [0xb34620d0b30648c9597799193e2265bee04606a8](https://etherscan.io/address/0xb34620d0b30648c9597799193e2265bee04606a8) |
| bSCRV Pool  | bSCRV | BTF |  2x |  9 |  [0x7bd9efca0ea682cc455456dc6ea9f1774a7667c9](https://etherscan.io/address/0x7bd9efca0ea682cc455456dc6ea9f1774a7667c9) |
| bYCRV Pool  | bYCRV | BTF |  2x |  10 |  [0x50dfdda590ea1c38a6f041a4f383818c9caf3b16](https://etherscan.io/address/0x50dfdda590ea1c38a6f041a4f383818c9caf3b16) |
| -----  | -----   | ----- |  ----- | ----- | ----- |

## About
btf

## Ownerships

BTFToken's owner = Masterchef

MasterChef's owner = Timelock

Timelock's admin = Gnosis Multisig01

Profit Share Pool's owner = Gnosis Multisig01

Vault's governance = Gnosis Multisig01

Controller's governance = Gnosis Multisig01

Controller's strategist = Gnosis Multisig01

BTFReferral's owner = Gnosis Multisig01

Strategyxxx's governance = Gnosis Multisig01

Strategyxxx's strategist = Gnosis Multisig01
