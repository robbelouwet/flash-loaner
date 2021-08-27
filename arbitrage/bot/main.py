import json
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
        calculate_price_discrepancy(pair)
        break


def calculate_price_discrepancy(pair):
    """
    Calculates the price discrepancy between token pairs on different DEX's for a given token pair
    :return:
    """
    result = get_pair_prices(pair[0], pair[1], 480)
    print(json.dumps(result, indent=4, default=str))


if __name__ == "__main__":
    find_arbitrage()
