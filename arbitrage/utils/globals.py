import json
import logging

logger = None
io3 = open('../resources/data.json')
data = json.loads(io3.read())


def network_data():
    return data


def get_logger():
    """
    log levels:
    NOTSET - 0
    DEBUG - 10
    INFO - 20
    WARNING - 30
    ERROR - 40
    CRITICAL - 50

    :return:
    """
    global logger

    if logger is None:
        logger = logging
        logger.getLogger().setLevel(20)

    return logger
