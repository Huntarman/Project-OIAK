from array import *
from math import ceil, log2
def run(number_1 , number_2):

    num_1_Bits = bitify(number_1)
    num_2_Bits = bitify(number_2)
    
    num_1_Bits.reverse()
    num_2_Bits.reverse()

    max_length = max(len(num_1_Bits), len(num_2_Bits))

    num_1_Bits = num_1_Bits + [False] * (max_length - len(num_1_Bits))
    num_2_Bits = num_2_Bits + [False] * (max_length - len(num_2_Bits))
    #preproccessing stage
    H, P, G = preProcessingStage(num_1_Bits, num_2_Bits)
    print(H)
    #parrarel-prefix stage
    C = parallelPrefixStage(H, P, G, max_length)
    print(C)
    #Sum
    S = SumCopmutationStage(H, C)

    printNum(num_1_Bits)
    printNum(num_2_Bits)
    printNum(S)

def preProcessingStage(number_1_Bit, number_2_Bit):
    
    H = []
    P = []
    G = []

    for bit1, bit2 in zip(number_1_Bit, number_2_Bit):
        H.append(XOR(bit1, bit2))
        P.append( OR(bit1, bit2))
        G.append(AND(bit1, bit2))

    return H, P, G

def parallelPrefixStage(H, P, G, levels):
    logic = []
    for i in range (0, levels):
        tupel = bitify(i)
        tupel = [False] * (levels - len(tupel)) + tupel
        tupel.reverse()
        logic.append(tupel)
    C = []
    Pairs = [[[G[0],P[0]] ]* ceil(log2(levels))]
    for i in range (1, levels):
        pi = False
        gi = False
        for j in range (0, ceil(log2(levels))):
            if logic[i][j]:
                if j == 0:
                    pi = P_i(P[i], P[i-1])
                    gi = G_i(G[i], G[i - 1], P[i])
                    Pairs.insert(i, [[gi,pi]])
                else:
                    k = i
                    while logic[k][j]:
                        k -= 1
                    gi = G_i(Pairs[i][j-1][0], Pairs[k][j-1][0], Pairs[i][j-1][1])
                    pi = P_i(Pairs[i][j-1][1], Pairs[k][j-1][1])
                    Pairs[i].append([gi,pi])
            else:
                if j == 0:
                    pi = P[i]
                    gi = G[i]
                    Pairs.insert(i, [[gi,pi]])
                else:
                    pi = Pairs[i][j-1][1]
                    gi = Pairs[i][j-1][0]
                    Pairs[i].append([gi,pi])
    
    for list in Pairs:
        C.append(list[ceil(log2(levels))-1][0])
    
    return C

def SumCopmutationStage(H,C):
    S = [H[0]]
    for i in range(1,len(H)):
        S.append(XOR(H[i],C[i-1])) 
    if (C[len(C) - 1]):
        S.append(C[len(C) - 1])
    return S

def bitify(number):
    inBits = []
    numberBinary = "{0:b}".format(number)
    for char in numberBinary:
        if char == '1':
            inBits.append(True)
        else: inBits.append(False)
    return inBits

def AND(bit1, bit2):
    return bit1 and bit2

def OR(bit1, bit2):
    return bit1 or bit2

def XOR(bit1, bit2):
    return (bit1 and not bit2) or (not bit1 and bit2)

def P_i (Pi, prev_Pi):
    return AND(Pi, prev_Pi)

def G_i (Gi, prev_Gi, Pi):
    return OR(Gi,AND(prev_Gi,Pi))

def printNum(inBits):
    numString = ""
    for char in reversed(inBits):
        if char:
            numString += '1'
        else: numString += '0'
    print(numString)
    