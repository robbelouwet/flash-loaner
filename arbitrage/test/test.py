import json

io = open('../resources/pancake_bakery_pairs.json')
pairs = json.loads(io.read())
print(pairs['pairs'])


# list all tokens that exist in at least 1 pair
tokens = []
pairs = pairs['pairs']
for i in range(len(pairs)):
    for j in range(len(pairs[i])):
        token = pairs[i][j]
        if token not in tokens:
            tokens.append(token)

# for every token, list its info
io2 = open('../resources/pancake_tokens.json')
dict = json.loads(io2.read())['data']
tokeninfo = {}
for key in dict.keys():
    token = dict[key]['symbol']
    tokeninfo[token] = {
        'contract': key,
    }

io3 = open('../resources/tokeninfo.json', 'w')
io3.write(json.dumps(tokeninfo, indent=4))
