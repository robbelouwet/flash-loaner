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

from model.bsc_client import BscClient
from model.data_client import DataClient
from test.find_liquidity_contracts import dex_supports

data = DataClient.get_instance().get_data()
all_tokens = DataClient.get_instance().get_tokens()
bsc_client = BscClient.get_instance()


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
        a0 = bsc_client.to_checksum_address(pair['buyCurrency']['address'])

        t1 = pair['sellCurrency']['symbol']
        a1 = bsc_client.to_checksum_address(pair['sellCurrency']['address'])

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
        if data['pairs'][pair]['token0'] is None or data['pairs'][pair]['token1'] is None:
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

            # if one of both token symbols is unknown (because of an unverified abi for example)
            # try to recover it anyway
            if split_pair[1] == symbol1:
                symbol0 = split_pair[0]
            elif split_pair[0] == symbol0:
                symbol1 = split_pair[1]
            elif split_pair[1] == symbol0:
                symbol1 = split_pair[0]
            elif split_pair[0] == symbol1:
                symbol0 = split_pair[1]

            if split_pair[0] == symbol0 or split_pair[1] == symbol0:
                data['pairs'][pair]['address0'] = token0
                data['pairs'][pair]['token0'] = symbol0
                data['pairs'][pair]['address1'] = token1
                data['pairs'][pair]['token1'] = symbol1

            if split_pair[0] == symbol1 or split_pair[1] == symbol1:
                data['pairs'][pair]['address1'] = token1
                data['pairs'][pair]['token1'] = symbol1
                data['pairs'][pair]['address0'] = token0
                data['pairs'][pair]['token0'] = symbol0

    io = open('../resources/data.json', 'w')
    io.write(json.dumps(data, indent=4, default=str))


def get_token_symbols_from_pool(pool):
    contract = bsc_client.get_contract(pool)

    # token0
    token0_address = contract.functions.token0().call()
    symbol0 = None
    try:
        token0 = bsc_client.get_contract(token0_address)
        symbol0 = token0.functions.symbol().call()
    except Exception:
        pass

    # token0
    token1_address = contract.functions.token1().call()
    symbol1 = None
    try:
        token1 = bsc_client.get_contract(token1_address)
        symbol1 = token1.functions.symbol().call()
    except Exception:
        pass

    return [token0_address, symbol0, token1_address, symbol1]


if __name__ == "__main__":
    find_token_not_found()
