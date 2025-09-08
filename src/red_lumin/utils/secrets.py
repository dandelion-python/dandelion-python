"""
Module for handling secrets in the Metasploit Red Lumin project.
"""
import os
import subprocess
import json

def get_secrets_from_image(image_name: str) -> list[dict]:
    """
    Extract secrets from a given Docker image.

    Args:
        image_name (str): The name of the Docker image.

    Returns:
        dict: A dictionary containing extracted secrets.
    """
    cli_scanner = "trufflehog"
    results = []
    try:
        result = subprocess.run(
            [cli_scanner, "docker", "--image", image_name, "-j", "--results", "verified"],
            capture_output=True,
            text=True,
            check=True
        )
        secrets_lines = result.stdout
        lines = secrets_lines.splitlines()
        for i, line in enumerate(lines):
            try:
                secret = json.loads(line)
                results.append(secret)
            except json.JSONDecodeError as e:
                print(f"Error decoding JSON on line {i}: {e}")
                continue
        return results
    except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
        print(f"Error extracting secrets: {e}")
        return []

def check_secrets_permissions(secrets: list[dict]) -> dict:
    """
    Check permissions of the extracted secrets.

    Args:
        secrets (list[dict]): A list of dictionaries containing extracted secrets.

    Returns:
        dict: A dictionary with permission status for each secret.
    """
    # TODO: Implement actual permission checking logic
    permissions = {}
    print("Checking permissions for extracted secrets...")
    return permissions

def inject_secrets_into_env(secrets: list[dict], **kwargs) -> None:
    """
    Inject extracted secrets into environment variables.

    Args:
        secrets (list[dict]): A list of dictionaries containing extracted secrets.
    """
    for secret in secrets:
        secret_type = secret.get("DetectorName")
        value = secret.get("Raw")
        if secret_type == "Github":
            os.environ["GITHUB_LEAKED_TOKEN"] = value
            print(f"Injected secret {secret_type} into environment variables.")
    for key, val in kwargs.items():
        os.environ[key] = val
        print(f"Injected custom secret {key} into environment variables.")

