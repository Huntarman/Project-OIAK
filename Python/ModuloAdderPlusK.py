import LadnerFischer as og
from array import *
from math import ceil, log2

def run(number_1, number_2, k):
    
    num_1_Bits = og.bitify(number_1)
    num_2_Bits = og.bitify(number_2)
    

    num_1_Bits.reverse()
    num_2_Bits.reverse()
   
    max_length = max(len(num_1_Bits), len(num_2_Bits))
    og_Length = max_length
    

    k_Bits = og.bitify(2**(max_length+1) -k)
    k_Bits.reverse()

    num_1_Bits = num_1_Bits + [False] * (max_length - len(num_1_Bits) + 1)
    num_2_Bits = num_2_Bits + [False] * (max_length - len(num_2_Bits) + 1)
    k_Bits = k_Bits + [False] * (max_length - len(k_Bits) + 1)
    k_Bits[max_length] = False
    num_1_prim_Bits, num_2_prim_Bits = numsPrim(num_1_Bits, num_2_Bits, k_Bits)

    #preproccessing stage
    H, P, G = og.preProcessingStage(num_1_Bits, num_2_Bits)
    H_prim, P_prim, G_prim = og.preProcessingStage(num_1_prim_Bits, num_2_prim_Bits)
    
    #parrarelprefix stage
    C = og.parallelPrefixStage(H,P,G, max_length)
    C_prim = og.parallelPrefixStage(H_prim, P_prim, G_prim, max_length)
    C_out = og.OR(C_prim[og_Length-1],C_prim[og_Length-1])

    if False:
        print("NUM1")
        print(num_1_Bits)
        print("NUM2")
        print(num_2_Bits)
        print("MOD")
        print(k_Bits)
        print("NUM1Prim")
        print(num_1_prim_Bits)
        print("NUM2Prim")
        print(num_2_prim_Bits)
        print("GPrim")
        print(G_prim)
        print("PPrim")
        print(P_prim)
        print("HPrim")
        print(H_prim)
        print("H")
        print(H)
        print("cout")
        print(C_out)
    
    #sumcompstage
    S = SumCopmutationStage(H, C, H_prim, C_prim, C_out)

    if True:
        print("Liczba 1:")
        og.printNum(num_1_Bits)
        print("Liczba 2:")
        og.printNum(num_2_Bits)
        print("Wynik")
        og.printNum(S)
    


def numsPrim(number_1_Bit, number_2_Bit, modulo_bits):
    num1Prim = []
    num2Prim = [False]
    for i in range(0,len(number_1_Bit)):
        if modulo_bits[i]:
            num1Prim.append(not og.XOR(number_1_Bit[i], number_2_Bit[i]))
            num2Prim.append(og.OR(number_1_Bit[i], number_2_Bit[i]))
        else:  
            num1Prim.append(og.XOR(number_1_Bit[i],number_2_Bit[i]))
            num2Prim.append(og.AND(number_1_Bit[i],number_2_Bit[i]))
    num2Prim.pop()
    return num1Prim, num2Prim
    
def SumCopmutationStage(H, C,H_prim, C_prim, C_out):
    S = []
    if not C_out:
        S.append(H[0])
    else:
        S.append(H_prim[0])

    for i in range(1, len(H)):
        if not C_out:
            S.append(og.XOR(H[i],C[i-1])) 
        else:
            S.append(og.XOR(H_prim[i], C_prim[i-1]))

    return S
   
run(127, 127, 120)