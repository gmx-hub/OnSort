import numpy as np

## reg class simulate the behavior of register in hardware

class reg:
    def __init__(self, init_val):
        self.reg = init_val
        self.init_val = init_val

    def get_reg_q(self):
        if(isinstance(self.reg,(int,float,str))):
            return self.reg
        else:
            return self.reg.copy()
    
    def set_reg_d_with_en(self, en, val):
        if (en == 1) :
            self.reg = val

        if(en !=0 | en !=1):
            print("Error_type is ",type(en))
            raise("Error: en of reg_set is wrong")
    
    def set_vecreg_d_with_vecen(self,en,val):
        length = len(en)
        for i in range(length):
            if(en[i]):
                self.reg[i] = val[i]
    
    def set_reg_d(self, val):
        self.reg = val









