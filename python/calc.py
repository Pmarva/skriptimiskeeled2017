
import math
tehe=input("valige tehe mida soovite teha 1.Liitmine 2.lahutamine 3.korrutamine 4.jagamine 5.ruutjuur 6.aste:")

operator = ""
tehe=int(tehe)

if tehe < 5:
    num1=input("Sisestage esimene number:")
    num2=input("sisestage teine number:")

    if tehe == 1:
        vastus = int(num1)+int(num2)
        operator = "+"

    if tehe == 2:
        vastus = int(num1)-int(num2)
        operator = "-"
    
    if tehe == 3:
        vastus = int(num1)*int(num2)
        operator = "*"

    if tehe == 4:
        vastus = int(num1)/int(num2)
        operator = "/"
    print(num1+operator+num2+"="+str(vastus))

if tehe == 5:
    num1=input("Sisestage number:")
    print("Ruutjuur "+num1+" on "+str(math.sqrt(int(num1))))

if tehe == 6:
    num1=input("Sisestage astme alus:")
    num2=input("Sisestage astendaja")
    print(num1+" astmes "+ num2 +" on "+str(math.pow(int(num1),int(num2))))
    
    





