// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// ─────────────────────────────────────────────────────────────────────────────
// OpenZeppelin v5
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// ─────────────────────────────────────────────────────────────────────────────
// Pancake/UniswapV2 minimal interfaces
interface IPancakeV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeV2Router02 {
    function factory() external view returns (address);
    function WETH() external view returns (address); // WBNB on BSC

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) external;

    function addLiquidityETH(
        address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

// ─────────────────────────────────────────────────────────────────────────────

contract CryloToken is ERC20, Ownable {
    // Wallets
    address public devWallet;
    address public prizeWallet;
    address public lpReceiver;

    // Router / Pair
    IPancakeV2Router02 public immutable router;
    address public immutable WBNB;
    address public pair;
    mapping(address => bool) public automatedMarketMakerPairs;

    // Fees (basis points, 10000 = 100%)
    struct Fees { uint16 devBps; uint16 prizeBps; uint16 lpBps; }
    Fees public buyFees  = Fees({ devBps: 100, prizeBps: 200, lpBps: 150 }); // 1% + 2% + 1.5% = 4.5%
    Fees public sellFees = Fees({ devBps: 100, prizeBps: 200, lpBps: 150 }); // same on sell

    uint16 public constant MAX_TOTAL_FEE_BPS = 1000; // 10% safety cap

    // Fee buckets
    uint256 public tokensForDev;
    uint256 public tokensForPrize;
    uint256 public tokensForLP;

    // Swap settings
    bool public swapEnabled = true;
    uint256 public swapTokensAt = 500_000 * 1e18; // adjust as needed
    bool private _swapping;

    // Trading gate
    bool public tradingEnabled;
    mapping(address => bool) public isExcludedFromFees;

    // Events
    event FeesUpdated(Fees buy, Fees sell);
    event WalletsUpdated(address dev, address prize, address lpReceiver);
    event AutomatedMarketMakerPairSet(address pair, bool value);
    event SwapBack(uint256 swapped, uint256 bnbDev, uint256 bnbPrize, uint256 bnbToLP, uint256 tokensToLP);

    // Constructor:
    // name, symbol, initialOwner, dev, prize, lpReceiver, router
    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _dev,
        address _prize,
        address _lpReceiver,
        address _router
    ) ERC20(_name, _symbol) Ownable(_owner) {
        require(_owner != address(0) && _dev != address(0) && _prize != address(0) && _lpReceiver != address(0), "zero addr");

        devWallet = _dev;
        prizeWallet = _prize;
        lpReceiver = _lpReceiver;

        router = IPancakeV2Router02(_router);
        WBNB = router.WETH();

        // Create pair
        address _pair = IPancakeV2Factory(router.factory()).createPair(address(this), WBNB);
        pair = _pair;
        automatedMarketMakerPairs[_pair] = true;
        emit AutomatedMarketMakerPairSet(_pair, true);

        // Exclusions
        isExcludedFromFees[_owner] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[_dev] = true;
        isExcludedFromFees[_prize] = true;
        isExcludedFromFees[_lpReceiver] = true;

        // Mint initial supply to owner (1,000,000,000)
        _mint(_owner, 1_000_000_000 * 1e18);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Owner controls

    function setTradingEnabled(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setSwapTokensAt(uint256 _amount) external onlyOwner {
        require(_amount >= 10_000 * 1e18, "too low");
        swapTokensAt = _amount;
    }

    function setWallets(address _dev, address _prize, address _lpReceiver) external onlyOwner {
        require(_dev != address(0) && _prize != address(0) && _lpReceiver != address(0), "zero addr");
        devWallet = _dev;
        prizeWallet = _prize;
        lpReceiver = _lpReceiver;
        emit WalletsUpdated(_dev, _prize, _lpReceiver);
    }

    function setAutomatedMarketMakerPair(address _pair, bool value) external onlyOwner {
        automatedMarketMakerPairs[_pair] = value;
        emit AutomatedMarketMakerPairSet(_pair, value);
    }

    function setExcludedFromFees(address account, bool value) external onlyOwner {
        isExcludedFromFees[account] = value;
    }

    function setFees(Fees calldata _buy, Fees calldata _sell) external onlyOwner {
        require(_buy.devBps + _buy.prizeBps + _buy.lpBps <= MAX_TOTAL_FEE_BPS, "buy fee too high");
        require(_sell.devBps + _sell.prizeBps + _sell.lpBps <= MAX_TOTAL_FEE_BPS, "sell fee too high");
        buyFees = _buy;
        sellFees = _sell;
        emit FeesUpdated(_buy, _sell);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Core transfer with fees + swapback

    function _update(address from, address to, uint256 amount) internal override {
        // Gate trading for non-exempt
        if (!tradingEnabled) {
            require(isExcludedFromFees[from] || isExcludedFromFees[to], "Trading not enabled");
        }

        // If swapping in progress, just move
        if (_swapping) {
            super._update(from, to, amount);
            return;
        }

        uint256 amountToTransfer = amount;

        bool takeFee = !(isExcludedFromFees[from] || isExcludedFromFees[to]);
        if (takeFee) {
            bool isBuy  = automatedMarketMakerPairs[from];
            bool isSell = automatedMarketMakerPairs[to];

            Fees memory f;
            if (isBuy) f = buyFees;
            else if (isSell) f = sellFees;
            else f = Fees(0,0,0); // P2P transfers: no fee

            uint16 totalBps = f.devBps + f.prizeBps + f.lpBps;
            if (totalBps > 0) {
                uint256 feeAmount = (amount * totalBps) / 10_000;
                if (feeAmount > 0) {
                    // Split buckets
                    uint256 devPart   = (feeAmount * f.devBps)   / totalBps;
                    uint256 prizePart = (feeAmount * f.prizeBps) / totalBps;
                    uint256 lpPart    = feeAmount - devPart - prizePart;

                    tokensForDev   += devPart;
                    tokensForPrize += prizePart;
                    tokensForLP    += lpPart;

                    amountToTransfer = amount - feeAmount;
                    super._update(from, address(this), feeAmount);
                }
            }
        }

        // Perform swapback on sells
        if (
            swapEnabled &&
            automatedMarketMakerPairs[to] &&
            !_swapping
        ) {
            uint256 contractBal = balanceOf(address(this));
            if (contractBal >= swapTokensAt) {
                _swapBack(contractBal);
            }
        }

        super._update(from, to, amountToTransfer);
    }

    function _swapBack(uint256 contractTokens) private {
        if (contractTokens == 0) return;

        // Limit how much we process in one go (optional)
        if (contractTokens > swapTokensAt * 5) {
            contractTokens = swapTokensAt * 5;
        }

        // Liquidity half
        uint256 lpHalf = tokensForLP / 2;
        uint256 tokensToSwapForBNB = contractTokens - lpHalf;
        if (tokensToSwapForBNB == 0) return;

        _swapping = true;

        // Approve router
        _approve(address(this), address(router), tokensToSwapForBNB);

        uint256 bnbBefore = address(this).balance;

        // Swap tokens → BNB
        address;
        path[0] = address(this);
        path[1] = WBNB;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwapForBNB, 0, path, address(this), block.timestamp
        );

        uint256 bnbReceived = address(this).balance - bnbBefore;

        // Compute shares
        uint256 tokensForBNBShare = tokensForDev + tokensForPrize + (tokensForLP - lpHalf);
        if (tokensForBNBShare == 0) {
            // nothing meaningful to distribute
            _resetBuckets();
            _swapping = false;
            return;
        }

        uint256 bnbForDev   = (bnbReceived * tokensForDev)   / tokensForBNBShare;
        uint256 bnbForPrize = (bnbReceived * tokensForPrize) / tokensForBNBShare;
        uint256 bnbForLP    = bnbReceived - bnbForDev - bnbForPrize;

        // Payouts
        if (bnbForDev > 0)   payable(devWallet).transfer(bnbForDev);
        if (bnbForPrize > 0) payable(prizeWallet).transfer(bnbForPrize);

        // Add liquidity: use the *other half* of LP tokens
        uint256 tokensForLPToAdd = tokensForLP - lpHalf;
        if (tokensForLPToAdd > 0 && bnbForLP > 0) {
            _approve(address(this), address(router), tokensForLPToAdd);
            router.addLiquidityETH{value: bnbForLP}(
                address(this),
                tokensForLPToAdd,
                0,
                0,
                lpReceiver,
                block.timestamp
            );
        }

        emit SwapBack(tokensToSwapForBNB, bnbForDev, bnbForPrize, bnbForLP, tokensForLPToAdd);

        _resetBuckets();
        _swapping = false;
    }

    function _resetBuckets() private {
        tokensForDev = 0;
        tokensForPrize = 0;
        tokensForLP = 0;
    }

    // Rescue native BNB if ever stuck
    function rescueETH(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    receive() external payable {}
}
