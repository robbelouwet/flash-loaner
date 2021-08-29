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
from utils.web3_utils import get_web3

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


if __name__ == "__main__":
    filter_tokens()
