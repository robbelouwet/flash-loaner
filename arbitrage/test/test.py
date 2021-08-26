import json

io = open('../resources/pancakeswap.json', 'w')
pairs = json.loads(str_pairs)

new = []
for pair in pairs:
    splitted = pair.split('/')
    new.append([splitted[0], splitted[1]])

io.write(str(new).replace('\'', '\"'))

##file = open('bakeryswap.json', 'w')
#file.write(str(tokens).replace("\'", "\""))



