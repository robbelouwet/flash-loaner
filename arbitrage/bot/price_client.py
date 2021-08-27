import json
from decimal import Decimal
import requests
from utils.web3_utils import get_symbol_by_address, get_address_by_symbol
from utils import globals
token_info = globals.network_data()['tokens']
appel


def get_pair_prices(sell_token, buy_token, sell_amount):
    """
    This method makes a GET request to the 0x API to get real time prices of this trade pair from different DEX's, at the time of execution!
    It then formats the data in human readable form and returns it.

    :param buy_token: symbol of the token to buy
    :param sell_token: symbol of the token to sell
    :param sell_amount: amount you want to sell, in human readable notation (eg: provide 2.3 (ETH) instead of 2300000000000000000 (wei))
    :return: a list of arbitrage opportunities, each item is a swapping pair's price for a certain DEX
    """
    global token_info

    # get the addresses of the tokens
    sell_token_address = get_address_by_symbol(sell_token)
    buy_token_address = get_address_by_symbol(buy_token)

    # first get the decimals of the sell_token, to rebase the sell_amount
    sell_decimals = token_info[sell_token_address]['decimals']

    # The DEX's NOT to include in the response
    excludeSources = "JetSwap,WaultSwap,Belt,DODO,DODO_V2,Ellipsis,Mooniswap,MultiHop,Nerve,SushiSwap,Smoothy,ApeSwap,CafeSwap,CheeseSwap,JulSwap,LiquidityProvider"
    response = requests.get(f"https://bsc.api.0x.org/swap/v1/quote?buyToken={buy_token_address}&sellToken={sell_token_address}&sellAmount={sell_amount*(10**sell_decimals)}{f'&excludedSources={excludeSources}' if excludeSources is not None else ''}&slippagePercentage=0&gasPrice=0").json()

    open('../resources/iets.json', 'w').write(json.dumps(response, indent=4))

    arbitrages = []

    for fakeOrder in response['orders']:

        # convert contract addresses to symbols
        maker_symbol = get_symbol_by_address(fakeOrder['makerToken'])
        taker_symbol = get_symbol_by_address(fakeOrder['takerToken'])

        # parse amounts
        maker_amount = Decimal(fakeOrder['makerAmount'])
        taker_amount = Decimal(fakeOrder['takerAmount'])

        # figure out decimals for each token
        maker_decimals = Decimal(token_info[maker_symbol]['decimals'])
        taker_decimals = Decimal(token_info[taker_symbol]['decimals'])

        # rebase amounts with their corresponding decimals, using Decimal to keep precision
        maker_amount_rebased = maker_amount / (10 ** maker_decimals)
        taker_amount_rebased = taker_amount / (10 ** taker_decimals)

        arbitrages.append({
            'DEX': fakeOrder['source'],
            'taker_token': taker_symbol,
            'taker_amount_rebased': taker_amount_rebased,
            'maker_token': maker_symbol,
            'maker_amount_rebased': maker_amount_rebased,
            'maker/taker_ratio': taker_amount_rebased / maker_amount_rebased
        })

    return arbitrages
