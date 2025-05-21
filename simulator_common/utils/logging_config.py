import logging


def logging_config(log_name):

    #handler = logging.StreamHandler()
    handler = logging.FileHandler('log.txt')
    #fmt = '%(asctime)s - %(filename)s:%(lineno)s - %(name)s - %(message)s'
    fmt = '%(filename)s:%(lineno)s - %(name)s - %(message)s'

    formatter = logging.Formatter(fmt)  
    handler.setFormatter(formatter)  

    logger = logging.getLogger(log_name) 
    logger.addHandler(handler) 
    logger.setLevel(logging.DEBUG)
    return logger