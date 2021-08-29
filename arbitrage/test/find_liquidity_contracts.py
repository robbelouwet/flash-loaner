import json
from decimal import Decimal

from utils import globals
from utils.web3_utils import get_web3, get_abi, get_symbol_by_address

web3 = get_web3()
network_data = globals.network_data()
dexes = globals.network_data()['dex']['working']

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
    factory_abi = get_abi(factory_address)
    factory = web3.eth.contract(abi=factory_abi, address=factory_address)

    # amount of pools in this factory
    length = factory.functions.allPairsLength().call()

    # iterate over every pool in this DEX's factory
    for i in range(length):
        process_pool(factory, i)


def process_pool(factory, i):
    # contract pool i
    pool_address = factory.functions.allPairs(i).call()
    pool_abi = get_abi(pool_address)
    pool = web3.eth.contract(abi=pool_abi, address=pool_address)

    # ERC20 addresses of both tokens in the pool
    token0 = pool.functions.token0().call()
    token1 = pool.functions.token1().call()

    # token 0
    #token0_abi = get_abi(token0)
    #token0_ctr = web3.eth.contract(abi=token0_abi, address=token0)
    token0_symbol = get_symbol_by_address(token0) #  token0_ctr.functions.symbol().call()

    # token 1
    #token1_abi = get_abi(token1)
    #token1_ctr = web3.eth.contract(abi=token1_abi, address=token1)
    token1_symbol = get_symbol_by_address(token1) #  token1_ctr.functions.symbol().call()

    # Add token 0 and token 1 to list of all known tokens, skip duplicates
    if token0_symbol not in network_data['tokens'].keys():
        network_data['tokens'][token0_symbol] = token0

    if token1_symbol not in network_data['tokens'].keys():
        network_data['tokens'][token1_symbol] = token1

    # Now add the pair to the list of known pairs, skip duplicates
    duplicate = f'{token0_symbol}_{token1_symbol}' in network_data[
        'pairs'].keys() or f'{token1_symbol}_{token0_symbol}' in network_data['pairs'].keys()

    if not duplicate:
        # calculate popularity
        popularity = 0
        pair = {}

        # calculate pair popularity and its pools across DEX's
        for dex in network_data['dex']['working']:
            pool = dex_supports(dex, [token0, token1])

            if pool is not None:
                popularity = popularity + 1
            pair[dex] = pool

        pair['popularity'] = popularity

        # add the pair
        network_data['pairs'][f'{token0_symbol}_{token1_symbol}'] = pair

        print(json.dumps(pair, indent=4, default=str))


def dex_supports(dex, token_pair):
    """
    Check whether or not the specified DEX supports a trade pair (does it provide a pool for this pair)

    :param dex: name of the DEX
    :param token_pair: [token 0, token 1]
    :return: None if not supported, else the pair's pool address
    """
    factory_address = network_data['dex']['working'][dex]['factory']
    factory_abi = get_abi(factory_address)
    factory = web3.eth.contract(abi=factory_abi, address=factory_address)

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
