import logging
import os

import uvicorn
from fastapi import FastAPI

from dandelion_python.logger import RemoteHandler

app = FastAPI()


@app.get("/")
async def read_root():
    return {"message": "Hello world!"}


def start_http_server():
    uvicorn.run(app, host="0.0.0.0", port=8000, log_config=None)


def configure_loggers(handler: logging.Handler):
    for logger_name in (
        "uvicorn.error",
        "uvicorn.access",
        "uvicorn.asgi",
        "uvicorn.access",
    ):
        logger = logging.getLogger(logger_name)
        for handler in logger.handlers:
            logger.removeHandler(handler)
        logger.propagate = True
        logger.disabled = False
        logger.setLevel(logging.DEBUG)
        logger.addHandler(handler)



def main():
    with RemoteHandler(host=os.getenv("LOGGING_ENDPOINT", "127.0.0.1"), port=int(os.getenv("LOGGING_PORT", "8080"))) as handler:
        configure_loggers(handler)
        start_http_server()


if __name__ == "__main__":
    main()
