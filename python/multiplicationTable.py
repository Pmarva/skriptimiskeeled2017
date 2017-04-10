number = input("Sisestage number, korrutstabeli suuruseks")

for x in range(0, int(number)):
	for y in range (0, int(number)):
		print(str(x*y)+'\t',end='')
	print("")
