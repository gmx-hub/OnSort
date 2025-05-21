import numpy as np
import math

# define a class for constant
class _const(object):
    class ConstError(PermissionError): pass

    def __setattr__(self, name, value):
        if name in self.__dict__.keys():
            raise self.ConstError( "Can't rebind const(%s)" % name)
        self.__dict__[name] = value

    def __delattr__(self, name):
        if name in self.__dict__:
            raise self.ConstError("Can't unbind const(%s)" % name)
        raise NameError(name)


# define the constant used in our simulator

const = _const()

const.test_hardware_type = 'HT' 

const.SORT_FUC_MAX_NUM         = 8192 #65536 #1024 #8192 #16384
const.SORT_PERF_OUT_PARALLEL   = 2
const.SORT_FUC_BK_NUM          = 16
const.SORT_PERF_PREFETCH_DEPTH = 16


if (const.test_hardware_type == 'HT') :
    const.SORT_FUC_PREFETCH_EN     = 1
    const.SORT_PERF_SBU_TILE_NUM   = 256

elif(const.test_hardware_type == 'FG'):
    const.SORT_FUC_PREFETCH_EN     = 1
    const.SORT_PERF_SBU_TILE_NUM   = const.SORT_FUC_MAX_NUM

elif(const.test_hardware_type == 'BASE'):
    const.SORT_FUC_PREFETCH_EN     = 0
    const.SORT_PERF_SBU_TILE_NUM   = const.SORT_FUC_MAX_NUM

else:
    raise("Error Setting")

const.SORT_FUC_ZERO_NUM        = 0
const.SORT_FUC_REPEAT_NUM      = const.SORT_FUC_MAX_NUM*2
const.SORT_FUC_DATA_BANDWIDTH = int(math.log2(const.SORT_FUC_MAX_NUM))

const.SORT_FUC_CNT_MEM_DEPTH  = int((const.SORT_FUC_MAX_NUM) / const.SORT_FUC_BK_NUM)
const.SORT_FUC_CNT_MEM_DEPTH_WIDTH = int(math.log2(const.SORT_FUC_CNT_MEM_DEPTH))
const.SORT_FUC_CNT_MEM_WIDTH  = int(math.log2(const.SORT_FUC_REPEAT_NUM))

const.SORT_FUC_BK_DEPTH_WIDTH = int(math.log2(const.SORT_FUC_BK_NUM))
 
const.SORT_FUC_PREFETCH_DEPTH_WIDTH = int(math.log2(const.SORT_PERF_PREFETCH_DEPTH))
const.SORT_FUC_PREFETCH_CNT_WIDTH   = const.SORT_FUC_PREFETCH_DEPTH_WIDTH + 1

const.SORT_FUC_SBU_TILE_WIDTH       = int(math.log2(const.SORT_PERF_SBU_TILE_NUM))
const.SORT_FUC_SBU_TILE_CNT_MAX_NUM = int(const.SORT_PERF_SBU_TILE_NUM/const.SORT_FUC_BK_NUM)
const.SORT_FUC_SBU_TILE_CNT_DEPTH   = int(math.log2(const.SORT_FUC_SBU_TILE_CNT_MAX_NUM))

const.SORT_PERF_SBU_NUM        = int((const.SORT_FUC_MAX_NUM) / (const.SORT_PERF_SBU_TILE_NUM))
const.SORT_FUC_SBU_DEPTH_WIDTH = int(math.log2(const.SORT_PERF_SBU_NUM))




