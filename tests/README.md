# tdo Testing Suite

This directory contains comprehensive unit and integration tests for the tdo.sh script.

## Setup

### Install bats-core

```bash
# macOS with Homebrew
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# Manual installation
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### Install Test Dependencies

```bash
# Ensure required tools are available
sudo apt-get install ripgrep fzf bat  # Ubuntu/Debian
brew install ripgrep fzf bat         # macOS
```

## Running Tests

```bash
# Run all tests
bats tests/

# Run specific test files
bats tests/unit/test_date_parsing.bats
bats tests/unit/test_file_generation.bats
bats tests/unit/test_utility_functions.bats

# Run with verbose output
bats -p tests/

# Run tests and show timing
bats --timing tests/
```

## Test Structure

```
tests/
├── README.md                    # This file
├── test_helper.bash            # Common test utilities and mocks
├── unit/                       # Unit tests for individual functions
│   ├── test_date_parsing.bats     # Natural language date parsing
│   ├── test_file_generation.bats  # File path generation 
│   └── test_utility_functions.bats # Helper functions
├── integration/                # End-to-end workflow tests
│   └── test_workflows.bats        # Main command workflows
└── fixtures/                   # Test data and expected outputs
    └── sample_notes/              # Sample notes structure
```

## Test Coverage

### Unit Tests (High Priority)
- ✅ **Date Parsing**: All natural language patterns, weekday calculations
- ✅ **File Generation**: Date to file path conversion, format handling
- ✅ **Utility Functions**: Platform detection, environment validation

### Integration Tests (Medium Priority)
- 🔄 **Todo Workflows**: End-to-end todo creation and navigation
- 🔄 **Journal Workflows**: Journal entry creation and date handling
- 🔄 **Note Workflows**: Note creation and search functionality

### CI Integration (Low Priority)
- 🔄 **GitHub Actions**: Automated testing on push/PR
- 🔄 **Cross-Platform**: Testing on Linux and macOS

## Mock Strategy

The tests use comprehensive mocking to ensure consistent, isolated testing:

- **Date Mocking**: Fixed test date (Friday July 18, 2025) for predictable results
- **Command Mocking**: Mock external commands (rg, fzf, git, editor)
- **Environment Mocking**: Temporary test directories with proper cleanup
- **Platform Mocking**: Test both gdate (macOS) and date (Linux) paths

## Test Examples

### Date Parsing Tests
```bash
@test "parse_natural_date handles weekdays in current week" {
    result=$(parse_natural_date "monday")
    assert_equal "$result" "-4"  # Monday of current week
}
```

### File Generation Tests
```bash
@test "generate_file_path handles absolute date format" {
    result=$(generate_file_path "2025-07-14")
    assert_equal "$result" "2025/07/2025-07-14.md"
}
```

## Contributing

When adding new features to tdo.sh:

1. **Add corresponding tests** for new functionality
2. **Update existing tests** if behavior changes
3. **Run full test suite** before submitting changes
4. **Maintain 100% coverage** for date parsing logic

## Debugging Tests

```bash
# Run single test with debug output
bats --verbose-run tests/unit/test_date_parsing.bats

# Show test timing for performance analysis
bats --timing tests/

# Print test setup/teardown for debugging
bats --print-output-on-failure tests/
```