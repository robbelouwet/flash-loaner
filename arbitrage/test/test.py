import json

io = open('../resources/all_pairs.json')
pairs = json.loads(io.read())
print(pairs['pairs'])

tokens = []
pairs = pairs['pairs']
for i in range(len(pairs)):
    for j in range(len(pairs[i])):
        token = pairs[i][j]
        if token not in tokens:
            tokens.append(token)

io2 = open('../resources/pancake_tokens.json')
dict = json.loads(io2.read())['data']
tokeninfo = {}

for token in tokens:
    for key in dict.keys():
        if dict[key]['symbol'] == token:
            tokeninfo[token] = {
                'contract': key,
            }

io3 = open('../resources/tokeninfo.json', 'w')
io3.write(json.dumps(tokeninfo, indent=4))