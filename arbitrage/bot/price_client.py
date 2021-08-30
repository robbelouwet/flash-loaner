import json
from decimal import Decimal
import requests

from model.bsc_client import BscClient
from model.data_client import DataClient
from utils.utils import get_symbol_by_address, get_address_by_symbol
all_tokens = DataClient.get_instance().get_tokens()
bsc_client = BscClient.get_instance()


def get_pair_prices(sell_token, buy_token, sell_amount):
    """
    This method makes a GET request to the 0x API to get real time prices of this trade pair from different DEX's, at the time of execution!
    It then formats the data in human readable form and returns it.

    :param buy_token: symbol of the token to buy
    :param sell_token: symbol of the token to sell
    :param sell_amount: amount you want to sell, in human readable notation (eg: provide 2.3 (ETH) instead of 2300000000000000000 (wei))
    :return: a list of arbitrage opportunities, each item is a swapping pair's price for a certain DEX
    """
    global all_tokens

    # get the addresses of the tokens
    sell_token_address = get_address_by_symbol(sell_token)
    buy_token_address = get_address_by_symbol(buy_token)

    # first get the decimals of the sell_token, to rebase the sell_amount
    sell_decimals = all_tokens[sell_token_address]['decimals']

    # The DEX's NOT to include in the response
    excludeSources = None  # "JetSwap,WaultSwap,Belt,DODO,DODO_V2,Ellipsis,Mooniswap,MultiHop,Nerve,SushiSwap,Smoothy,ApeSwap,CafeSwap,CheeseSwap,JulSwap,LiquidityProvider"
    response = requests.get(
        f"https://bsc.api.0x.org/swap/v1/quote?buyToken={buy_token_address}&sellToken={sell_token_address}&sellAmount={sell_amount * (10 ** sell_decimals)}{f'&excludedSources={excludeSources}' if excludeSources is not None else ''}&slippagePercentage=0&gasPrice=0").json()

    open('../resources/iets.json', 'w').write(json.dumps(response, indent=4))

    arbitrages = []

    if "orders" not in response.keys():
        raise ValueError(f'\n{json.dumps(response, indent=4, default=str)}')

    for fakeOrder in response['orders']:
        # convert contract addresses to symbols
        maker_symbol = get_symbol_by_address(fakeOrder['makerToken'])
        taker_symbol = get_symbol_by_address(fakeOrder['takerToken'])

        # parse amounts
        maker_amount = Decimal(fakeOrder['makerAmount'])
        taker_amount = Decimal(fakeOrder['takerAmount'])

        # get addresses
        maker = fakeOrder['makerToken']
        taker = fakeOrder['takerToken']

        # figure out decimals for each token
        maker_decimals = Decimal(all_tokens[bsc_client.to_checksum_address(maker)]['decimals'])
        taker_decimals = Decimal(all_tokens[bsc_client.to_checksum_address(taker)]['decimals'])

        # rebase amounts with their corresponding decimals, using Decimal to keep precision
        maker_amount_rebased = maker_amount / (10 ** maker_decimals)
        taker_amount_rebased = taker_amount / (10 ** taker_decimals)

        if maker_amount_rebased == 0:
            continue

        arbitrages.append({
            'DEX': fakeOrder['source'],
            'taker_token': taker_symbol,
            'taker_amount_rebased': taker_amount_rebased,
            'maker_token': maker_symbol,
            'maker_amount_rebased': maker_amount_rebased,
            'unit_price': taker_amount_rebased / maker_amount_rebased,
        })

    # print(json.dumps(arbitrages, indent=4, default=str))
    return arbitrages


def calculate_loan_amount(dex, pool, token):
    """
    Tis is the spot to place logic on how much to loan from a specific pool.

    :param dex: DEX the pool belongs to
    :param pool: address of a pool
    :param token: symbol of the token to loan
    :return: amount to loan IN WEI
    """
    global data

    pair_pool = data['dex'][dex]['liquidityPools'][pool]
    if pair_pool['token0'] == token:
        reserve = Decimal(pair_pool['reserve0_rebased'])
    else:
        reserve = Decimal(pair_pool['reserve1_rebased'])

    # logic:
    rebased_amount = round(reserve * Decimal(0.01))
    return rebased_amount

    # decimals = get_decimals(get_address_by_symbol(token))

    #result = round(Decimal(rebased_amount * Decimal(10 ** decimals)))

    #return result
