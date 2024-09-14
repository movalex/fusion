import logging
import sys

from pathlib import Path


def create_logging_handler(stream, level, formatter, filter=None):
    """
    Create and configure a logging handler.

    :param stream: The stream the handler will write to.
    :param level: The minimum logging level of messages the handler will handle.
    :param formatter: The formatter to use for log messages.
    :param filter: An optional function to filter log messages.
    :return: Configured logging.Handler object.
    """
    handler = logging.StreamHandler(stream=stream)
    handler.setLevel(level)
    handler.setFormatter(formatter)
    if filter:
        handler.addFilter(filter)
    return handler


def set_logging(level="debug", script_name=None):
    if script_name is None:
        script_name = Path(__file__).stem

    log_levels = {
        "debug": logging.DEBUG,
        "info": logging.INFO,
        "warning": logging.WARNING,
        "error": logging.ERROR,
        "critical": logging.CRITICAL,
    }

    # Validate the level argument
    if level.lower() not in log_levels:
        raise ValueError(f"Invalid logging level: {level}")

    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)  # Set the logger to the lowest level

    # Common formatter for both handlers
    formatter = logging.Formatter(
        f"%(levelname)s | [{script_name}] | %(message)s"
    )

    # Handler for stdout, with a filter for messages below WARNING level
    stdout_handler = create_logging_handler(
        stream=sys.stdout,
        level=logging.DEBUG,
        formatter=formatter,
        filter=lambda record: record.levelno < logging.WARNING,
    )

    # Handler for stderr, for WARNING level and above
    stderr_handler = create_logging_handler(
        stream=sys.stderr,
        level=logging.WARNING,
        formatter=formatter,
    )

    # Reset the logger's handlers before adding new ones
    logger.handlers.clear()  # Clear any existing handlers
    logger.handlers = [stdout_handler, stderr_handler]

    log_level = log_levels.get(level.lower(), logging.INFO)
    logger.setLevel(log_level)

    return logger