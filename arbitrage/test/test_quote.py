from model.bsc_client import BscClient

bsc_client = BscClient.get_instance()

reserve0 = 570594238294365410426617
reserve1 = 265444884490041698388018752

symbol0 = "BUSD"
symbol1 = "WBNB"

amount_in = int(48000*10e18)

router = bsc_client.get_contract("0x10ED43C718714eb63d5aA57B78B54704E256024E", cast_abi="PancakeRouter", cast=True)

amount_out = router.functions.getAmountOut(amount_in, reserve1, reserve0).call()
rate = amount_in / amount_out
print(f'{amount_in/10e18} {symbol0} -> {amount_out/10e18} {symbol1} at {rate} {symbol0}/{symbol1}')
