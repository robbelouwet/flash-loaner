from utils.web3_utils import get_web3, get_abi, get_symbol_by_address

web3 = get_web3()

router_address = "0x10ED43C718714eb63d5aA57B78B54704E256024E"
router_abi = get_abi(router_address)
router = web3.eth.contract(address=router_address, abi=router_abi)

factory_address = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73"
factory_abi = get_abi(factory_address)
factory = web3.eth.contract(address=factory_address, abi=factory_abi)

pair_address = "0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16"
pair_abi = get_abi(pair_address)
pair = web3.eth.contract(address=pair_address, abi=pair_abi)

result = pair.functions.getReserves().call()
token0 = get_symbol_by_address(pair.functions.token0().call())
token1 = get_symbol_by_address(pair.functions.token1().call())

print(result)
amount_out = router.functions.getAmountOut(200, result[0], result[1]).call()

print(amount_out)
print(token0)
print(token1)

