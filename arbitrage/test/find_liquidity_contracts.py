import json
from decimal import Decimal

from model.bsc_client import BscClient
from model.data_client import DataClient
from utils.utils import get_symbol_by_address

bsc_client = BscClient.get_instance()
data = DataClient.get_instance().get_data()
dexes = DataClient.get_instance().get_dexes()

tokens = {}


def get_all_pools():
    """
    Gets every liquidation pool of every DEX (that we saved) and each individual ERC20 token
    :return:
    """
    for key in dexes.keys():
        # skip pancakeswap, it's got 406k pools...
        if key == "PancakeSwap":
            continue

        find_tokens_and_pairs("JetSwap")


def find_tokens_and_pairs(dex):
    """
    This function queries all pools of the specified DEX's factory
    We save every pool (tradable pair), each individual token and the popularity of this pair (how many DEX's support this trade)
    :param dex:
    :return:
    """
    # get the factory of this DEX
    factory_address = dexes[dex]['factory']
    factory = bsc_client.get_contract(factory_address)

    # amount of pools in this factory
    length = factory.functions.allPairsLength().call()

    # iterate over every pool in this DEX's factory
    for i in range(length):
        process_pool(factory, i)


def process_pool(factory, i):
    # contract pool i
    pool_address = factory.functions.allPairs(i).call()
    pool = bsc_client.get_contract(pool_address)

    # ERC20 addresses of both tokens in the pool
    token0 = pool.functions.token0().call()
    token1 = pool.functions.token1().call()

    # token 0
    token0_symbol = get_symbol_by_address(token0)

    # token 1
    token1_symbol = get_symbol_by_address(token1)

    # Add token 0 and token 1 to list of all known tokens, skip duplicates
    if token0_symbol not in data['tokens'].keys():
        data['tokens'][token0_symbol] = token0

    if token1_symbol not in data['tokens'].keys():
        data['tokens'][token1_symbol] = token1

    # Now add the pair to the list of known pairs, skip duplicates
    duplicate = f'{token0_symbol}_{token1_symbol}' in data[
        'pairs'].keys() or f'{token1_symbol}_{token0_symbol}' in data['pairs'].keys()

    if not duplicate:
        # calculate popularity
        popularity = 0
        pair = {}

        # calculate pair popularity and its pools across DEX's
        for dex in data['dex']['working']:
            pool = dex_supports(dex, [token0, token1])

            if pool is not None:
                popularity = popularity + 1
            pair[dex] = pool

        pair['popularity'] = popularity

        # add the pair
        data['pairs'][f'{token0_symbol}_{token1_symbol}'] = pair

        print(json.dumps(pair, indent=4, default=str))


def dex_supports(dex, token_pair):
    """
    Check whether or not the specified DEX supports a trade pair (does it provide a pool for this pair)

    :param dex: name of the DEX
    :param token_pair: [token 0, token 1]
    :return: None if not supported, else the pair's pool address
    """
    factory_address = data['dex']['working'][dex]['factory']
    factory = bsc_client.get_contract(factory_address)

    pool = None
    try:
        pool = factory.functions.getPair(token_pair[0], token_pair[1]).call()
        if int(pool, 16) == 0x0:
            pool = None
    except Exception:
        pass

    return pool


if __name__ == "__main__":
    get_all_pools()
