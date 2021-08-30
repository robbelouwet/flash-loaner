import json


class DataClient:
    INSTANCE = None

    def __init__(self, data_path, abis_path):
        self.__data_resource__ = data_path
        self.__abis_resource__ = abis_path

        # data:
        io = open(self.__data_resource__, 'r')
        self.__data__ = json.loads(io.read())
        io.close()

        # data:
        io1 = open(self.__abis_resource__, 'r')
        self.__abis__ = json.loads(io1.read())
        io1.close()

    def get_data(self):
        return self.__data__

    def get_pair(self, pair):
        return self.get_pairs()[pair]

    def get_pairs(self):
        return self.__data__['pairs']

    def get_tokens(self):
        return self.__data__['all_tokens']

    def get_dexes(self):
        return self.__data__['dex']['working']

    def get_factory_abi(self):
        return self.__abis__['PancakeFactory']

    def get_router_abi(self):
        return self.__abis__['PancakeRouter']

    def get_pair_abi(self):
        return self.__abis__['PancakePair']

    def update_data(self, data):
        io = open(self.__data_resource__, 'w')
        io.write(json.dumps(data, indent=4, default=str))
        io.close()

    @classmethod
    def get_instance(cls):
        if DataClient.INSTANCE is None:
            DataClient.INSTANCE = DataClient('../resources/data.json', '../resources/abis.json')

        return DataClient.INSTANCE
