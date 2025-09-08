"""
Module to run different shell scripts for Metasploit Red Lumin project.
"""
from metasploit import module

def run_script(script_path: str) -> None:
    """
    Execute a shell script located at the given path.

    Args:
        script_path (str): The path to the shell script to be executed.
    """
    import subprocess

    try:
        subprocess.run(["bash", script_path], check=True)
    except subprocess.CalledProcessError as e:
        module.log(f"Error executing script {script_path}: {e}", 'error')

