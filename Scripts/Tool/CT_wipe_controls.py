# num_inps = [inp for inp in tool.GetInputList().values() if inp.ID.startswith('Show')]

print('removing numbers')
for n in range(4,9):
    tool['ShowNumber{}'.format(n)] = False

print('removing points')
for n in range(2,5):
    tool['ShowPoint{}'.format(n)] = False

print('removing LUTs')
for n in range(1,5):
    tool['ShowLUT{}'.format(n)] = False

print('done')
