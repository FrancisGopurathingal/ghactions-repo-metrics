# GitHub Action: Repository Metrics

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-blue?logo=github)](https://github.com/features/actions)

A GitHub Action that analyzes your repository to generate detailed code metrics using `cloc` (Count Lines of Code). This action counts lines of code by language and file type, generating a comprehensive JSON report for tracking code growth and repository statistics.

## Overview

This action leverages [cloc](https://github.com/AlDanial/cloc) to perform static analysis on your repository, producing detailed metrics including:

- Total lines of code by language
- Number of files by type
- Blank lines and comments count
- Code organization insights

Perfect for tracking repository growth, monitoring code contributions, and maintaining code metrics over time.

## Features

- ✅ Accurate code counting across all languages supported by `cloc`
- ✅ Automatic `cloc` installation (optional)
- ✅ Analyze any branch (default: `main`)
- ✅ JSON report format for easy integration
- ✅ Git-aware analysis (excludes `.git` directory)
- ✅ Timestamped reports for historical tracking
- ✅ Zero dependencies - uses standard GitHub Actions environment

## Usage

### Basic Example

```yaml
name: Generate Repo Metrics

on:
  push:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday at midnight UTC

jobs:
  metrics:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Generate Repository Metrics
        uses: FrancisGopurathingal/ghactions-repo-metrics@v1
        with:
          branch: main
          output-dir: ./reports
```

### Advanced Example with Report Storage

```yaml
- name: Generate Repository Metrics
  uses: FrancisGopurathingal/ghactions-repo-metrics@v1
  with:
    branch: ${{ github.ref_name }}
    output-dir: ./nol-reports
    install-cloc: true

- name: Upload metrics report
  uses: actions/upload-artifact@v3
  with:
    name: metrics-reports
    path: nol-reports/
    retention-days: 30
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `branch` | Branch name to analyze | No | `main` |
| `output-dir` | Directory where JSON report will be generated | No | `nol-reports` |
| `install-cloc` | Automatically install `cloc` if not available | No | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `report-file` | Path to the generated JSON report file |

## Report Format

The generated JSON report includes:

```json
{
  "report_type": "number_of_lines",
  "repository": "owner/repo-name",
  "repository_name": "repo-name",
  "owner": "owner",
  "branch": "main",
  "commit_sha": "abc123...",
  "generated_at_utc": "2024-06-14T10:30:45Z",
  "tool": {
    "name": "cloc",
    "version": "cloc version"
  },
  "summary": {
    "total_files": 42,
    "total_lines": 10234,
    "blank_lines": 2100,
    "comment_lines": 1500,
    "code_lines": 6634
  },
  "by_language": {
    "Python": { "files": 12, "blank": 450, "comment": 300, "code": 2500 },
    "JavaScript": { "files": 18, "blank": 800, "comment": 600, "code": 3200 }
  }
}
```

## Use Cases

- **Continuous Code Metrics Tracking**: Monitor code volume and complexity over time
- **Team Analytics**: Track repository growth across sprints or quarters
- **Code Review Insights**: Understand code distribution by language
- **Historical Records**: Maintain a time-series of code metrics in version control
- **CI/CD Integration**: Incorporate code metrics into your workflow

## Prerequisites

- GitHub Actions runner (Ubuntu, macOS, or Windows with bash)
- Repository checkout via `actions/checkout@v4` or later

## Security Considerations

- This action requires read access to your repository contents
- No data is transmitted outside your workflow environment
- Reports are stored locally in your specified output directory
- See [SECURITY.md](SECURITY.md) for detailed security guidelines

## Troubleshooting

### cloc installation fails
Ensure `install-cloc: true` is set and the runner has internet access and appropriate permissions.

### Report file not generated
Check that the `output-dir` path is writable and the action has sufficient permissions to create the directory.

### Analyze specific paths only
Currently, this action analyzes the entire checked-out repository. Use `actions/checkout@v4` with `sparse-checkout` to limit the scope if needed.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests to help improve this action.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Created by Francis Sebastian

## Support

For issues, questions, or feature requests, please open an issue in the [repository](https://github.com/FrancisGopurathingal/ghactions-repo-metrics).