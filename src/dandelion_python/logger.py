import socket
import logging


class RemoteHandler(logging.Handler):
    def __init__(self, host: str, port: int):
        """
        Initializes the remote logger with the server host and port.
        """
        super().__init__(logging.DEBUG)
        self.host = host
        self.port = port
        self.client_socket = None

    def __enter__(self):
        """
        Sets up the context by connecting to the server.
        """
        self.client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.client_socket.connect((self.host, self.port))
        self.client_socket.sendall(b"Connected to logging server\n")
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        """
        Cleans up resources when exiting the context.
        """
        if self.client_socket:
            self.client_socket.close()
            self.client_socket = None
        if exc_type:
            print(f"Logging stopped due to an exception: {exc_value}")

    def emit(self, message: logging.LogRecord):
        """
        Sends a log message to the server.
        """
        if not self.client_socket:
            raise RuntimeError("Logger not initialized. Use it within a 'with' block.")

        log_line = f"{message.levelname}: {message.getMessage()}\n"
        try:
            self.client_socket.sendall(log_line.encode())
        except Exception as e:
            print(f"Error sending log: {e}")
