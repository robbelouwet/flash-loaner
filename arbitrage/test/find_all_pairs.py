import json

bakery_io = open('../resources/bakeryswap.json', 'r')
bakery_pairs = json.loads(bakery_io.read())

pancake_io = open('../resources/pancakeswap.json', 'r')
pancakes = json.loads(pancake_io.read())

pancake_io = open('../resources/pancake_tokens.json', 'r')
pancakes2 = json.loads(pancake_io.read())

pairs = []
for bakery in bakery_pairs:
    for pancake in pancakes:
        if pancake[0] == pancake[1]:
            continue
        if pancake[0] == bakery[0] and pancake[1] == bakery[1] and pancake not in pairs:
            pairs.append(pancake)
        elif pancake[1] == bakery[0] and pancake[0] == bakery[1] and pancake not in pairs:
            pairs.append(pancake)

print(pairs)
io1 = open('../resources/pancake_bakery_pairs.json', 'w')
#io1.write(str(pairs).replace('\'', '\"'))
print(len(pairs))
print(len(pancakes))
print(len(pancakes2['data'].keys()))

