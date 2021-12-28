dic = {}

for i in range(0,26):
    dic[chr(ord('A')+i)] = 0x60 + i
    dic[chr(ord('a')+i)] = 0x81 + i
    
entry = "phase"

for c in entry:
    print("82 " + hex(dic[c])[2:] + " ", end = '')