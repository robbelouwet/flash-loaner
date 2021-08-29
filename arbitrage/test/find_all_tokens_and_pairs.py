"""
TOKEN: address

P0_P1: {
popularity,
PancakeSwap: pool_address
BakerySwap: None
...
}
"""
import json

from test.find_liquidity_contracts import dex_supports
from utils.globals import network_data
from utils.web3_utils import get_web3, get_abi

data = network_data()
all_tokens = data['all_tokens']
web3 = get_web3()


def find_all_tokens():
    """
    Queries our known DEX's for every possible pair that can be made with all_tokens in data.json,
    if that pair has a pool.

    :return:
    """
    global all_tokens

    for a0 in all_tokens.keys():
        t0 = all_tokens[a0]['symbol']
        for a1 in all_tokens.keys():
            t1 = all_tokens[a1]['symbol']

    io = open('../resources/data.json', 'w')
    io.write(json.dumps(data, indent=4, default=str))


def print_popular_pairs():
    io = open('../resources/popular_trade_pairs.json')
    data1 = json.loads(io.read())

    count = 0
    for pair in data1['ethereum']['dexTrades']:
        t0 = pair['buyCurrency']['symbol']
        a0 = web3.toChecksumAddress(pair['buyCurrency']['address'])

        t1 = pair['sellCurrency']['symbol']
        a1 = web3.toChecksumAddress(pair['sellCurrency']['address'])

        duplicate = f'{t0}_{t1}' in data['pairs'].keys() or f'{t1}_{t0}' in data['pairs'].keys()
        if duplicate:
            continue

        count = count + 1

        popularity = 0
        pair = {}

        # calculate pair popularity and its pools across DEX's
        for dex in data['dex']['working']:
            pool = dex_supports(dex, [a0, a1])

            if pool is not None:
                popularity = popularity + 1
            pair[dex] = pool

        pair['popularity'] = popularity

        print(f'{count}; {t0}_{t1}: ', pair)

        # add the pair
        data['pairs'][f'{t0}_{t1}'] = pair

    io = open('../resources/data.json', 'w')
    io.write(json.dumps(data, indent=4, default=str))


def filter_tokens():
    """
    remove pairs that have 0 or 1 popularity

    :return:
    """

    keys_to_delete = []
    for key in data['pairs'].keys():
        if data['pairs'][key]['popularity'] <= 1:
            keys_to_delete.append(key)

    for key2 in keys_to_delete:
        data['pairs'].pop(key2)

    io = open('../resources/data.json', 'w')
    io.write(json.dumps(data, indent=4, default=str))


def find_corresponding_symbols():
    for pair in data['pairs'].keys():
        symbols = pair.split("_")

        # find token[0]
        for token in data['all_tokens'].keys():
            if data['all_tokens'][token]['symbol'] == symbols[0]:
                data['pairs'][pair]['token0'] = token

        # find token[1]
        for token in data['all_tokens'].keys():
            if data['all_tokens'][token]['symbol'] == symbols[1]:
                data['pairs'][pair]['token1'] = token
    io = open('../resources/data.json', 'w')
    io.write(json.dumps(data, indent=4, default=str))


def find_token_not_found():
    count = 0
    for pair in data['pairs'].keys():
        count = count + 1

        # if we have no token0 or token1 present, look them up if possible, using one of the pool contracts
        if 'token0' not in data['pairs'][pair].keys() or 'token1' not in data['pairs'][pair].keys():
            print(f"Querying {pair}... {count}/{len(data['pairs'].keys())}")
            results = []

            # find a random, not null pool, and query it for token0 and token1
            for dex in data['pairs'][pair]["pools"].keys():
                pool = data['pairs'][pair]["pools"][dex]
                if pool is not None:
                    results = get_token_symbols_from_pool(pool)
                    break

            token0 = results[0]
            symbol0 = results[1]
            token1 = results[2]
            symbol1 = results[3]

            # find out which symbols to compare using the XXX_YYY key of the dict
            split_pair = pair.split("_")

            # now we have data anbout the pair
            if 'token0' not in data['pairs'][pair].keys():
                if split_pair[0] == symbol0 or split_pair[1] == symbol0:
                    data['pairs'][pair]['address0'] = token0
                    data['pairs'][pair]['token0'] = symbol0

            if 'token1' not in data['pairs'][pair].keys():
                if split_pair[0] == symbol1 or split_pair[1] == symbol1:
                    data['pairs'][pair]['address1'] = token1
                    data['pairs'][pair]['token1'] = symbol1

    io = open('../resources/data.json', 'w')
    io.write(json.dumps(data, indent=4, default=str))


def get_token_symbols_from_pool(pool):
    contract = web3.eth.contract(abi=get_abi(pool), address=pool)

    # token0
    token0_address = None
    symbol0 = None
    try:
        token0_address = contract.functions.token0().call()
        token0 = web3.eth.contract(abi=get_abi(token0_address), address=token0_address)
        symbol0 = token0.functions.symbol().call()
    except Exception:
        pass

    # token0
    token1_address = None
    symbol1 = None
    try:
        token1_address = contract.functions.token1().call()
        token1 = web3.eth.contract(abi=get_abi(token1_address), address=token1_address)
        symbol1 = token1.functions.symbol().call()
    except Exception:
        pass

    return [token0_address, symbol0, token1_address, symbol1]


if __name__ == "__main__":
    find_token_not_found()
