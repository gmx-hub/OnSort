import numpy as np

## reg class simulate the behavior of register in hardware

class memory:
    def __init__(self, depth, bank_num, width):

        ## parameter of mem
        self.depth = depth
        self.bank_num = bank_num
        self.width = width

        self.mem = np.zeros((self.depth,self.bank_num),dtype=int)

    def wr_mem(self, vld, addr, data):
        for i in range(self.bank_num):
            if(vld[i] == 1):
                self.mem[addr][i] = data[i]
    
    def rd_mem(self,vld, addr):
        rd_data = np.zeros(self.bank_num,dtype=int)
        for i in range(self.bank_num):
            if(vld[i] == 1):
                rd_data[i] = self.mem[addr][i]

        return rd_data
    









