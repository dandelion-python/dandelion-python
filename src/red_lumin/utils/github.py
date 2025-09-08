"""
Module to handle GitHub API interactions in the Metasploit Red Lumin project.
"""

import requests

from metasploit import module


GITHUB_API_URL = "https://api.github.com"

COMMON_HEADERS = {
    "Accept": "application/vnd.github.v3+json"
}

def check_token_permissions(token: str) -> dict:
    """
    Check the permissions of a given GitHub token.

    Args:
        token (str): The GitHub token to be checked.

    Returns:
        dict: A dictionary containing the permissions of the token.
    """
    headers = COMMON_HEADERS.copy()
    headers["Authorization"] = f"Bearer {token}"
    try:
        response = requests.get(GITHUB_API_URL, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        module.log(f"Error checking token permissions: {e}", 'error')
        return {}


def remove_branch_protection(org: str, repo: str, branch: str, token: str) -> None:
    """
    Remove branch protection from a specified branch in a GitHub repository.
    """
    headers = COMMON_HEADERS.copy()
    headers["Authorization"] = f"Bearer {token}"
    try:
        response = requests.delete(f"{GITHUB_API_URL}/repos/{org}/{repo}/branches/{branch}/protection", headers=headers)
        response.raise_for_status()
        module.log(f"Successfully removed branch protection from {branch} in {org}/{repo}", 'info')
    except requests.RequestException as e:
        module.log(f"Error removing branch protection: {e}", 'error')

