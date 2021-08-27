import requests
import json

"""
This script is used to test out th api for realtime token prices.
0x is an API that provides real time prices of liquidity pools from all kinds of DEX'es on the binance smart chain
We're going to use this api to get real time price data
"""

# 'BUY' = maker
# 'sell' = taker

buy = "0xAC51066d7bEC65Dc4589368da368b212745d63E8"  # CAKE
# buy = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"  # WBNB
sell = "BUSD"
sellAmount = "100000000000000000000"

excludeSources = "JetSwap,WaultSwap,Belt,DODO,DODO_V2,Ellipsis,Mooniswap,MultiHop,Nerve,SushiSwap,Smoothy,ApeSwap,CafeSwap,CheeseSwap,JulSwap,LiquidityProvider"

tokens = requests.get(
    f"https://bsc.api.0x.org/swap/v1/quote?buyToken={buy}&sellToken={sell}&sellAmount={sellAmount}{f'&excludedSources={excludeSources}' if excludeSources is not None else ''}&slippagePercentage=0&gasPrice=0").json()
# "tokens = requests.get("https://coinmarketcap.com/exchanges/bakeryswap/").content


# tokens = requests.get("https://bsc.api.0x.org/swap/v1/price?sellToken=WETH&buyToken=DAI&sellAmount=1000000000000000000&excludedSources=Belt,DODO,DODO_V2,Ellipsis,Mooniswap,MultiHop,Nerve,SushiSwap,Smoothy,ApeSwap,CafeSwap,CheeseSwap,JulSwap,LiquidityProvider").json()

io = open('../resources/iets.json', 'w')
io.write(json.dumps(tokens, indent=4).replace('\'', '\"'))

pancake_kost = 0
bedragen = []

for item in tokens['orders']:
    makerAmount = int(item['makerAmount']) / 10e18
    takerAmount = int(item['takerAmount']) / 10e18

    if makerAmount == 0:
        continue

    print(item['source'])

    if item['source'] == "PancakeSwap":
        pancake_kost = (int(sellAmount) / 10e18) * (takerAmount / makerAmount)
    elif item['source'] == "BakerySwap":
        bedragen.append((int(sellAmount) / 10e18) * (takerAmount / makerAmount))

    print(f"- maker: {makerAmount} {buy}")
    print(f"- taker: {takerAmount} {sell}")

    print(f"{int(sellAmount) / 10e18} {buy} = {(int(sellAmount) / 10e18) * (takerAmount / makerAmount)} {sell}\n")

if pancake_kost == 0 or len(bedragen) == 0:
    print("geen arbitrage")
else:
    print(f"\nTheoretische winst:\n{pancake_kost-min(bedragen)}")