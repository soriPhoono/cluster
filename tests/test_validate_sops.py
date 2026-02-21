import os
import sys
import pytest
import re
from unittest.mock import MagicMock, patch

# Ensure the scripts directory is in the path
sys.path.append(os.path.join(os.path.dirname(__file__), '../scripts'))

import validate_sops

@pytest.fixture
def mock_files(tmp_path):
    """Create a temporary directory with dummy files."""
    (tmp_path / "foo.sops.yaml").touch()
    (tmp_path / "bar.txt").touch()
    return tmp_path

def test_get_creation_rules_valid():
    config = {
        'creation_rules': [
            {'path_regex': 'foo\\.sops\\.yaml'},
            {'path_regex': '.*\\.enc\\.yaml'}
        ]
    }
    rules = validate_sops.get_creation_rules(config)
    assert len(rules) == 2
    assert rules[0]['regex'] == 'foo\\.sops\\.yaml'
    assert rules[1]['regex'] == '.*\\.enc\\.yaml'

def test_validate_rules_valid():
    rules = [
        {'regex': 'foo\\.sops\\.yaml', 'pattern': re.compile('foo\\.sops\\.yaml'), 'matched_files': set()},
    ]
    files = ['foo.sops.yaml', 'bar.txt']

    # Should pass: foo.sops.yaml covered, rule used.
    assert validate_sops.validate_rules(rules, files) is True
    assert 'foo.sops.yaml' in rules[0]['matched_files']

def test_validate_rules_missing_coverage():
    rules = [
        {'regex': 'other\\.sops\\.yaml', 'pattern': re.compile('other\\.sops\\.yaml'), 'matched_files': set()},
    ]
    files = ['foo.sops.yaml', 'other.sops.yaml']

    # Should fail: foo.sops.yaml not covered.
    # other.sops.yaml matches rule, so usage is fine.
    # But coverage fails.
    assert validate_sops.validate_rules(rules, files) is False

def test_validate_rules_unused_rule():
    rules = [
        {'regex': 'foo\\.sops\\.yaml', 'pattern': re.compile('foo\\.sops\\.yaml'), 'matched_files': set()},
        {'regex': 'unused\\.sops\\.yaml', 'pattern': re.compile('unused\\.sops\\.yaml'), 'matched_files': set()},
    ]
    files = ['foo.sops.yaml']

    # Should fail: unused.sops.yaml rule matches nothing.
    assert validate_sops.validate_rules(rules, files) is False

def test_validate_rules_ignore_sops_config():
    rules = []
    files = ['.sops.yaml']

    # Should pass: .sops.yaml is ignored for coverage check.
    # And since no rules exist, usage check is vacuously true.
    assert validate_sops.validate_rules(rules, files) is True

def test_validate_rules_usage_by_non_sensitive():
    rules = [
        {'regex': '.*\\.txt', 'pattern': re.compile('.*\\.txt'), 'matched_files': set()},
    ]
    files = ['bar.txt']

    # Should pass: rule matches bar.txt, so it is used.
    # bar.txt is not sensitive, so coverage not required (but matched anyway).
    assert validate_sops.validate_rules(rules, files) is True

def test_find_files_excludes(tmp_path):
    (tmp_path / ".git").mkdir()
    (tmp_path / ".git" / "HEAD").touch()
    (tmp_path / "node_modules").mkdir()
    (tmp_path / "node_modules" / "foo.js").touch()
    (tmp_path / "file.txt").touch()

    cwd = os.getcwd()
    os.chdir(tmp_path)
    try:
        files = validate_sops.find_files(".")
        assert "file.txt" in files
        assert ".git/HEAD" not in files
        assert "node_modules/foo.js" not in files
    finally:
        os.chdir(cwd)
