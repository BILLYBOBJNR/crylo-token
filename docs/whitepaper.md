# CRYLO Litepaper v1.0

**Ticker:** CRYLO  
**Standard:** BEP20 (BNB Smart Chain)  
**Contract:** 0x0eD55C16E4b8332091f5B1Af8cd5E3985C58770f  
**Website:** https://crylo.io

## 1. Abstract
CRYLO is a **DeFi-focused** BEP20 token powering community rewards, lottery promotions, and future GameFi integrations. A 4.5% buy/sell fee automatically routes funds to **development**, a **prize pool**, and **auto-liquidity** to support market depth and long-term sustainability.

## 2. Tokenomics
- **Total Supply:** 1,000,000,000 CRYLO  
- **Decimals:** 18  
- **Fees (Buy/Sell):** 4.5% total  
  - 1.0% — Development  
  - 2.0% — Prize Pool (lottery & community rewards)  
  - 1.5% — Auto-Liquidity  
- **Router:** PancakeSwap V2 (0x10ED43C718714eb63d5aA57B78B54704E256024E)

## 3. Mechanics (high level)
On AMM trades, the contract accrues fees in CRYLO, then **swaps to BNB**:
- Sends BNB to the **dev wallet** and **prize wallet**.  
- Adds **liquidity** using the LP portion (half kept as tokens, paired with BNB).  
The **prize wallet** acts as the Lottery Treasury for draws, promotions, and rewards.

_Current configured wallets (may be updated on-chain by owner):_  
- Dev: 0xe5BBde1EcD6bAd426Ba1C992dD50A7cD6fD19449  
- Prize/Treasury: 0x9a29DfBd32F28Cc37ebfdbb1331B00A72ef2573C  
- LP Receiver: 0xB1De795118A5a21c2c692A0d263583eCe0A67a0E

## 4. DeFi, Lottery & GameFi
- **DeFi:** CRYLO participates in AMM liquidity and can be integrated in staking, farming, or partner dApps.  
- **Lottery:** the prize wallet funds periodic draws and community campaigns (off-chain entries, ERC-20 tickets, or ERC-721 NFTs are all viable patterns).  
- **GameFi:** CRYLO can be used as an in-game reward or payment asset through partner titles.

## 5. Governance & Admin
- Owner can adjust: fee exemptions, AMM pairs, swap thresholds, team wallets.  
- Rescue functions cannot rescue CRYLO itself.  
- No proxy/upgradability.

## 6. Security & Risks
- Built on OpenZeppelin ERC20 with swapback/LP logic.  
- Smart contracts carry risk; independent audit and responsible use encouraged.  
- No promises of profit; CRYLO is a utility/community token.

## 7. Roadmap (short)
- Aggregator listings & wallet metadata  
- Lottery dashboards & regular draws  
- GameFi partner pilots and DeFi integrations  
- Community governance experiments

## 8. Links
- Website: https://crylo.io  
- Explorer: https://bscscan.com/token/0x0eD55C16E4b8332091f5B1Af8cd5E3985C58770f  
- X (Twitter): https://x.com/crylocoin  
- Telegram: https://t.me/crylocoin  
- GitHub: https://github.com/BILLYBOBJNR/crylo  
- Whitepaper (PDF): https://crylo.io/whitepaper.pdf

*Disclaimer: Nothing herein is financial advice. Participation may be restricted by local laws.*
MD
open -e docs/whitepaper.md