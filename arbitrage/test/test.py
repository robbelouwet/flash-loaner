from model.data_client import DataClient

tokens = DataClient.get_instance().get_tokens()
addresses = tokens.keys()

for adr1 in addresses:
    for adr2 in addresses:
        if adr1 == adr2:
            print(f'Found duplicate: {tokens[adr1]}')


