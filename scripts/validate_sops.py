#!/usr/bin/env python3
import os
import sys
import re
import yaml
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

def load_sops_config(config_path=".sops.yaml"):
    """Load and parse the .sops.yaml configuration file."""
    if not os.path.exists(config_path):
        logging.error(f"Configuration file {config_path} not found.")
        sys.exit(1)

    with open(config_path, 'r') as f:
        try:
            config = yaml.safe_load(f)
        except yaml.YAMLError as e:
            logging.error(f"Error parsing {config_path}: {e}")
            sys.exit(1)

    return config

def get_creation_rules(config):
    """Extract creation rules from the configuration."""
    rules = []
    if not config or 'creation_rules' not in config:
        logging.warning("No creation_rules found in configuration.")
        return rules

    for rule in config['creation_rules']:
        if 'path_regex' in rule:
            try:
                # Compile regex for performance and validation
                pattern = re.compile(rule['path_regex'])
                rules.append({
                    'regex': rule['path_regex'],
                    'pattern': pattern,
                    'matched_files': set()
                })
            except re.error as e:
                logging.error(f"Invalid regex '{rule['path_regex']}': {e}")
                sys.exit(1)
    return rules

def find_files(root_dir="."):
    """Recursively find all files in the repository, excluding ignored directories."""
    files = []
    # Directories to ignore
    ignore_dirs = {'.git', '.venv', 'venv', '__pycache__', 'node_modules', 'result'}

    for root, dirs, filenames in os.walk(root_dir):
        # Modify dirs in-place to skip ignored directories
        dirs[:] = [d for d in dirs if d not in ignore_dirs]

        for filename in filenames:
            filepath = os.path.relpath(os.path.join(root, filename), root_dir)
            files.append(filepath)

    return files

def validate_rules(rules, files):
    """Validate that rules match files and sensitive files are covered."""
    # Pattern for files that SHOULD be encrypted
    # Adjust this based on project conventions. typically *.sops.yaml, *.enc.yaml
    sensitive_pattern = re.compile(r'.*\.sops\.yaml$')

    errors = 0

    # Check coverage: Every sensitive file must match at least one rule
    for filepath in files:
        if filepath == '.sops.yaml':
            continue

        if sensitive_pattern.search(filepath):
            covered = False
            for rule in rules:
                if rule['pattern'].search(filepath):
                    covered = True
                    rule['matched_files'].add(filepath)

            if not covered:
                logging.error(f"File '{filepath}' is a SOPS file but matches no creation rules.")
                errors += 1
        else:
            # Also check non-sensitive files to update matched_files for usage check
            for rule in rules:
                if rule['pattern'].search(filepath):
                    rule['matched_files'].add(filepath)

    # Check usage: Every rule must match at least one file
    for rule in rules:
        if not rule['matched_files']:
            logging.error(f"Creation rule regex '{rule['regex']}' does not match any files in the repository.")
            errors += 1

    return errors == 0

def main():
    config = load_sops_config()
    rules = get_creation_rules(config)
    files = find_files()

    if validate_rules(rules, files):
        logging.info("SOPS configuration validation passed.")
        sys.exit(0)
    else:
        logging.error("SOPS configuration validation failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()
