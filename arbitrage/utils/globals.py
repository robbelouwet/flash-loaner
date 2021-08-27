import json
import logging

logger = None


def network_data():
    io3 = open('../resources/data.json')
    return json.loads(io3.read())


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
