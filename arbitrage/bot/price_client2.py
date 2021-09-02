import json
import sys

sys.path.append(f'../model')
import asyncio
import time
from decimal import Decimal
from tabulate import tabulate
from model.bsc_client import BscClient
from model.data_client import DataClient
from utils.globals import get_logger
from utils.utils import run_in_executor, execute_concurrently
import cProfile

logger = get_logger()
bsc_client = BscClient.get_instance()
data_client = DataClient.get_instance()


@run_in_executor
def amount_out(dex, pool, token_in, amount_in, token_out, results, reverse=False, ):
    """
    Get amountOut for a specific pair

    :return:
    """
    # get reserves of pool
    # We can cast to our PancakePair ABI, because every DEX is a fork from UniSwap, they all share the same ABI.
    pool_ctr = bsc_client.get_instance().get_contract(pool, cast_abi="PancakePair", cast=True)
    reserve_in, reserve_out, _ = pool_ctr.functions.getReserves().call()

    if reverse:
        temp = reserve_in
        reserve_in = reserve_out
        reserve_out = temp

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
        amount = round(Decimal(0.00001) * Decimal(sum(reserves) / len(reserves)))

    results = []
    functions = []
    for dex in pair['pools'].keys():
        pool_adr = pair['pools'][dex]
        if pool_adr is not None:
            functions.append([amount_out, dex, pool_adr, t0, amount, t1, results, reverse])

    await execute_concurrently(functions)
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
    # First, find the best opportunity to sell our flash loan
    [results, bought_amount] = await get_trade_prices(symbol_in, symbol_out)
    normalized_bought_amount = normalize(symbol_in, bought_amount)
    best_sell_amount = max([r[3] for r in results])
    table_in = ""
    best_sell_oportunity = []
    for r in results:
        if r[3] == best_sell_amount:
            best_sell_oportunity = r
            normalized_in = normalize_results(r)
            table_in = tabulate(tabular_data=[normalized_in],
                                headers=["DEX", "AMOUNT IN", "TOKEN IN", "AMOUNT OUT", "TOKEN OUT"])

    # Second, find the best opportunity to trade our loaned amount back
    [buy_back_amounts, _] = await get_trade_prices(symbol_out, symbol_in, amount=best_sell_amount)
    best_buy_back_amount = max([r[3] for r in buy_back_amounts])
    best_buy_back_opportunity = []
    table_out = ""
    for r in buy_back_amounts:
        if r[3] == best_buy_back_amount:
            normalized_out = normalize_results(r)
            best_buy_back_opportunity = r
            table_out = tabulate(tabular_data=[normalized_out],
                                 headers=["DEX", "AMOUNT IN", "TOKEN IN", "AMOUNT OUT", "TOKEN OUT"])

    # calculate profit
    profit = best_buy_back_amount - bought_amount
    normalized_profit = normalize(symbol_in, profit)
    if profit > 0:
        print(table_in)
        print(table_out)
        print('###')
        print(f"Profit: {'%f' % normalized_profit}")
        print(f'{symbol_in}')
        print('###')

        # [profit, symbol_in]
        ret = {
            "profit_amount": profit,
            "profit_token": symbol_in,
            "start_loan": bought_amount,
            "sell_opportunity": best_sell_oportunity,
            "buy_back_opportunity": best_buy_back_opportunity
        }
        return ret
    else:
        logger.info(
            f'Tested {round(normalized_bought_amount, 5):,} {symbol_in}_{symbol_out}: {round(normalized_profit, 5):,} {symbol_in} loss')
        return None


def normalize_results(res):
    symbol0 = res[2]
    symbol1 = res[4]

    amount0_normalized = normalize(symbol0, res[1])
    amount1_normalized = normalize(symbol1, res[3])

    return [res[0], amount0_normalized, res[2], amount1_normalized, res[4]]


def normalize(symbol, amount):
    """
    Given a symbol and an amount, returns the normalized amount according to its saved decimal count.
    :param amount:
    :param symbol:
    :param res:
    :return:
    """

    all_tokens = data_client.get_tokens()

    decimals = 0
    for adr in all_tokens.keys():
        if all_tokens[adr]['symbol'] == symbol:
            decimals = all_tokens[adr]['decimals']
            break
    return Decimal(amount / (10 ** decimals))


def summarize_profits(profits):
    keys = profits.keys()

    summarized_profits = {}
    for key in keys:
        token = profits[key]['profit_token']
        if token in summarized_profits.keys():
            summarized_profits[token] = summarized_profits[token] + profits[key]['profit_amount']
        else:
            summarized_profits[token] = profits[key]['profit_amount']
    return summarized_profits


async def convert_all_to_stablecoin(results):
    keys = results.keys()

    base_tokens = ["WBNB", "BUSD"]

    converted_results = {}
    conversions = []
    for base_token in base_tokens:
        converted_results[base_token] = 0
        for token in keys:
            if results[token] is None:
                continue
            conversions.append([to_stablecoin, token, results[token], base_token])

    results = await execute_concurrently(conversions, are_async=True)

    for res in results:
        if results[res][2] is None:
            continue
        stablec = results[res][1]
        stablec_amount = results[res][2]
        converted_results[stablec] = converted_results[stablec] + stablec_amount

    # lastly, convert our WBNB amount to BUSD:
    [_, _, busd] = await to_stablecoin("WBNB", converted_results["WBNB"], "BUSD")
    converted_results["BUSD"] = converted_results["BUSD"] + busd
    return converted_results["BUSD"]


async def to_stablecoin(token, amount, stablecoin):
    stable_coin_amount = None

    if token == stablecoin:
        stable_coin_amount = amount
    else:
        [prices, _] = await get_trade_prices(token, stablecoin, amount)
        if len(prices) != 0:
            stable_coin_amount = max([r[3] for r in prices])

    return [token, stablecoin, stable_coin_amount]


# +- 48s
async def main():
    start_time = time.time()
    all_pairs = data_client.get_pairs().keys()

    functions = []

    for pair in all_pairs:
        t0 = data_client.get_pairs()[pair]['token0']
        t1 = data_client.get_pairs()[pair]['token1']
        functions.append([get_trade_profit, t0, t1])

    results = await execute_concurrently(functions, True)

    summarized = summarize_profits(results)
    print(json.dumps(summarized, indent=4, default=str))

    total_busd_profit = await convert_all_to_stablecoin(summarized)
    print(f'Total profit: {normalize("BUSD", total_busd_profit)} BUSD')
    print(f'Execution time: {time.time() - start_time}')


def run():
    asyncio.run(main(), debug=True)
