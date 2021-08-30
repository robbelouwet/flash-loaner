from ctypes import Array

import numpy

from model.bsc_client import BscClient

bsc_client = BscClient.get_instance()

router_address = "0x10ED43C718714eb63d5aA57B78B54704E256024E"
router = bsc_client.get_contract(router_address)

amount_in = 2
path = [bsc_client.to_checksum_address("0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16"), bsc_client.to_checksum_address("0x0eD7e52944161450477ee417DE9Cd3a859b14fD0")]


print(router.functions.getAmountsOut("0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73", amount_in, path).call())