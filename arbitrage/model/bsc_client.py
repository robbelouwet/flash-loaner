import json
import requests
from web3 import Web3
from web3.exceptions import ABIFunctionNotFound
from utils.globals import get_logger
from utils.utils import get_abi


class BscClient:
    INSTANCE = None

    def __init__(self, node_url):
        self.__web3__ = Web3(Web3.HTTPProvider(node_url))
        self.__logger__ = get_logger()

    def get_contract(self, address, cast_abi=None, cast=False, sleep=False):
        abi = get_abi(address, cast_abi, cast, sleep)
        return self.__web3__.eth.contract(abi=abi, address=address)

    def get_pool(self, factory, pool_index):
        pass

    def get_decimals_from_api(self, address, symbol):
        resp = requests.post(
            url='https://eu.bsc.chaingateway.io/v1/getToken?apikey=f8fb08bdf2512083bd750a34528ff93b93884e94', headers={
                'Content-Type': 'application/json'
            }, data=json.dumps({
                'contractaddress': f'{address}',
                'apikey': 'f8fb08bdf2512083bd750a34528ff93b93884e94'
            })).json()

        decimals = int(resp['decimals'])

        self.__logger__.info(f'API: {symbol} = {decimals}')
        return decimals

    def get_decimals_from_contract(self, address, symbol):
        decimals = None
        try:
            contract = self.get_contract(address, cast_abi="PancakePair", cast=True, sleep=True)

            decimals = contract.functions.decimals().call()
            if decimals is not None:
                self.__logger__.info(f'Contract: {symbol} = {decimals}')

        except ABIFunctionNotFound as e:
            self.__logger__.error(f'Could not get decimals from token {symbol}:\n{e}')

        except Exception as e:
            self.__logger__.error(f'Error with abi/contract of {symbol}:\n{e}')

        return decimals

    def to_checksum_address(self, address):
        return self.__web3__.toChecksumAddress(address)

    @classmethod
    def get_instance(cls):
        if BscClient.INSTANCE is None:
            BscClient.INSTANCE = BscClient('https://bsc-dataseed1.binance.org')
        return BscClient.INSTANCE
