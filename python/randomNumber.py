from random import randint

number = randint(0,500)



while True:
	userChoise = int(input("Sisesta arvatav number"))

	if userChoise > number:
		print("Pakkusite liiga suure numbri, proovige väiksemat")

	if userChoise < number:
		print("Pakkusite liiga väikse numbri, proovige suuremat")

	if number == userChoise:
		print("Palju õnne saite pihta")
		break
