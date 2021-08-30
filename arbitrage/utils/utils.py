import asyncio
import functools
import json
import time

from web3 import Web3
import requests
from web3.exceptions import ABIFunctionNotFound

from model.data_client import DataClient
from utils.globals import get_logger

logger = get_logger()
web3 = Web3(Web3.HTTPProvider('https://bsc-dataseed1.binance.org'))
data_client = DataClient.get_instance()
data = data_client.get_data()


def get_web3():
    return web3


def get_symbol_by_address(address):
    tokens = data.get_tokens()

    for key in tokens.keys():
        if key == web3.toChecksumAddress(address):
            return tokens[key]['symbol']


def get_address_by_symbol(symbol):
    tokens = data.get_tokens()

    for key in tokens.keys():
        if tokens[key]['symbol'] == symbol:
            return key
    raise ValueError('Not Found')


def get_decimals(address):
    tokens = data.get_tokens()

    for key in tokens:
        if key == address:
            return tokens[key]['decimals']


def get_pool_by_pair(pair, dex):
    pools = data['dex'][dex]['liquidityPools'].keys()

    candidate1 = f'{pair[0]}_{pair[1]}'
    candidate2 = f'{pair[1]}_{pair[0]}'

    for pool in pools:
        if pool == candidate1 or pool == candidate2:
            return data['dex'][dex]['liquidityPools'][pool]['pool']


def get_abi(address, cast_as_pancake=False, sleep=False):
    """
    Queries bscscan for the abi. If it isn't known, it returns the pancake version of the abi (if specified)
    :param sleep: useful with multi-threading to avoid hitting binance's API rate limit
    :param cast_as_pancake:
    :param address:
    :return:
    """
    # Binance API rate limit is 1 req/50 milliseconds
    if sleep:
        time.sleep(0.05)

    # print(f'REQUESTING ABI: {req_count}; {address}')
    res = requests.get('https://api.bscscan.com/api?module=contract&action=getabi'
                       f'&address={address}&apikey=QR4DM459W4XUCSN7WMWGR6RU23YNS81NWC'
                       '').json()['result']

    if res == 'Contract source code not verified':
        if cast_as_pancake is not None:
            if cast_as_pancake == "PancakeFactory":
                return data_client.get_factory_abi()
            elif cast_as_pancake == "PancakeRouter":
                return data_client.get_router_abi()
            elif cast_as_pancake == "PancakePair":
                return data_client.get_pair_abi()
    elif res[0] != '[':
        # TODO: is this dangerous? (recursion without stop condition)
        return get_abi(address, cast_as_pancake)
    return res


def get_pair_by_pool(dex, pool):
    """
    Returns the XXX_YYY pair of token symbols for the specified pool
    :param dex:
    :param pool:
    :return:
    """
    pools = data['dex'][dex]['liquidityPools'].keys()

    for pair in pools:
        if data['dex'][dex]['liquidityPools'][pair]['pool'] == pool:
            return pair


def run_in_executor(f):
    @functools.wraps(f)
    async def inner(*args, **kwargs):
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(None, lambda: f(*args, **kwargs))

    return inner


async def coroutine_wrapper(fun, *args, returns=False):
    """
    Wrap a method in an awaitable coroutine.
    e.g.: foo(1, 2, 3) -> (await) coroutine_wrapper(foo, 1, 2, 3)

    :param returns: True if the wrapped method returns a value, else False
    :param fun: the function to wrap
    :param args: the original method's arguments
    :return:
    """
    if not returns:
        await fun(*args)
    else:
        return await fun(*args)


async def execute_concurrently(blocking_functions):
    """
    Expects an array of blocking function pointers with their arguments,
    and executes them asynchronously and concurrently.

    e.g.:
    - def foo(a, b) -> int
    - def bar(c, d) -> None

    expects: [
        [foo, a, b],
        [bar, c, d]
    ]

    :param blocking_functions:
    :return: a dictionary, keys are the method names, values are the return values for that method
    """

    tasks = []
    for fun_ptrs in blocking_functions:
        tasks.append(asyncio.create_task(coroutine_wrapper(*fun_ptrs), name=fun_ptrs[0].__name__))

    task_results = {}
    for t in tasks:
        task_results[t.get_name()] = await t

    return task_results
