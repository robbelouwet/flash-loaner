import json
from utils import globals
from utils.web3_utils import get_abi, get_address_by_symbol
from web3 import Web3

web3 = Web3(Web3.HTTPProvider('https://bsc-dataseed1.binance.org'))

network_data = globals.network_data()
all_pairs = globals.network_data()['dex']['pancakeBakeryPairs']


def get_pancake_pools(dex):
    """
    Querries the DEX Factory contract for the liquidity pools of (most) of our tradable pairs
    :type dex: DEX to query the liquidity pools from
    :return:
    """
    factory = network_data['bsc'][dex]['factory']
    abi = get_abi(factory)

    factory = web3.eth.contract(abi=abi, address=factory)

    for pair in all_pairs:
        p0 = None
        p1 = None
        try:
            p0 = get_address_by_symbol(pair[0])
            p1 = get_address_by_symbol(pair[1])
        except ValueError as e:
            print(f'{pair[0]} or {pair[1]} not found on pancakeswap')

        if p0 is not None and p1 is not None:
            liquidity_contract = factory.functions.getPair(p0, p1).call()
            network_data['dex'][dex]['liquidityPools'][f'{pair[0]}_{pair[1]}']['contract'] = liquidity_contract

    io = open('../resources/data.json', 'w')
    io.write(json.dumps(network_data, indent=4))


get_pancake_pools("PancakeSwap")
get_pancake_pools("BakerySwap")
