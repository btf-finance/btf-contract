## Btf-protocol Smart Contracts
BTFToken: [0x850eb951594F8df82413bbb3915D7CA2e394EEF3](https://etherscan.io/address/0x850eb951594F8df82413bbb3915D7CA2e394EEF3)

BTFReferral: [0x8214f52E56B66Bb797b6003188d8Fb920F8c41ad](https://etherscan.io/address/0x8214f52E56B66Bb797b6003188d8Fb920F8c41ad)

Timelock (12 hours): [0x6D4aA65af839813Fac3195dC2e44e8C539AC4a89](https://etherscan.io/address/0x6D4aA65af839813Fac3195dC2e44e8C539AC4a89)

Masterchef（change）: [0xF713D5a4EcE5C943e6dd82b7e6297ABD4d476D37](https://etherscan.io/address/0xF713D5a4EcE5C943e6dd82b7e6297ABD4d476D37)

Controller: [0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA](https://etherscan.io/address/0x229Ad7298D0dD41755c9771B1Cf72c302D12E6FA)

Governance (multi-sig): [0xBA67F3b52a7C15F8abeb99d4BA9ccCDb5C664ee8](https://etherscan.io/address/0xBA67F3b52a7C15F8abeb99d4BA9ccCDb5C664ee8)

Vault ProfitBooster: [0xC24Ecc381faA4C467a373239e8aFb5de940922eA](https://etherscan.io/address/0xC24Ecc381faA4C467a373239e8aFb5de940922eA)

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



## STAKE LEVEL
|  Pool Name | Stake Token | Reward Token | Weight |  Contract of Staking Token Contract  |
|  ----       | ----   |  ----  |  ----  | ----  |
| BTF-ETH Pool  | uni-v2-BTF-ETH LP | BTF |  6x|  [0x4F18FA10099ee416Cc9A12274d8b267273A95c6c](https://etherscan.io/address/0x4F18FA10099ee416Cc9A12274d8b267273A95c6c) |
| bDAI Pool   | bDAI   | BTF |  1x |  [0x285544E16944fb2d24Ae1d83e6111D33d2eC1C80](https://etherscan.io/address/0x285544E16944fb2d24Ae1d83e6111D33d2eC1C80) |
| bUSDC Pool  | bUSDC  | BTF |  1x |  [0xa1720c0146a1cEC87B6A99cdEB7FF47145ed4f84](https://etherscan.io/address/0xa1720c0146a1cEC87B6A99cdEB7FF47145ed4f84) |
| -----  | -----   | ----- |  ----- | ----- | 
| bUniDAI Pool  | bUniDAI | BTF |  4x |  [0xED95F14AFAF2495D3096DC26De825bC7CBcc6abC](https://etherscan.io/address/0xED95F14AFAF2495D3096DC26De825bC7CBcc6abC) |
| bUniUSDC Pool  | bUniUSDC | BTF |  4x |  [0x92545517C90c10FB36cA4Ec23590413106105bf4](https://etherscan.io/address/0x92545517C90c10FB36cA4Ec23590413106105bf4) |
| bUniUSDT Pool  | bUniUSDT | BTF |  4x |  [0xc0b7611533c32182D06837fDeab2778B3952a2c4](https://etherscan.io/address/0xc0b7611533c32182D06837fDeab2778B3952a2c4) |
| bUniWBTC Pool  | bUniWBTC | BTF |  4x|  [0x326c37e35175c5869afF0730a617aaCC95dE595F](https://etherscan.io/address/0x326c37e35175c5869afF0730a617aaCC95dE595F) |
| b3CRV Pool  | b3CRV | BTF |  1x|  [0x0b99CBd081B588bB75D7388Ab07bdE31Afb018f1](https://etherscan.io/address/0x0b99CBd081B588bB75D7388Ab07bdE31Afb018f1) |