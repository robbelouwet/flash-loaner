from pandas import DataFrame


def write_results_to_csv(results, block_number):
    data = []

    res_keys = results.keys()

    for key in res_keys:
        res = results[key]
        buy_op = res['buy_opportunity']
        sell_op = res['sell_opportunity']

        data.append([f"{buy_op[2]}_{sell_op[2]}", *buy_op, "\=\>", *sell_op, res['profit_amount'], res['profit_token']])

    df = DataFrame(data, columns=(
        'PAIR', 'DEX', 'AMOUNT TOKEN 0', 'TOKEN 0', 'AMOUNT TOKEN 2', 'TOKEN 1', 'PPU', '% RESERVE 1', '% RESERVE 1',
        '',
        'DEX', 'AMOUNT TOKEN 0', 'TOKEN 0', 'AMOUNT TOKEN 2', 'TOKEN 1', 'PPU', '% RESERVE 1', '% RESERVE 1',
        'PROFIT AMOUNT', 'PROFIT TOKEN'))

    df.to_csv(path_or_buf=f'./resources/{block_number}.csv')
