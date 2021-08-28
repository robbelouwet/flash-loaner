import json
from decimal import Decimal
from bot.price_client import get_pair_prices, calculate_loan_amount
from utils import globals
from utils.web3_utils import get_pool_by_pair, get_pair_by_pool

all_pairs = globals.network_data()['pairs']['PancakeSwap_BakerySwap']


def find_arbitrage():
    """"
    For every tradable pair listed in pancake_bakery_pairs.json,
    it checks whether an arbitrage opportunity is present at PancakeSwap <=> BakerySwap
    """
    global all_pairs
    profits = []
    for pair in all_pairs:
        pool = get_pool_by_pair(pair, "PancakeSwap")
        loan_amount = calculate_loan_amount("PancakeSwap", get_pair_by_pool("PancakeSwap", pool), pair[0])
        result = find_trade_opportunities(pair, loan_amount)
        absolute_profit = calculate_absolute_token_profit(result)
        profits.append({
            'opportunity': result,
            'loan_amount': loan_amount,
            'absolute_profit': absolute_profit,
            'profit_unity': pair[0]
        })

    return profits


def find_trade_opportunities(pair, amount_token_0):
    """
    Calculates the price discrepancy between token pairs on different DEX's for a given token pair
    :param amount_token_0:
    :type pair: Array [token0, token1]
    :return:
    """
    # print(f'Opportunities for flash loaning {f"{amount_token_0:,}"} {pair[0]}:')

    results = get_pair_prices(pair[0], pair[1], amount_token_0)
    list.sort(results, key=lambda i: Decimal(i['unit_price']))

    cheapest = results[0]
    most_expensive = results[len(results) - 1]

    return [cheapest, most_expensive]


def calculate_absolute_token_profit(op):
    """
    Given 2 trade opportunities with different unit prices, this method calculates the absolute amount
    of profit, by using the recommended amount to trade

    :param op:
    :return: amount of absolute profit, in the loaned token
    """
    # print(json.dumps(op, indent=4, default=str))

    # both best-price trade opportunities don't trade the same amount, so look for the
    # lowest amount that both dex's can liquidate
    amount_0 = Decimal(op[0]['taker_amount_rebased'])
    amount_1 = Decimal(op[1]['taker_amount_rebased'])

    if amount_0 < amount_1:
        amount_to_trade = amount_0
    else:
        amount_to_trade = amount_1

    # find out where to buy low and where to sell high
    price_0 = Decimal(op[0]['unit_price'])
    price_1 = Decimal(op[1]['unit_price'])

    if price_0 < price_1:
        buy_here = op[0]
        sell_here = op[1]
    else:
        buy_here = op[1]
        sell_here = op[0]

    buy_price = Decimal(buy_here['unit_price'])
    sell_price = Decimal(sell_here['unit_price'])
    return ((amount_to_trade * sell_price) / buy_price) - amount_to_trade


def iterate():
    profits = find_arbitrage()

    for profit in profits:
        # print(json.dumps(profit, indent=4, default=str))
        print(f"amount: {profit['loan_amount']} {profit['opportunity'][0]['taker_token']}; "
              f"{profit['opportunity'][0]['taker_token']} <-> {profit['opportunity'][0]['maker_token']}; "
              f"profit: {profit['absolute_profit']} {profit['profit_unity']}")


if __name__ == "__main__":
    iterate()
