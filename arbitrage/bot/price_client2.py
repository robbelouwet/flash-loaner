import json
import asyncio
import sys
import time
from decimal import Decimal
from tabulate import tabulate
from model.bsc_client import BscClient
from model.data_client import DataClient
from utils.globals import get_logger
from utils.utils import run_in_executor, execute_concurrently

logger = get_logger()
bsc_client = BscClient.get_instance()
data_client = DataClient.get_instance()


def write_results_to_csv(results, block):
    res_keys = results.keys()

    for key in res_keys:
        pass


@run_in_executor
def amount_out(dex, pool, token_in, amount_in, token_out, results, reverse=False):
    """
    For a given DEX and a given pair, calculate the optimal amount of token0 to buy, so that
    we get the optimal amount of token1 in return.

    @param amount_in: if specified, will use this amount to calculate price, instead of calculating optimal amount
    @param dex: the dex: e.g.: 'PancakeSwap'
    @param pool: pool address of the pair, used to query reserves
    @param token_in: symbol of the token to sell
    @param token_out: symbol of the token to buy
    @param results: array that contains the amount we're buying, and the amount we get for it n return
    @param reverse: whether we want to reverse the trade (so buy token_in and sell token_out)
    """
    # get reserves of pool
    # We can cast to our PancakePair ABI, because every DEX is a fork from UniSwap, they all share the same ABI.
    pool_ctr = bsc_client.get_instance().get_contract(pool, cast_abi="PancakePair", cast=True)
    reserve_in, reserve_out, _ = pool_ctr.functions.getReserves().call()

    # The more we buy, the less equivalent value we get for it in return
    # the less we buy, the less arbitrage profit we will make
    # calculate a (somewhat) optimal buy amount based on reserves
    if amount_in is None:
        amount_in = calculate_buy_amount(reserve_in, reserve_out)

    # sometimes the reserve is really low on dexes that aren't widely used
    if amount_in < 1:
        return None

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
    if _amount_out == 0:
        return None

    if reverse:
        unit_price = amount_in / _amount_out

    else:
        unit_price = _amount_out / amount_in

    results.append(
        [dex, amount_in, token_in, _amount_out, token_out, unit_price, amount_in / reserve_in,
         _amount_out / reserve_out])


def calculate_buy_amount(reserve_in, reserve_out):
    """
    Used to calculate the optimal amount to buy.

    @param reserve_in:
    @param reserve_out:
    @return:
    """
    return int(0.01 * reserve_in)
    # return 1


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
    """
    Gets the best offer for selling and rebuying. token[0] (token IN) is what wel sell first (what we flash loan),
    """
    if reverse:
        t0 = pair['token1']
        t1 = pair['token0']
    else:
        t0 = pair['token0']
        t1 = pair['token1']

    results = []
    functions = []
    # now for every dex, see how many OUT tokens we get for a given amount of IN tokens
    for dex in pair['pools'].keys():
        pool_adr = pair['pools'][dex]
        if pool_adr is not None:
            functions.append([amount_out, dex, pool_adr, t0, amount, t1, results, reverse])

    await execute_concurrently(functions)
    return results


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

    results = []

    # try both pairs
    # see if, in our saved pairs in the json, either BUSD_WBNB or WBNB_BUSD exists
    # if one does, then get the best offer for selling and buying
    option1 = f'{symbol_in}_{symbol_out}'
    option2 = f'{symbol_out}_{symbol_in}'
    if option1 in all_pair_keys:
        if pairs[option1]['token0'] == symbol_in:
            results = await get_pair_quota(pairs[option1], amount, False)
        elif pairs[option1]['token1'] == symbol_in:
            results = await get_pair_quota(pairs[option1], amount, True)

    if option2 in all_pair_keys:
        if pairs[option2]['token0'] == symbol_in:
            results = await get_pair_quota(pairs[option2], amount, False)
        elif pairs[option2]['token1'] == symbol_in:
            results = await get_pair_quota(pairs[option2], amount, True)

    return results


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
    :return:
    """

    all_tokens = data_client.get_tokens()

    decimals = 0
    for adr in all_tokens.keys():
        if all_tokens[adr]['symbol'] == symbol:
            decimals = all_tokens[adr]['decimals']
            break
    return Decimal(amount / (10 ** decimals))


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
    stable_coin_amount = 0

    if token == stablecoin:
        stable_coin_amount = amount
    else:
        prices = await get_trade_prices(token, stablecoin, amount)
        if len(prices) != 0:
            stable_coin_amount = max([r[3] for r in prices])

    return [token, stablecoin, stable_coin_amount]


def summarize_profits(profits):
    keys = profits.keys()

    summarized_profits = {}
    for key in keys:
        if profits[key] is None:
            continue
        token = profits[key]['profit_token']
        if token in summarized_profits.keys():
            summarized_profits[token] = summarized_profits[token] + profits[key]['profit_amount']
        else:
            summarized_profits[token] = profits[key]['profit_amount']
    return summarized_profits


async def get_best_dex(symbol_in, symbol_out, amount=None):
    """
    Finds the DEX which offers the best trade for the given pair
    @param amount:
    @param symbol_in:
    @param symbol_out:
    @return:
    """
    results = await get_trade_prices(symbol_in, symbol_out, amount)
    if len(results) == 0:
        return None
    highest_return = max([r[3] for r in results])
    for r in results:
        if r[3] == highest_return:
            return r


async def get_trade_profit(symbol_in, symbol_out):
    best_buy_opportunity = await get_best_dex(symbol_in, symbol_out)
    if best_buy_opportunity is None:
        return None
    table_in = tabulate(tabular_data=[best_buy_opportunity],
                        headers=["DEX", "AMOUNT IN", "TOKEN IN", "AMOUNT OUT", "TOKEN OUT", "IN/OUT", "RESERVE_IN %",
                                 "RESERVE_OUT %"])

    best_sell_opportunity = await get_best_dex(symbol_out, symbol_in, best_buy_opportunity[3])
    if best_sell_opportunity is None:
        return None
    table_out = tabulate(tabular_data=[best_sell_opportunity],
                         headers=["DEX", "AMOUNT IN", "TOKEN IN", "AMOUNT OUT", "TOKEN OUT", "IN/OUT", "RESERVE_IN %",
                                  "RESERVE_OUT %"])

    # calculate profit
    profit = int(Decimal(best_sell_opportunity[3]) - Decimal(best_buy_opportunity[1]))
    normalized_profit = normalize(symbol_in, profit)
    if profit > 0:
        print(table_in)
        print(table_out)
        print('###')
        print(f"Profit: {'%f' % normalized_profit}")
        print(f'{symbol_in}')
        print('###')

        return {
            "profit_amount": profit,
            "profit_token": symbol_in,
            "start_loan": best_buy_opportunity[3],
            "buy_opportunity": best_buy_opportunity,
            "sell_opportunity": best_sell_opportunity
        }
    else:
        logger.info(
            f'Tested {round(normalize(symbol_in, best_buy_opportunity[1]), 5):,} {symbol_in}_{symbol_out}: {round(normalized_profit, 5):,} {symbol_in} loss')
        return None


async def main():
    start_time = time.time()
    all_pairs = data_client.get_pairs().keys()

    functions = []

    for pair in all_pairs:
        t0 = data_client.get_pairs()[pair]['token0']
        t1 = data_client.get_pairs()[pair]['token1']
        functions.append([get_trade_profit, t0, t1])
        # break

    results = await execute_concurrently(functions, True)

    latest_block_number = bsc_client.get_latest_block_number()

    # write_results_to_csv(results, latest_block_number)

    summarized = summarize_profits(results)
    print(json.dumps(summarized, indent=4, default=str))

    total_busd_profit = await convert_all_to_stablecoin(summarized)
    print(f'Total profit: {normalize("BUSD", total_busd_profit)} BUSD')
    print(f'Execution time: {time.time() - start_time}')


def run():
    asyncio.run(main(), debug=True)
