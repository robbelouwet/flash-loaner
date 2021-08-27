import json
from decimal import Decimal

from bot.price_client import get_pair_prices
from utils import globals

all_pairs = globals.network_data()['dex']['pancakeBakeryPairs']


def find_arbitrage():
    """"
    For every tradable pair listed in pancake_bakery_pairs.json,
    it checks whether an arbitrage opportunity is present at PancakeSwap <=> BakerySwap
    """
    global all_pairs
    for pair in all_pairs:
        result = calculate_price_discrepancy(pair)
        print(result[2])


def calculate_price_discrepancy(pair):
    """
    Calculates the price discrepancy between token pairs on different DEX's for a given token pair
    :return:
    """
    results = get_pair_prices(pair[0], pair[1], 1)
    list.sort(results, key=lambda i: Decimal(i['total_price']))

    return [results[0], results[len(results)-1],
            Decimal(results[0]['total_price']) - Decimal(results[len(results)-1]['total_price'])]


if __name__ == "__main__":
    get_pair_prices("ETH", "WBNB", 10000)
    #find_arbitrage()
