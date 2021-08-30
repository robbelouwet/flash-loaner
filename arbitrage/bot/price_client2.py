import asyncio
import sys
import time
from decimal import Decimal
from tabulate import tabulate
from model.bsc_client import BscClient
from model.data_client import DataClient
from utils.utils import run_in_executor, execute_concurrently

bsc_client = BscClient.get_instance()
data_client = DataClient.get_instance()


@run_in_executor
def amount_out(dex, pool, token_in, amount_in, token_out, results):
    """
    Get amountOut for a specific pair

    :return:
    """
    # get reserves of pool
    # We can cast to our PancakePair ABI, because every DEX is a fork from UniSwap, they all share the same ABI.
    pool_ctr = bsc_client.get_instance().get_contract(pool, cast_abi="PancakePair", cast=True)
    reserve_in, reserve_out, _ = pool_ctr.functions.getReserves().call()

    # get router
    router_address = data_client.get_data()['dex']['working'][dex]['router']
    router = bsc_client.get_contract(router_address, cast_abi="PancakeRouter", cast=True)

    # -> token_in
    # -> amount_in
    # <- amount_out
    _amount_out = router.functions.getAmountOut(amount_in, reserve_in, reserve_out).call()
    results.append([dex, amount_in, token_in, _amount_out, token_out])


async def get_average_reserve(pair, reverse):
    reserves = []
    functions = []
    for dex in pair['pools'].keys():
        pool_adr = pair['pools'][dex]
        if pool_adr is not None:
            functions.append([get_reserves, pool_adr, reserves, reverse])

    await execute_concurrently(functions)
    return reserves


@run_in_executor
def get_reserves(pool_adr, results, reverse):
    """
    Returns the reserve of token0 in this pair!

    :param reverse: specified if we want the reserves of the out_token
    :param pool_adr:
    :param results:
    :return:
    """
    contract = bsc_client.get_contract(pool_adr, cast_abi="PancakePair", cast=True)
    reserve0, reserve1, _ = contract.functions.getReserves().call()
    if reverse:
        results.append(reserve1)
    else:
        results.append(reserve0)


async def get_pair_quota(pair, amount=None, reverse=False):
    if reverse:
        t0 = pair['token1']
        t1 = pair['token0']
    else:
        t0 = pair['token0']
        t1 = pair['token1']

    # get 1% of the average reserve of token0
    # in other words, token0 is considered the token that is being sold, token1 is whet we get in return
    reserves = await get_average_reserve(pair, reverse)
    if amount is None:
        amount = 490 # round(Decimal(0.0001) * Decimal(sum(reserves) / len(reserves)))

    results = []
    functions = []
    for dex in pair['pools'].keys():
        pool_adr = pair['pools'][dex]
        if pool_adr is not None:
            functions.append([amount_out, dex, pool_adr, t0, amount, t1, results])

    await execute_concurrently(functions)

    print(tabulate(tabular_data=results, headers=["DEX", "AMOUNT IN", "TOKEN IN", "AMOUNT OUT", "TOKEN OUT"]))
    return [results, amount]


async def get_trade_prices(symbol_in, symbol_out, amount=None):
    """
    Calculates the amount of symbol_out tokens you will get for a certain amount of symbol_in tokens, for every DEX.
    The amount is calculated automatically later on, based on available reserves to maximize profit

    :param amount:
    :param symbol_in:
    :param symbol_out:
    :return:
    """
    # first find the pair in our list of known pairs
    pairs = data_client.get_pairs()
    all_pair_keys = pairs.keys()

    prices = []

    option1 = f'{symbol_in}_{symbol_out}'
    option2 = f'{symbol_out}_{symbol_in}'
    if option1 in all_pair_keys:
        if pairs[option1]['token0'] == symbol_in:
            [prices, amount] = await get_pair_quota(pairs[option1], amount, False)
        elif pairs[option1]['token1'] == symbol_in:
            [prices, amount] = await get_pair_quota(pairs[option1], amount, True)

    if option2 in all_pair_keys:
        if pairs[option2]['token0'] == symbol_in:
            [prices, amount] = await get_pair_quota(pairs[option2], amount, False)
        elif pairs[option2]['token1'] == symbol_in:
            [prices, amount] = await get_pair_quota(pairs[option2], amount, True)

    return [prices, amount]


async def get_trade_profit(symbol_in, symbol_out):
    ### HERE vvvv gettrade...
    [sell_amounts, bought_amount] = await get_trade_prices(symbol_in, symbol_out)
    best_sell_amount = max(sell_amounts)

    buy_back_amounts = await get_trade_prices(symbol_out, symbol_in)
    best_buy_back_amount = max(buy_back_amounts)
    return bought_amount - best_buy_back_amount


async def main():
    # pairs = list(data_client.get_pairs().keys())[0:5]
    # for pair in pairs:
    #    await get_pair_quota(data_client.get_pairs()[pair])
    await get_trade_profit("BUSD", "WBNB")


if __name__ == "__main__":
    start_time = time.time()
    asyncio.run(main(), debug=True)
    print(f"Execution time: {round(time.time() - start_time, 2)}s")
