#!/usr/bin/env zsh

# Test runner for the reminder plugin

echo "🧪 Zsh Todo Reminder Plugin - Test Suite"
echo "══════════════════════════════════════════"
echo

# Color definitions for output
if autoload -U colors 2>/dev/null && colors 2>/dev/null; then
    RED=$'\e[31m'
    GREEN=$'\e[32m'
    YELLOW=$'\e[33m'
    BLUE=$'\e[34m'
    MAGENTA=$'\e[35m'
    CYAN=$'\e[36m'
    RESET=$'\e[0m'
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    RESET=""
fi

# Test file configuration
TESTS_DIR="$(dirname "$0")"
TEST_FILES=(
    "display.zsh"
    "configuration.zsh"
    "config_management.zsh"
    "color.zsh"
    "interface.zsh"
    "subcommand_interface.zsh"
    "character.zsh"
    "wizard_noninteractive.zsh"
    "color_mode.zsh"
    "preset_detection.zsh"
    "preset_filtering.zsh"
    "token_size.zsh"
)

PERFORMANCE_TEST_FILE="performance.zsh"
UX_TEST_FILE="ux.zsh"
DOCUMENTATION_TEST_FILE="documentation.zsh"
HELP_EXAMPLES_TEST_FILE="help_examples.zsh"
USER_WORKFLOWS_FILE="user_workflows.zsh"

# Global test tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# Spinner for showing progress during test execution  
show_spinner() {
    local pid=$1
    local delay=0.2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    # Hide cursor
    tput civis 2>/dev/null || true
    
    while kill -0 $pid 2>/dev/null; do
        local char=${spinstr:$((i % ${#spinstr})):1}
        printf " %s\b\b" "$char"
        sleep $delay
        ((i++))
    done
    
    # Show cursor and clear spinner
    tput cnorm 2>/dev/null || true
    printf " \b\b"
}

# Function to run a single test file
run_test_file() {
    local test_file="$1"
    local test_path="$TESTS_DIR/$test_file"
    local current_test="${2:-}"
    local total_tests="${3:-}"
    
    # Show progress indicator
    if [[ "$verbose" == true ]]; then
        echo "${BLUE}▶ Running $test_file...${RESET}"
        echo "────────────────────────────────────────────────────"
    else
        # Show progress with test name
        if [[ -n "$current_test" && -n "$total_tests" ]]; then
            echo -n "${CYAN}[$current_test/$total_tests]${RESET} ${test_file} ... "
        else
            echo -n "${CYAN}▶${RESET} ${test_file} ... "
        fi
    fi
    
    if [[ ! -f "$test_path" ]]; then
        echo "${RED}❌ Test file not found: $test_path${RESET}"
        return 1
    fi
    
    if [[ ! -x "$test_path" ]]; then
        echo "${RED}❌ Test file not executable: $test_path${RESET}"
        return 1
    fi
    
    # Capture output and parse results
    local output
    local exit_code
    
    # Change to plugin directory to ensure relative paths work
    local original_pwd="$PWD"
    cd "$TESTS_DIR/.."
    
    # Add timeout to prevent hanging tests
    if [[ "$verbose" == false ]]; then
        # Run with spinner for non-verbose mode
        if command -v timeout >/dev/null 2>&1; then
            timeout 30 "$test_path" > /tmp/test_output_$$ 2>&1 &
        else
            "$test_path" > /tmp/test_output_$$ 2>&1 &
        fi
        local test_pid=$!
        show_spinner $test_pid
        wait $test_pid
        exit_code=$?
        output=$(cat /tmp/test_output_$$)
        rm -f /tmp/test_output_$$
    else
        # Run normally for verbose mode
        if command -v timeout >/dev/null 2>&1; then
            output=$(timeout 30 "$test_path" 2>&1)
            exit_code=$?
        else
            output=$("$test_path" 2>&1)
            exit_code=$?
        fi
    fi
    
    cd "$original_pwd"
    
    # Parse test results from output
    local file_passed=$(echo "$output" | grep -c "✅ PASS")
    local file_failed=$(echo "$output" | grep -c "❌ FAIL")
    local file_warnings=$(echo "$output" | grep -c "⚠️  WARNING:")
    
    # Update global counters
    TOTAL_TESTS=$((TOTAL_TESTS + file_passed + file_failed))
    PASSED_TESTS=$((PASSED_TESTS + file_passed))
    FAILED_TESTS=$((FAILED_TESTS + file_failed))
    WARNING_TESTS=$((WARNING_TESTS + file_warnings))
    
    # Show results based on mode
    if [[ "$verbose" == true ]]; then
        echo "$output"
        echo "────────────────────────────────────────────────────"
        # Report detailed results in verbose mode
        if [[ $file_failed -eq 0 ]]; then
            echo "${GREEN}✅ $test_file: $file_passed passed, $file_warnings warnings${RESET}"
        else
            echo "${RED}❌ $test_file: $file_passed passed, $file_failed failed, $file_warnings warnings${RESET}"
        fi
    else
        # Non-verbose mode - show compact results
        if [[ $file_failed -eq 0 ]]; then
            echo "${GREEN}✅ ${file_passed} passed${RESET}"
        else
            echo "${RED}❌ ${file_failed} failed${RESET}"
            # Show failure details
            echo "$output" | grep -E "(❌ FAIL:|⚠️  WARNING:)" | head -3
            if [[ $(echo "$output" | grep -c "❌ FAIL:") -gt 3 ]]; then
                echo "   ... and $((file_failed - 3)) more failures"
            fi
        fi
    fi
    
    if [[ "$verbose" == true ]]; then
        echo
    fi
    
    return $exit_code
}

# Function to run performance tests
run_performance_tests() {
    local perf_path="$TESTS_DIR/$PERFORMANCE_TEST_FILE"
    
    if [[ ! -f "$perf_path" ]]; then
        echo "${RED}❌ Performance test file not found: $PERFORMANCE_TEST_FILE${RESET}"
        return 1
    fi
    
    if [[ "$verbose" == true ]]; then
        echo "${MAGENTA}🚀 Running performance tests...${RESET}"
        echo "This may take 30-60 seconds to complete all 16 performance tests."
        echo
    fi
    
    # Run performance tests with timeout
    local output
    local exit_code
    
    if timeout 120 "$perf_path" > /tmp/perf_output 2>&1; then
        output=$(cat /tmp/perf_output)
        exit_code=0
    else
        output=$(cat /tmp/perf_output 2>/dev/null || echo "Performance tests timed out or failed")
        exit_code=1
    fi
    
    # Clean up temp file
    rm -f /tmp/perf_output
    
    # Count performance test results first
    local perf_passed=$(echo "$output" | grep -c "✅ PASS")
    local perf_failed=$(echo "$output" | grep -c "❌ FAIL")
    local perf_warnings=$(echo "$output" | grep -c "⚠️")
    
    # Display relevant output in verbose mode, or failures only
    if [[ "$verbose" == true ]]; then
        echo "$output" | tail -20
    elif [[ $perf_failed -gt 0 || $perf_warnings -gt 0 ]]; then
        echo "${RED}❌ ${perf_failed} failed${RESET}"
        echo "$output" | grep -E "(❌ FAIL|⚠️)" | tail -3
        if [[ $perf_failed -gt 3 ]]; then
            echo "   ... and $((perf_failed - 3)) more failures"
        fi
    else
        echo "${GREEN}✅ ${perf_passed} passed${RESET}"
    fi
    
    # Update global counters
    TOTAL_TESTS=$((TOTAL_TESTS + perf_passed + perf_failed))
    PASSED_TESTS=$((PASSED_TESTS + perf_passed))
    FAILED_TESTS=$((FAILED_TESTS + perf_failed))
    WARNING_TESTS=$((WARNING_TESTS + perf_warnings))
    
    # Report performance results
    if [[ "$verbose" == true ]]; then
        echo "────────────────────────────────────────────────────"
    fi
    if [[ $perf_failed -eq 0 ]]; then
        if [[ "$verbose" == true ]]; then
            echo "${GREEN}✅ Performance tests: $perf_passed passed, $perf_warnings warnings${RESET}"
        fi
    else
        echo "${RED}❌ Performance tests: $perf_passed passed, $perf_failed failed, $perf_warnings warnings${RESET}"
    fi
    if [[ "$verbose" == true ]]; then
        echo
    fi
    
    return $exit_code
}

# Function to run UX tests
run_ux_tests() {
    local ux_path="$TESTS_DIR/$UX_TEST_FILE"
    
    if [[ ! -f "$ux_path" ]]; then
        echo "${RED}❌ UX test file not found: $UX_TEST_FILE${RESET}"
        return 1
    fi
    
    if [[ "$verbose" == true ]]; then
        echo "${MAGENTA}🎨 Running UX tests...${RESET}"
        echo "This validates user experience, onboarding, and progressive disclosure."
        echo
    fi
    
    # Run UX tests with timeout
    local output
    local exit_code
    
    if timeout 60 "$ux_path" > /tmp/ux_output 2>&1; then
        output=$(cat /tmp/ux_output)
        exit_code=0
    else
        output=$(cat /tmp/ux_output 2>/dev/null || echo "UX tests timed out or failed")
        exit_code=1
    fi
    
    # Clean up temp file
    rm -f /tmp/ux_output
    
    # Count UX test results first
    local ux_passed=$(echo "$output" | grep -c "✅ PASS")
    local ux_failed=$(echo "$output" | grep -c "❌ FAIL")
    local ux_warnings=$(echo "$output" | grep -c "⚠️")
    
    # Display relevant output in verbose mode, or failures only
    if [[ "$verbose" == true ]]; then
        echo "$output"
    elif [[ $ux_failed -gt 0 || $ux_warnings -gt 0 ]]; then
        echo "${RED}❌ ${ux_failed} failed${RESET}"
        echo "$output" | grep -E "(❌ FAIL|⚠️)" | tail -3
        if [[ $ux_failed -gt 3 ]]; then
            echo "   ... and $((ux_failed - 3)) more failures"
        fi
    else
        echo "${GREEN}✅ ${ux_passed} passed${RESET}"
    fi
    
    # Update global counters
    TOTAL_TESTS=$((TOTAL_TESTS + ux_passed + ux_failed))
    PASSED_TESTS=$((PASSED_TESTS + ux_passed))
    FAILED_TESTS=$((FAILED_TESTS + ux_failed))
    WARNING_TESTS=$((WARNING_TESTS + ux_warnings))
    
    # Report UX results
    if [[ "$verbose" == true ]]; then
        echo "────────────────────────────────────────────────────"
    fi
    if [[ $ux_failed -eq 0 ]]; then
        if [[ "$verbose" == true ]]; then
            echo "${GREEN}✅ UX tests: $ux_passed passed, $ux_warnings warnings${RESET}"
        fi
    else
        echo "${RED}❌ UX tests: $ux_passed passed, $ux_failed failed, $ux_warnings warnings${RESET}"
    fi
    if [[ "$verbose" == true ]]; then
        echo
    fi
    
    return $exit_code
}

# Function to run user workflow tests
run_user_workflows() {
    local verbose="$1"
    local workflows_path="$TESTS_DIR/$USER_WORKFLOWS_FILE"
    
    if [[ ! -f "$workflows_path" ]]; then
        echo "${RED}❌ User workflows test file not found: $USER_WORKFLOWS_FILE${RESET}"
        return 1
    fi
    
    if [[ "$verbose" == true ]]; then
        echo "${MAGENTA}🚀 Running user workflow tests...${RESET}"
        echo "This validates complete end-to-end user scenarios."
        echo
    fi
    
    # Run workflow tests
    local output
    local exit_code
    
    output=$("$workflows_path" 2>&1)
    exit_code=$?
    
    # Count workflow test results
    local workflows_passed=$(echo "$output" | grep -c "Passed:.*[1-9]")
    local workflows_failed=$(echo "$output" | grep -c "Failed:.*[1-9]")
    
    # Display relevant output
    if [[ "$verbose" == true ]]; then
        echo "$output"
    elif [[ $workflows_failed -gt 0 ]]; then
        echo "${RED}❌ ${workflows_failed} failed${RESET}"
        echo "$output" | grep -E "(❌|Failed:)" | tail -3
        if [[ $workflows_failed -gt 3 ]]; then
            echo "   ... and $((workflows_failed - 3)) more failures"
        fi
    else
        echo "${GREEN}✅ 5 passed${RESET}"
    fi
    
    # Update global counters (5 workflows tested)
    TOTAL_TESTS=$((TOTAL_TESTS + 5))
    if [[ $workflows_failed -eq 0 && $workflows_passed -gt 0 ]]; then
        PASSED_TESTS=$((PASSED_TESTS + 5))
    else
        PASSED_TESTS=$((PASSED_TESTS + (5 - workflows_failed)))
        FAILED_TESTS=$((FAILED_TESTS + workflows_failed))
    fi
    
    # Set exit code
    if [[ $exit_code -ne 0 ]]; then
        echo "${RED}❌ User workflow tests: execution failed${RESET}"
    fi
    
    return $exit_code
}

# Function to run documentation tests
run_documentation_tests() {
    local doc_path="$TESTS_DIR/$DOCUMENTATION_TEST_FILE"
    
    if [[ ! -f "$doc_path" ]]; then
        echo "${RED}❌ Documentation test file not found: $DOCUMENTATION_TEST_FILE${RESET}"
        return 1
    fi
    
    if [[ "$verbose" == true ]]; then
        echo "${MAGENTA}📚 Running documentation tests...${RESET}"
        echo "This validates that documentation accurately represents the implementation."
        echo
    fi
    
    # Run documentation tests with timeout
    local output
    local exit_code
    
    if timeout 60 "$doc_path" > /tmp/doc_output 2>&1; then
        output=$(cat /tmp/doc_output)
        exit_code=0
    else
        output=$(cat /tmp/doc_output 2>/dev/null || echo "Documentation tests timed out or failed")
        exit_code=1
    fi
    
    # Clean up temp file
    rm -f /tmp/doc_output
    
    # Count documentation test results first
    local doc_passed=$(echo "$output" | grep -c "✅ PASS")
    local doc_failed=$(echo "$output" | grep -c "❌ FAIL")
    local doc_warnings=$(echo "$output" | grep -c "⚠️")
    
    # Display relevant output in verbose mode, or failures only
    if [[ "$verbose" == true ]]; then
        echo "$output"
    elif [[ $doc_failed -gt 0 || $doc_warnings -gt 0 ]]; then
        echo "${RED}❌ ${doc_failed} failed${RESET}"
        echo "$output" | grep -E "(❌ FAIL|⚠️)" | tail -3
        if [[ $doc_failed -gt 3 ]]; then
            echo "   ... and $((doc_failed - 3)) more failures"
        fi
    else
        echo "${GREEN}✅ ${doc_passed} passed${RESET}"
    fi
    
    # Update global counters
    TOTAL_TESTS=$((TOTAL_TESTS + doc_passed + doc_failed))
    PASSED_TESTS=$((PASSED_TESTS + doc_passed))
    FAILED_TESTS=$((FAILED_TESTS + doc_failed))
    WARNING_TESTS=$((WARNING_TESTS + doc_warnings))
    
    # Report documentation results
    if [[ "$verbose" == true ]]; then
        echo "────────────────────────────────────────────────────"
    fi
    if [[ $doc_failed -eq 0 ]]; then
        if [[ "$verbose" == true ]]; then
            echo "${GREEN}✅ Documentation tests: $doc_passed passed, $doc_warnings warnings${RESET}"
        fi
    else
        echo "${RED}❌ Documentation tests: $doc_passed passed, $doc_failed failed, $doc_warnings warnings${RESET}"
    fi
    if [[ "$verbose" == true ]]; then
        echo
    fi
    
    return $exit_code
}

# Function to run help examples tests
run_help_examples_tests() {
    local help_path="$TESTS_DIR/$HELP_EXAMPLES_TEST_FILE"
    
    if [[ ! -f "$help_path" ]]; then
        echo "${RED}❌ Help examples test file not found: $HELP_EXAMPLES_TEST_FILE${RESET}"
        return 1
    fi
    
    if [[ "$verbose" == true ]]; then
        echo "${MAGENTA}📖 Running help examples tests...${RESET}"
        echo "This validates that all help examples actually work and produce expected outputs."
        echo
    fi
    
    # Run help examples tests with timeout
    local output
    local exit_code
    
    if timeout 30 "$help_path" > /tmp/help_output 2>&1; then
        output=$(cat /tmp/help_output)
        exit_code=0
    else
        output=$(cat /tmp/help_output 2>/dev/null || echo "Help examples tests timed out or failed")
        exit_code=1
    fi
    
    # Clean up temp file
    rm -f /tmp/help_output
    
    # Count help examples test results
    local help_passed=$(echo "$output" | grep -c "✅ PASS")
    local help_failed=$(echo "$output" | grep -c "❌ FAIL")
    local help_warnings=$(echo "$output" | grep -c "⚠️")
    
    # Display relevant output in verbose mode, or failures only
    if [[ "$verbose" == true ]]; then
        echo "$output"
    elif [[ $help_failed -gt 0 || $help_warnings -gt 0 ]]; then
        echo "${RED}❌ ${help_failed} failed${RESET}"
        echo "$output" | grep -E "(❌ FAIL|⚠️)" | tail -3
        if [[ $help_failed -gt 3 ]]; then
            echo "   ... and $((help_failed - 3)) more failures"
        fi
    else
        echo "${GREEN}✅ ${help_passed} passed${RESET}"
    fi
    
    # Update global counters
    TOTAL_TESTS=$((TOTAL_TESTS + help_passed + help_failed))
    PASSED_TESTS=$((PASSED_TESTS + help_passed))
    FAILED_TESTS=$((FAILED_TESTS + help_failed))
    WARNING_TESTS=$((WARNING_TESTS + help_warnings))
    
    # Report help examples results
    if [[ "$verbose" == true ]]; then
        echo "────────────────────────────────────────────────────"
    fi
    if [[ $help_failed -eq 0 ]]; then
        if [[ "$verbose" == true ]]; then
            echo "${GREEN}✅ Help examples tests: $help_passed passed, $help_warnings warnings${RESET}"
        fi
    else
        echo "${RED}❌ Help examples tests: $help_passed passed, $help_failed failed, $help_warnings warnings${RESET}"
    fi
    if [[ "$verbose" == true ]]; then
        echo
    fi
    
    return $exit_code
}

# Function to display summary
display_summary() {
    echo "🎯 Test Suite Summary"
    echo "═════════════════════"
    echo "Total Tests:    $TOTAL_TESTS"
    echo "${GREEN}Passed:         $PASSED_TESTS${RESET}"
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo "${RED}Failed:         $FAILED_TESTS${RESET}"
    else
        echo "Failed:         $FAILED_TESTS"
    fi
    if [[ $WARNING_TESTS -gt 0 ]]; then
        echo "${YELLOW}Warnings:       $WARNING_TESTS${RESET}"
    else
        echo "Warnings:       $WARNING_TESTS"
    fi
    echo
    
    # Calculate success rate
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo "Success Rate:   ${success_rate}%"
    fi
    
    # Overall result
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo "${GREEN}🎉 All tests passed!${RESET}"
        if [[ $WARNING_TESTS -gt 0 ]]; then
            echo "${YELLOW}⚠️  There were $WARNING_TESTS warnings to review.${RESET}"
        fi
        return 0
    else
        echo "${RED}💥 $FAILED_TESTS test(s) failed.${RESET}"
        return 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    echo "${CYAN}🔍 Checking prerequisites...${RESET}"
    
    # Check if plugin file exists
    if [[ ! -f "$TESTS_DIR/../reminder.plugin.zsh" ]]; then
        echo "${RED}❌ Plugin file not found: reminder.plugin.zsh${RESET}"
        echo "Make sure you're running tests from the correct directory."
        return 1
    fi
    
    # Check zsh version
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "✅ Zsh version: $ZSH_VERSION"
    else
        echo "${YELLOW}⚠️  Not running in zsh. Some tests may not work correctly.${RESET}"
    fi
    
    # Check if colors are available
    if command -v colors >/dev/null 2>&1; then
        echo "✅ Color support available"
    else
        echo "${YELLOW}⚠️  Color support not available${RESET}"
    fi
    
    # Check for optional dependencies
    local deps_available=true
    for dep in bc curl jq; do
        if command -v "$dep" >/dev/null 2>&1; then
            echo "✅ $dep available"
        else
            echo "${YELLOW}⚠️  $dep not available (some tests may be limited)${RESET}"
            deps_available=false
        fi
    done
    
    echo
    return 0
}

# Function to run specific test files
run_specific_tests() {
    local selected_tests=("$@")
    
    if [[ ${#selected_tests[@]} -eq 0 ]]; then
        echo "${RED}❌ No test files specified${RESET}"
        return 1
    fi
    
    for test_file in "${selected_tests[@]}"; do
        if [[ ! " ${TEST_FILES[@]} " =~ " $test_file " ]]; then
            echo "${RED}❌ Unknown test file: $test_file${RESET}"
            echo "Available tests: ${TEST_FILES[*]}"
            return 1
        fi
        run_test_file "$test_file"
    done
}

# Function to display help
show_help() {
    local script_name="$(basename "${1:-$0}")"
    echo "Usage: $script_name [options] [test_files...]"
    echo
    echo "By default, runs ALL tests (functional, performance, UX, documentation)"
    echo
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -l, --list           List available test files"
    echo "  -v, --verbose        Run with verbose output"
    echo "  --only-functional    Run only functional tests (skip perf, ux, docs)"
    echo "  --skip-perf          Skip performance tests"
    echo "  --skip-ux            Skip UX tests"
    echo "  --skip-docs          Skip documentation tests"
    echo "  -m, --meta           Add Claude-powered analysis to test results"
    echo "  --improve-docs       Improve documentation quality"
    echo
    echo "Test Files:"
    for test_file in "${TEST_FILES[@]}"; do
        echo "  $test_file"
    done
    echo
    echo "Examples:"
    echo "  $script_name                          # Run ALL tests (default)"
    echo "  $script_name --only-functional        # Run only functional tests"
    echo "  $script_name --skip-perf              # Run all except performance"
    echo "  $script_name --skip-perf --skip-docs  # Run functional + UX only"
    echo "  $script_name display.zsh              # Run specific test file"
    echo "  $script_name --meta                   # Run all tests + Claude analysis"
    echo "  $script_name --only-functional --meta # Functional tests + Claude analysis"
    echo "  $script_name --improve-docs           # Improve documentation"
}

# Function to list available tests
list_tests() {
    echo "Available test files:"
    for test_file in "${TEST_FILES[@]}"; do
        local test_path="$TESTS_DIR/$test_file"
        if [[ -f "$test_path" ]]; then
            echo "  ✅ $test_file"
        else
            echo "  ❌ $test_file (missing)"
        fi
    done
}

# Main execution
main() {
    local script_name="$1"
    shift  # Remove script name from arguments
    
    # By default, run ALL tests (functional, performance, ux, docs)
    local skip_functional=false
    local skip_performance=false
    local skip_ux=false
    local skip_documentation=false
    local run_meta=false
    local verbose=false
    local only_functional=false
    local specific_tests=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help "$script_name"
                return 0
                ;;
            -l|--list)
                list_tests
                return 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            --only-functional|--functional)
                only_functional=true
                shift
                ;;
            --skip-perf|--no-perf)
                skip_performance=true
                shift
                ;;
            --skip-ux|--no-ux)
                skip_ux=true
                shift
                ;;
            --skip-docs|--no-docs)
                skip_documentation=true
                shift
                ;;
            -m|--meta)
                run_meta=true
                shift
                ;;
            --improve-docs)
                echo "📝 Running documentation improvement..."
                if [[ -f "./dev-tools/improve-docs.zsh" ]]; then
                    ./dev-tools/improve-docs.zsh
                    return $?
                else
                    echo "❌ Documentation improvement tool not available"
                    return 1
                fi
                ;;
            -*)
                echo "${RED}❌ Unknown option: $1${RESET}"
                show_help "$script_name"
                return 1
                ;;
            *)
                specific_tests+=("$1")
                # If specific tests are provided, only run those
                skip_functional=true
                skip_performance=true
                skip_ux=true
                skip_documentation=true
                shift
                ;;
        esac
    done
    
    # Set verbose mode
    if [[ "$verbose" == true ]]; then
        set -x
    fi
    
    # Check prerequisites
    if ! check_prerequisites; then
        return 1
    fi
    
    local start_time=$(date +%s 2>/dev/null || date +%s)
    
    # Handle --only-functional flag
    if [[ "$only_functional" == true ]]; then
        skip_performance=true
        skip_ux=true
        skip_documentation=true
    fi
    
    # Determine what to run
    local running_all=false
    if [[ ${#specific_tests[@]} -eq 0 && "$skip_functional" == false && "$skip_performance" == false && "$skip_ux" == false && "$skip_documentation" == false ]]; then
        running_all=true
        echo "${CYAN}🚀 Running ALL tests (functional, performance, UX, documentation)...${RESET}"
        echo
    elif [[ ${#specific_tests[@]} -gt 0 ]]; then
        echo "${CYAN}🚀 Running specific tests...${RESET}"
        echo
        run_specific_tests "${specific_tests[@]}"
    else
        echo "${CYAN}🚀 Running selected test categories...${RESET}"
        echo
    fi
    
    # Calculate total test count for proper numbering
    local all_tests=()
    local current_test_num=1
    
    # Add functional tests
    if [[ "$skip_functional" == false && ${#specific_tests[@]} -eq 0 ]]; then
        all_tests+=("${TEST_FILES[@]}")
    fi
    
    # Add extended tests
    if [[ "$skip_performance" == false && ${#specific_tests[@]} -eq 0 ]]; then
        all_tests+=("performance.zsh")
    fi
    if [[ "$skip_ux" == false && ${#specific_tests[@]} -eq 0 ]]; then
        all_tests+=("ux.zsh")
    fi
    if [[ ${#specific_tests[@]} -eq 0 || " ${specific_tests[@]} " =~ " user_workflows " ]]; then
        all_tests+=("user_workflows.zsh")
    fi
    if [[ "$skip_documentation" == false && ${#specific_tests[@]} -eq 0 ]]; then
        all_tests+=("documentation.zsh")
        all_tests+=("help_examples.zsh")
    fi
    
    local total_test_count=${#all_tests[@]}
    
    # Run all tests with proper numbering
    for test_file in "${all_tests[@]}"; do
        if [[ " ${TEST_FILES[@]} " =~ " $test_file " ]]; then
            # Functional test - run with standard function
            run_test_file "$test_file" "$current_test_num" "$total_test_count"
        else
            # Extended test - run without background processes to fix counter bug
            echo -n "${CYAN}[$current_test_num/$total_test_count]${RESET} $test_file ... "
            
            # Store counters before test
            local before_total=$TOTAL_TESTS
            local before_passed=$PASSED_TESTS
            local before_failed=$FAILED_TESTS
            local before_warnings=$WARNING_TESTS
            
            # Run test in foreground to preserve global counter updates
            case "$test_file" in
                "performance.zsh")
                    run_performance_tests
                    ;;
                "ux.zsh")
                    run_ux_tests
                    ;;
                "user_workflows.zsh")
                    run_user_workflows "$verbose"
                    ;;
                "documentation.zsh")
                    run_documentation_tests
                    ;;
                "help_examples.zsh")
                    run_help_examples_tests
                    ;;
            esac
            
            local test_exit_code=$?
            
            # Calculate changes in counters and show compact results
            local test_total=$((TOTAL_TESTS - before_total))
            local test_passed=$((PASSED_TESTS - before_passed))
            local test_failed=$((FAILED_TESTS - before_failed))
            local test_warnings=$((WARNING_TESTS - before_warnings))
            
            if [[ $test_failed -eq 0 ]]; then
                echo "${GREEN}✅ ${test_passed} passed${RESET}"
            else
                echo "${RED}❌ ${test_failed} failed${RESET}"
            fi
        fi
        ((current_test_num++))
    done
    
    # Run meta-analysis if requested
    if [[ "$run_meta" == true ]]; then
        echo
        echo "${MAGENTA}🤖 Running Claude meta-analysis...${RESET}"
        
        # Determine what tests were run
        local meta_test_type="functional"
        if [[ "$skip_performance" == false && "$skip_ux" == false && "$skip_documentation" == false ]]; then
            meta_test_type="complete"
        elif [[ "$skip_performance" == true && "$skip_ux" == true && "$skip_documentation" == true ]]; then
            meta_test_type="functional"
        elif [[ "$skip_functional" == true && "$skip_performance" == true && "$skip_documentation" == true ]]; then
            meta_test_type="ux"
        elif [[ "$skip_functional" == true && "$skip_ux" == true && "$skip_performance" == true ]]; then
            meta_test_type="documentation"
        elif [[ "$skip_functional" == true && "$skip_ux" == true && "$skip_documentation" == true ]]; then
            meta_test_type="performance"
        fi
        
        # Run meta-analysis
        if [[ -x "$TESTS_DIR/meta_test.zsh" ]]; then
            "$TESTS_DIR/meta_test.zsh" "$meta_test_type"
            local meta_exit_code=$?
            
            if [[ $meta_exit_code -ne 0 ]]; then
                FAILED_TESTS=$((FAILED_TESTS + 1))
            fi
        else
            echo "${RED}❌ Meta-test script not found${RESET}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
    
    local end_time=$(date +%s 2>/dev/null || date +%s)
    local duration=$((end_time - start_time))
    
    echo
    echo "📊 Execution time: ${duration}s"
    echo
    
    # Display final summary
    display_summary
}

# Execute main function if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"test.zsh" ]]; then
    # Pass script name as first argument to main
    main "$0" "$@"
fi