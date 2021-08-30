from model.bsc_client import BscClient
from model.data_client import DataClient

data_client = DataClient.get_instance()
data = data_client.get_data()
bsc_client = BscClient.get_instance()


def get_tokens_from_pairs():
    pair_keys = data['pairs'].keys()  # BUSD_WBNB, ...
    token_keys = list(data['all_tokens'].keys())  # "0x....", ...

    for pair_key in pair_keys:
        pair = data['pairs'][pair_key]

        # see if token0 exists in our list of tokens
        if pair['address0'] not in token_keys:
            print(f"{pair['token0']} was not found")
            decimals = None
            try:
                ctr = bsc_client.get_contract(pair['address0'], cast_abi="ERC20", cast=False, sleep=True)
                decimals = ctr.fundtions.decimals().call()
                if decimals is not None:
                    print(f'Found decimals {decimals}')
            except Exception:
                print(f"Could not cast ERC20 to {pair['token0']}")
            data['tokens'][pair['address0']] = {
                'symbol': pair['token0'],
                'decimals': decimals
            }

        # see if token1 exists in our list of tokens
        if pair['address1'] not in token_keys:
            print(f"{pair['token1']} was not found")
            decimals = None
            try:
                ctr = bsc_client.get_contract(pair['address0'], cast_abi="ERC20", cast=False, sleep=True)
                decimals = ctr.functions.decimals().call()
                if decimals is not None:
                    print(f'Found decimals {decimals}')
            except Exception:
                print(f"Could not cast ERC20 to {pair['token1']}")
            data['tokens'][pair['address1']] = {
                'symbol': pair['token1'],
                'decimals': decimals
            }
    data_client.update_data(data)


if __name__ == "__main__":
    get_tokens_from_pairs()
