# Security Policy

## Supported Versions

We maintain security updates for the following versions of the GitHub Action:

| Version | Supported          | End of Support |
| ------- | ------------------ | -------------- |
| 1.x     | :white_check_mark: | Active         |
| < 1.0   | :x:                | Deprecated     |

Please update to the latest version to ensure you receive security patches and improvements. We recommend pinning to a specific major version in your workflows (e.g., `uses: FrancisGopurathingal/ghactions-repo-metrics@v1`).

## Security Considerations

### Action Permissions

This action requires read access to your repository contents to analyze code metrics:
- It uses `cloc` to count lines of code across your repository
- The analysis results are stored in a JSON file specified by the `output-dir` input
- No sensitive data is transmitted outside your workflow environment

### Recommendations

1. **Pin to Specific Versions**: Always pin this action to a specific release version or major version tag in your workflows, not `@main`
   ```yaml
   - uses: FrancisGopurathingal/ghactions-repo-metrics@v1
   ```

2. **Review Outputs**: Verify that the generated JSON report doesn't expose sensitive information in your repository

3. **Secure Artifact Storage**: If storing the generated reports, ensure proper access controls are in place

4. **Keep Dependencies Updated**: Ensure the `cloc` tool and system dependencies are kept up-to-date in the action's container

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue in this GitHub Action, please report it responsibly.

### How to Report

**Please do not open public GitHub issues for security vulnerabilities.** Instead:

1. Email your report to the repository maintainer with details including:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact
   - Suggested fix (if available)

2. Allow up to 7 days for an initial response
3. Work with us to develop and verify a fix before public disclosure

### What to Expect

- Acknowledgment of your report within 7 days
- Regular updates on the progress toward a fix
- Credit for the discovery (unless you prefer to remain anonymous)
- A security advisory and patch release when available

### Out of Scope

Security concerns not related to this action (such as vulnerabilities in `cloc` or other third-party tools) should be reported directly to the respective project maintainers.
