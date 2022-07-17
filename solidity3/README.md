We start at Bot::start

1) iterate over all our pairs: token0/token1
3) check for arbitrage opportunities
     for a given pair token0/token1:
     a) loan token0 from another token pair pool in order to save liquidity for our swaps
         e.g.: we want to find an arb opportunity of the pair USDC/WBTC which has certain pools on every DEX
               But we're going to flash loan 100 000 USDC from the USDC/WETH pool on uniswap V3, not from one of the pools
               of the USDC/WBTC pair, because then we lose liquidity on one of these pools and possibly screw up a profitable arbitrage opportunity
     b) find the best buy DEX that returns the most token1's in exchange for our amount of token0's
         actually perform the trade for every DEX and see got a maximum amount in return, then revert
     c) find the best sell DEX that returns the most token0's in exchange for our token1's we just got
         Actually sell on every DEX and see if we again sold for the maximum amount, then revert
     d) REVERT this, but send back the result through the exception stack
         We do this in order to return the result but revert the trades we made because we don't want to finalize these trades
         we just wanted to know the outcome
     e) if that trade would have been profitable if we didn't revert, save it in the profitable_trades arr
4) Perform every trade in profitable_trades array