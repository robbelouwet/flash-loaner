import json
from web3 import Web3
import requests
from web3.exceptions import ABIFunctionNotFound
from utils.globals import get_logger, network_data

logger = get_logger()
web3 = Web3(Web3.HTTPProvider('https://bsc-dataseed1.binance.org'))
data = network_data()


def get_web3():
    return web3


def get_decimals_from_contract(address, symbol):
    global logger
    decimals = None
    try:
        abi = get_abi(address)
        contract = web3.eth.contract(address=address, abi=abi)

        decimals = contract.functions.decimals().call()
        if decimals is not None:
            logger.info(f'Contract: {symbol} = {decimals}')

    except ABIFunctionNotFound as e:
        logger.error(f'Could not get decimals from token {symbol}:\n{e}')

    except Exception as e:
        logger.error(f'Error with abi/contract of {symbol}:\n{e}')

    return decimals


def get_decimals_from_api(address, symbol):
    resp = requests.post(
        url='https://eu.bsc.chaingateway.io/v1/getToken?apikey=f8fb08bdf2512083bd750a34528ff93b93884e94',
        headers={'Content-Type': 'application/json'},
        data=json.dumps({'contractaddress': f'{address}', 'apikey': 'f8fb08bdf2512083bd750a34528ff93b93884e94'})).json()

    decimals = int(resp['decimals'])

    logger.info(f'API: {symbol} = {decimals}')
    return decimals


def get_symbol_by_address(address):
    tokens = data['all_tokens']

    for key in tokens.keys():
        if key == web3.toChecksumAddress(address):
            return tokens[key]['symbol']


def get_address_by_symbol(symbol):
    tokens = data['all_tokens']

    for key in tokens.keys():
        if tokens[key]['symbol'] == symbol:
            return key
    raise ValueError('Not Found')


def get_pancake_liquidity(pair):
    """
    Querries the PancakeSwap factory smartcontract for the specified token's liquidity size.
    This can be used to guess a good amount to loan or trade
    :param pair:
    :return:
    """
    pass


def get_bakery_liquidity(pair):
    pass


def get_abi(address):
    return requests.get('https://api.bscscan.com/api?module=contract&action=getabi'
                        f'&address={address}&apikey=QR4DM459W4XUCSN7WMWGR6RU23YNS81NWC'
                        '').json()['result']
