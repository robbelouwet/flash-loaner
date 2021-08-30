import asyncio
import time
from decimal import Decimal

from tabulate import tabulate

from model.bsc_client import BscClient
from model.data_client import DataClient
from utils.utils import run_in_executor, coroutine_wrapper, execute_concurrently

bsc_client = BscClient.get_instance()
data_client = DataClient.get_instance()


@run_in_executor
def amount_out(dex, pool, token_in, amount_in, token_out, results):
    """
    Get amountOut for a specific pair

    :return:
    """
    # get reserves of pool
    pool_ctr = bsc_client.get_instance().get_contract(pool, cast="PancakePair")
    reserve_in, reserve_out, _ = pool_ctr.functions.getReserves().call()

    # get router
    router_address = data_client.get_data()['dex']['working'][dex]['router']
    router = bsc_client.get_contract(router_address)

    # -> token_in
    # -> amount_in
    # <- amount_out
    _amount_out = router.functions.getAmountOut(amount_in, reserve_in, reserve_out).call()
    results.append([dex, amount_in, token_in, _amount_out, token_out])


async def get_average_reserve(pair):
    reserves = []
    functions = []
    for dex in pair['pools'].keys():
        pool_adr = pair['pools'][dex]
        if pool_adr is not None:
            functions.append([get_reserves, pool_adr, reserves])

    await execute_concurrently(functions)
    return reserves


@run_in_executor
def get_reserves(pool_adr, results):
    contract = bsc_client.get_contract(pool_adr, "PancakePair")
    reserve0, _, _ = contract.functions.getReserves().call()
    results.append(reserve0)


async def main():
    # take BUSD_WBNB for example
    str_pair = "BUSD_WBNB"
    pair = DataClient.get_instance().get_pair(str_pair)

    tokens = str_pair.split("_")
    t0 = tokens[0]
    t1 = tokens[1]

    # get 1% of the average reserve
    reserves = await get_average_reserve(pair)
    amount = round(Decimal(0.00001) * Decimal(sum(reserves) / len(reserves)))

    results = []
    functions = []
    for dex in pair['pools'].keys():
        pool_adr = pair['pools'][dex]
        if pool_adr is not None:
            functions.append([amount_out, dex, pool_adr, t0, amount, t1, results])

    await execute_concurrently(functions)

    print(tabulate(tabular_data=results, headers=["DEX", "AMOUNT IN", "TOKEN IN", "AMOUNT OUT", "TOKEN OUT"]))


if __name__ == "__main__":
    start_time = time.time()
    asyncio.run(main(), debug=True)
    print(f"Execution time: {round(time.time() - start_time, 2)}s")
