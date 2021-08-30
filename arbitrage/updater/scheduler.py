import json

from config import ROOT_DIR
from model.data_client import DataClient
from updater.main import get_approximate_reserves

data = DataClient.get_instance().get_data()


def update_all_reserves():
    """
    Updates the reserve of every pool in data.json
    :return:
    """
    global data
    for dex in data['dex'].keys():
        for pool in data['dex'][dex]['liquidityPools'].keys():
            reserves = get_approximate_reserves(data['dex'][dex]['liquidityPools'][pool])
            reserves['pool'] = data['dex'][dex]['liquidityPools'][pool]
            data['dex'][dex]['liquidityPools'][pool] = reserves
    print(json.dumps(data, indent=4, default=str))
    io = open(f'{ROOT_DIR}/resources/data.json', 'w')
    # io.write(json.dumps(data, indent=4, default=str))


if __name__ == "__main__":
    update_all_reserves()
