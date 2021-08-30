from model.bsc_client import BscClient
from model.data_client import DataClient
from utils.utils import get_web3, get_abi, get_decimals, get_symbol_by_address

data = DataClient.get_instance().get_data()
bsc_client = BscClient.get_instance()


def get_approximate_reserves(pool):
    """
    Queries the pool's getReserves() and stores it (for both tokens in the pool)

    :param pool: address of the liquidity pool
    :return:
    """
    contract = bsc_client.get_contract(pool)

    token0 = contract.functions.token0().call()
    token1 = contract.functions.token1().call()

    token0_symbol = get_symbol_by_address(bsc_client.to_checksum_address(token0))
    token1_symbol = get_symbol_by_address(bsc_client.to_checksum_address(token1))

    decimals0 = get_decimals(token0)
    decimals1 = get_decimals(token1)

    [reserve0, reserve1, block_timestamp] = contract.functions.getReserves().call()

    reserve0_rebased = reserve0 / (10 ** decimals0)
    reserve1_rebased = reserve1 / (10 ** decimals1)

    return {
        "token0": token0_symbol,
        "reserve0_rebased": reserve0_rebased,
        "token1": token1_symbol,
        "reserve1_rebased": reserve1_rebased,
        "block_timestamp": block_timestamp
    }
