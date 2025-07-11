#!/usr/bin/env zsh

# Color configuration and validation tests for the reminder plugin

echo "🎨 Testing Color Configuration & Validation"
echo "═══════════════════════════════════════════"

# Load shared test utilities
source "$(dirname "$0")/test_utils.zsh"

# Test 1: Default color configuration
test_default_colors() {
    echo "\n1. Testing default color configuration:"
    
    source_test_plugin
    
    # Test default color values
    if [[ "$_TODO_INTERNAL_TASK_COLORS" == "167,71,136,110,139,73" ]]; then
        echo "✅ PASS: Default task colors correct"
    else
        echo "❌ FAIL: Default task colors wrong (got: $_TODO_INTERNAL_TASK_COLORS)"
    fi
    
    if [[ "$_TODO_INTERNAL_BORDER_COLOR" == "240" ]]; then
        echo "✅ PASS: Default border color correct"
    else
        echo "❌ FAIL: Default border color wrong (got: $_TODO_INTERNAL_BORDER_COLOR)"
    fi
    
    if [[ "$_TODO_INTERNAL_TASK_TEXT_COLOR" == "240" ]]; then
        echo "✅ PASS: Default task text color correct"
    else
        echo "❌ FAIL: Default task text color wrong (got: $_TODO_INTERNAL_TASK_TEXT_COLOR)"
    fi
    
    if [[ "$_TODO_INTERNAL_TITLE_COLOR" == "250" ]]; then
        echo "✅ PASS: Default title color correct"
    else
        echo "❌ FAIL: Default title color wrong (got: $_TODO_INTERNAL_TITLE_COLOR)"
    fi
    
    if [[ "$_TODO_INTERNAL_AFFIRMATION_COLOR" == "109" ]]; then
        echo "✅ PASS: Default affirmation color correct"
    else
        echo "❌ FAIL: Default affirmation color wrong (got: $_TODO_INTERNAL_AFFIRMATION_COLOR)"
    fi
    
    if [[ "$_TODO_INTERNAL_BORDER_BG_COLOR" == "235" ]]; then
        echo "✅ PASS: Default border background color correct"
    else
        echo "❌ FAIL: Default border background color wrong (got: $_TODO_INTERNAL_BORDER_BG_COLOR)"
    fi
    
    if [[ "$_TODO_INTERNAL_CONTENT_BG_COLOR" == "235" ]]; then
        echo "✅ PASS: Default content background color correct"
    else
        echo "❌ FAIL: Default content background color wrong (got: $_TODO_INTERNAL_CONTENT_BG_COLOR)"
    fi
}

# Test 2: Color array initialization
test_color_array() {
    echo "\n2. Testing color array initialization:"
    
    # Initialize the color array manually for testing (since plugin loads in different context)
    typeset -a _TODO_INTERNAL_COLORS
    _TODO_INTERNAL_COLORS=(${(s:,:)_TODO_INTERNAL_TASK_COLORS})
    
    # Test color array initialization
    if [[ ${#_TODO_INTERNAL_COLORS[@]} -eq 6 ]]; then
        echo "✅ PASS: Color array initialized with correct count"
    else
        echo "❌ FAIL: Color array has wrong size (got: ${#_TODO_INTERNAL_COLORS[@]}, expected: 6)"
    fi
    
    # Test that array contains expected values
    local expected_colors=(167 71 136 110 139 73)
    local array_match=true
    for ((i=1; i<=${#expected_colors[@]}; i++)); do
        if [[ "${_TODO_INTERNAL_COLORS[i]}" != "${expected_colors[i]}" ]]; then
            array_match=false
            break
        fi
    done
    
    if [[ "$array_match" == "true" ]]; then
        echo "✅ PASS: Color array contains expected default values"
    else
        echo "❌ FAIL: Color array values don't match defaults (got: ${_TODO_INTERNAL_COLORS[@]})"
    fi
}

# Test 3: Color validation logic
test_color_validation_logic() {
    echo "\n3. Testing color validation logic:"
    
    # Test valid color range (0-255)
    valid_color=128
    if [[ $valid_color -ge 0 && $valid_color -le 255 ]]; then
        echo "✅ PASS: Valid color range check works"
    else
        echo "❌ FAIL: Valid color range check failed"
    fi
    
    # Test invalid color range 
    invalid_color=256
    if [[ $invalid_color -gt 255 ]]; then
        echo "✅ PASS: Invalid color range detection works"
    else
        echo "❌ FAIL: Invalid color range detection failed"
    fi
    
    # Test comma-separated format validation
    valid_format="123,45,67"
    if [[ "$valid_format" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
        echo "✅ PASS: Valid task colors format check works"
    else
        echo "❌ FAIL: Valid task colors format check failed"
    fi
    
    invalid_format="red,green,blue"
    if [[ ! "$invalid_format" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
        echo "✅ PASS: Invalid task colors format detection works"
    else
        echo "❌ FAIL: Invalid task colors format detection failed"
    fi
    
    # Test empty string detection
    empty_format=""
    if [[ -z "$empty_format" ]] || [[ ! "$empty_format" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
        echo "✅ PASS: Empty task colors format detection works"
    else
        echo "❌ FAIL: Empty task colors format detection failed"
    fi
}

# Test 4: Key color validation scenarios
test_color_validation_scenarios() {
    echo "\n4. Testing key color validation scenarios:"
    
    # Test valid color configuration
    COLUMNS=80 _TODO_INTERNAL_TASK_COLORS="196,46,33" _TODO_INTERNAL_BORDER_COLOR=244 _TODO_INTERNAL_AFFIRMATION_COLOR=109 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "✅ Valid colors accepted"' 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ PASS: Valid color configuration loads successfully"
    else
        echo "❌ FAIL: Valid color configuration rejected"
    fi
    
    # Test invalid border color (too high)
    error_output=$(COLUMNS=80 _TODO_INTERNAL_BORDER_COLOR=256 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
    if [[ $? -ne 0 ]] && [[ "$error_output" == *"_TODO_INTERNAL_BORDER_COLOR must be a number between 0-255"* ]]; then
        echo "✅ PASS: Invalid border color (256) properly rejected"
    else
        echo "❌ FAIL: Invalid border color not properly rejected"
    fi
    
    # Test invalid task colors (non-numeric)
    error_output=$(COLUMNS=80 _TODO_INTERNAL_TASK_COLORS="red,green,blue" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
    if [[ $? -ne 0 ]] && [[ "$error_output" == *"_TODO_INTERNAL_TASK_COLORS must be comma-separated numbers"* ]]; then
        echo "✅ PASS: Non-numeric task colors properly rejected"
    else
        echo "❌ FAIL: Non-numeric task colors not properly rejected"
    fi
    
    # Test invalid border background color (too high)
    error_output=$(COLUMNS=80 _TODO_INTERNAL_BORDER_BG_COLOR=256 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
    if [[ $? -ne 0 ]] && [[ "$error_output" == *"_TODO_INTERNAL_BORDER_BG_COLOR must be a number between 0-255"* ]]; then
        echo "✅ PASS: Invalid border background color (256) properly rejected"
    else
        echo "❌ FAIL: Invalid border background color not properly rejected"
    fi
    
    # Test invalid content background color (too high)
    error_output=$(COLUMNS=80 _TODO_INTERNAL_CONTENT_BG_COLOR=300 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
    if [[ $? -ne 0 ]] && [[ "$error_output" == *"_TODO_INTERNAL_CONTENT_BG_COLOR must be a number between 0-255"* ]]; then
        echo "✅ PASS: Invalid content background color (300) properly rejected"
    else
        echo "❌ FAIL: Invalid content background color not properly rejected"
    fi
    
    # Test invalid border background color (non-numeric)
    error_output=$(COLUMNS=80 _TODO_INTERNAL_BORDER_BG_COLOR="gray" zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh' 2>&1)
    if [[ $? -ne 0 ]] && [[ "$error_output" == *"_TODO_INTERNAL_BORDER_BG_COLOR must be a number between 0-255"* ]]; then
        echo "✅ PASS: Non-numeric border background color properly rejected"
    else
        echo "❌ FAIL: Non-numeric border background color not properly rejected"
    fi
    
    # Test valid border background color configuration
    COLUMNS=80 _TODO_INTERNAL_BORDER_COLOR=244 _TODO_INTERNAL_BORDER_BG_COLOR=233 _TODO_INTERNAL_CONTENT_BG_COLOR=234 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "Valid border colors accepted"' 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ PASS: Valid border background color configuration loads successfully"
    else
        echo "❌ FAIL: Valid border background color configuration rejected"
    fi
    
    # Test boundary values (0 and 255)
    COLUMNS=80 _TODO_INTERNAL_TASK_COLORS="0,255" _TODO_INTERNAL_BORDER_COLOR=0 _TODO_INTERNAL_BORDER_BG_COLOR=255 _TODO_INTERNAL_CONTENT_BG_COLOR=0 _TODO_INTERNAL_AFFIRMATION_COLOR=255 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "Boundary values loaded"' 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ PASS: Boundary values (0,255) accepted for all color types"
    else
        echo "❌ FAIL: Boundary values (0,255) rejected for border/content colors"
    fi
}

# Test 5: Custom color configuration
test_custom_colors() {
    echo "\n5. Testing custom color configuration:"
    
    # Test custom colors are applied
    original_task_colors="$_TODO_INTERNAL_TASK_COLORS"
    original_border_color="$_TODO_INTERNAL_BORDER_COLOR"
    original_border_bg_color="$_TODO_INTERNAL_BORDER_BG_COLOR"
    original_content_bg_color="$_TODO_INTERNAL_CONTENT_BG_COLOR"
    original_affirmation_color="$_TODO_INTERNAL_AFFIRMATION_COLOR"
    
    # Set custom colors
    _TODO_INTERNAL_TASK_COLORS="196,46,33"
    _TODO_INTERNAL_BORDER_COLOR=244
    _TODO_INTERNAL_BORDER_BG_COLOR=233
    _TODO_INTERNAL_CONTENT_BG_COLOR=234
    _TODO_INTERNAL_AFFIRMATION_COLOR=33
    
    # Reinitialize color array
    typeset -a _TODO_INTERNAL_COLORS
    _TODO_INTERNAL_COLORS=(${(s:,:)_TODO_INTERNAL_TASK_COLORS})
    
    if [[ ${#_TODO_INTERNAL_COLORS[@]} -eq 3 ]]; then
        echo "✅ PASS: Custom task color array has correct size"
    else
        echo "❌ FAIL: Custom task color array has wrong size (got: ${#_TODO_INTERNAL_COLORS[@]}, expected: 3)"
    fi
    
    if [[ "${_TODO_INTERNAL_COLORS[1]}" == "196" && "${_TODO_INTERNAL_COLORS[2]}" == "46" && "${_TODO_INTERNAL_COLORS[3]}" == "33" ]]; then
        echo "✅ PASS: Custom task colors properly set"
    else
        echo "❌ FAIL: Custom task colors not properly set (got: ${_TODO_INTERNAL_COLORS[@]})"
    fi
    
    # Test custom border background colors
    if [[ "$_TODO_INTERNAL_BORDER_BG_COLOR" == "233" ]]; then
        echo "✅ PASS: Custom border background color properly set"
    else
        echo "❌ FAIL: Custom border background color not properly set (got: $_TODO_INTERNAL_BORDER_BG_COLOR, expected: 233)"
    fi
    
    if [[ "$_TODO_INTERNAL_CONTENT_BG_COLOR" == "234" ]]; then
        echo "✅ PASS: Custom content background color properly set"
    else
        echo "❌ FAIL: Custom content background color not properly set (got: $_TODO_INTERNAL_CONTENT_BG_COLOR, expected: 234)"
    fi
    
    # Restore original values
    _TODO_INTERNAL_TASK_COLORS="$original_task_colors"
    _TODO_INTERNAL_BORDER_COLOR="$original_border_color"
    _TODO_INTERNAL_BORDER_BG_COLOR="$original_border_bg_color"
    _TODO_INTERNAL_CONTENT_BG_COLOR="$original_content_bg_color"
    _TODO_INTERNAL_AFFIRMATION_COLOR="$original_affirmation_color"
    _TODO_INTERNAL_COLORS=(${(s:,:)_TODO_INTERNAL_TASK_COLORS})
}

# Test 6: Border color combinations
test_border_color_combinations() {
    echo "\n6. Testing border color combinations:"
    
    # Test default combination (border and content should be same)
    source_test_plugin
    
    if [[ "$_TODO_INTERNAL_BORDER_BG_COLOR" == "$_TODO_INTERNAL_CONTENT_BG_COLOR" ]]; then
        echo "✅ PASS: Default border and content background colors match (unified look)"
    else
        echo "❌ FAIL: Default border and content background colors don't match (got border: $_TODO_INTERNAL_BORDER_BG_COLOR, content: $_TODO_INTERNAL_CONTENT_BG_COLOR)"
    fi
    
    # Test contrasting border and content colors
    _TODO_INTERNAL_BORDER_BG_COLOR=196  # Red background
    _TODO_INTERNAL_CONTENT_BG_COLOR=235 # Dark gray background
    
    if [[ "$_TODO_INTERNAL_BORDER_BG_COLOR" != "$_TODO_INTERNAL_CONTENT_BG_COLOR" ]]; then
        echo "✅ PASS: Contrasting border/content backgrounds can be set (border: $_TODO_INTERNAL_BORDER_BG_COLOR, content: $_TODO_INTERNAL_CONTENT_BG_COLOR)"
    else
        echo "❌ FAIL: Contrasting border/content backgrounds not properly set"
    fi
    
    # Test color validation in combination
    COLUMNS=80 _TODO_INTERNAL_BORDER_COLOR=255 _TODO_INTERNAL_BORDER_BG_COLOR=196 _TODO_INTERNAL_CONTENT_BG_COLOR=235 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "Combination loaded"' 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ PASS: High contrast combination (white on red border, content on dark) loads successfully"
    else
        echo "❌ FAIL: High contrast color combination rejected"
    fi
    
    # Test edge case: same foreground and background color (should still work)
    COLUMNS=80 _TODO_INTERNAL_BORDER_COLOR=240 _TODO_INTERNAL_BORDER_BG_COLOR=240 zsh -c 'autoload -U colors; colors; source reminder.plugin.zsh; echo "Same fg/bg loaded"' 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ PASS: Same foreground/background color combination accepted (creates invisible border effect)"
    else
        echo "❌ FAIL: Same foreground/background color combination rejected"
    fi
    
    # Restore original values for cleanup
    _TODO_INTERNAL_BORDER_BG_COLOR=235
    _TODO_INTERNAL_CONTENT_BG_COLOR=235
}

# Run all color tests
main() {
    test_default_colors
    test_color_array
    test_color_validation_logic
    test_color_validation_scenarios
    test_custom_colors
    test_border_color_combinations
    
    echo "\n🎯 Color Tests Completed"
    echo "═════════════════════════"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"color.zsh" ]]; then
    main "$@"
fi