import numpy as np

def extract_bits(num, start, end):
    length = end - start + 1
    
    if(length <0):
        print("Error length:", length)
        print("Error start :", start )
        print("Error end   :", end   )
        raise("length is negative")
    
    mask = (1 << length) - 1
    
    return (num >> start) & mask

def splice_bits(num1,num0,bit_w1,bit_w0):
    bin_str1 = bin(num1)[2:].zfill(bit_w1)
    bin_str2 = bin(num0)[2:].zfill(bit_w0)

    splice_bin_str = bin_str1 + bin_str2

    result = int(splice_bin_str, 2)

    if(result >= pow(2,bit_w1+bit_w0)): ## assert
        print("Error length bit1:",bit_w1,"bit2",bit_w0,"Error num1:",num1,"Error num0:",num0)
        raise("Error: splice bits is wrong")
    
    return result

def pad_array(arr, target_length):
    current_length = len(arr)
    if current_length >= target_length:
        return arr
    else:
        padding_length = target_length - current_length
        padded_arr = np.pad(arr, (0, padding_length), mode='constant')
        return padded_arr

def barrel_shifter(arr, shift): ## example: input arr=[1,2,3,4,5],shift=4, output [2,3,4,5,1]
    length = len(arr)
    shifted_arr = np.zeros(length, dtype=arr.dtype)

    if shift == 0:
        shifted_arr = arr
    elif shift > 0:
        shifted_arr[shift:] = arr[:-shift]
        shifted_arr[:shift] = arr[-shift:]
    else: ## assert
        raise("Error: shift num can't be negative")

    return shifted_arr

def adder_under_bitlimit(a, b, bit_width):
    result = (a + b) % (2 ** bit_width)
    return result

def generate_gaussian_integer_data(num_samples, min_value, max_value):

    mean = (min_value + max_value) / 2  
    std = max_value / 6 
 
    data = np.random.normal(mean, std, num_samples)
    
    data = np.clip(data, min_value, (max_value-1)) ## generate data from min_val~(max_val-1)
    
    integer_data = np.round(data).astype(int)
    
    return integer_data

def generate_all1_integer_data(size):
    data = np.ones(size,dtype=int)

    return data

def generate_rdm_integer_data(size,max_val,min_val):
    seed = np.random.randint(0, 2**31 - 1)
    np.random.seed(seed)

    data = np.random.randint(low=min_val, high=max_val, size=size)
    
    return seed, data

def generate_best_integer_data(size,max_val,min_val):
    data = np.linspace(min_val, (size-1), size, dtype=int)
    print(data)

    return data

