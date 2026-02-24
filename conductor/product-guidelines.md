# Product Guidelines

## Documentation Style

- **Technical Precision**: Use clear, concise language for technical procedures and configuration options.
- **Markdown Standards**: Use standard GitHub Flavored Markdown. Ensure all code blocks have appropriate language tags (e.g., `yaml`, `nix`, `bash`).
- **Consistency**: Maintain a consistent voice across all documentation—professional, direct, and task-oriented.

## Configuration Principles

- **Explicit over Implicit**: Favor explicit configuration values over defaults to ensure predictability.
- **Declarative Patterns**: All infrastructure changes must be defined in code. Avoid manual, one-off changes ("click-ops" or manual CLI commands for state changes).
- **Modularity**: Organize manifests and Nix code into logical, reusable components to reduce duplication.

## Security & Privacy

- **Secret Sovereignty**: Never commit plaintext secrets. All sensitive data must be encrypted with SOPS and age.
- **Least Privilege**: Apply the principle of least privilege to all service accounts and resource permissions.
- **Privacy First**: Ensure that any logs or telemetry gathered do not expose personally identifiable information (PII).

## Workflow & Quality

- **Validation First**: Every manifest must be validated before it is considered ready for deployment.
- **Atomic Changes**: Commit small, logical units of work that are easy to review and revert if necessary.
- **Review-Driven**: All major configuration changes should be reviewed for adherence to these guidelines.
