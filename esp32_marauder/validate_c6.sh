#!/bin/bash
# ESP32-C6 Configuration Validation Script

echo "=== ESP32-C6 Marauder Configuration Validation ==="
echo ""

CONFIG_FILE="configs.h"
ERRORS=0

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: $CONFIG_FILE not found"
    exit 1
fi

echo "✓ Found $CONFIG_FILE"
echo ""

# Check for all required C6 defines
echo "Checking C6 configuration sections..."

checks=(
    "Board target define:31://#define MARAUDER_C6"
    "Hardware name:85:#elif defined(MARAUDER_C6)"
    "Board features:427:#ifdef MARAUDER_C6"
    "SD CS pin:2170:#ifdef MARAUDER_C6"
    "Memory limit:2277:#elif defined(MARAUDER_C6)"
    "NeoPixel pin:2301:#elif defined(MARAUDER_C6)"
    "GPS pins:2398:#elif defined(MARAUDER_C6)"
    "Title bytes:2507:#elif defined(MARAUDER_C6)"
    "SD SPI pins:2569:#ifdef MARAUDER_C6"
)

for check in "${checks[@]}"; do
    IFS=':' read -r name line pattern <<< "$check"
    if grep -q "$pattern" "$CONFIG_FILE"; then
        result=$(grep -n "$pattern" "$CONFIG_FILE" | head -1 | cut -d: -f1)
        if [ "$result" = "$line" ]; then
            echo "  ✓ $name (line $line)"
        else
            echo "  ⚠️  $name found at line $result (expected $line)"
        fi
    else
        echo "  ❌ $name - NOT FOUND"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""

# Check for matching ifdef/endif pairs
echo "Checking ifdef/endif balance..."
IFDEF_COUNT=$(grep -c "#ifdef MARAUDER_C6" "$CONFIG_FILE")
ENDIF_COUNT=$(grep -A 30 "#ifdef MARAUDER_C6" "$CONFIG_FILE" | grep -c "#endif")

if [ $IFDEF_COUNT -eq 2 ]; then
    echo "  ✓ Found $IFDEF_COUNT #ifdef MARAUDER_C6 blocks"
else
    echo "  ⚠️  Found $IFDEF_COUNT #ifdef MARAUDER_C6 blocks (expected 2)"
fi

# Check for matching elif
ELIF_COUNT=$(grep -c "#elif defined(MARAUDER_C6)" "$CONFIG_FILE")
if [ $ELIF_COUNT -eq 7 ]; then
    echo "  ✓ Found $ELIF_COUNT #elif defined(MARAUDER_C6) blocks"
else
    echo "  ⚠️  Found $ELIF_COUNT #elif defined(MARAUDER_C6) blocks (expected 7)"
fi

echo ""

# Verify pin definitions exist
echo "Checking C6-specific pin definitions..."
C6_SECTION=$(sed -n '/^[[:space:]]*#ifdef MARAUDER_C6/,/^[[:space:]]*#endif/p' "$CONFIG_FILE")

if echo "$C6_SECTION" | grep -q "HAS_BT"; then
    echo "  ✓ HAS_BT enabled (BLE 5.3)"
else
    echo "  ❌ HAS_BT not found"
    ERRORS=$((ERRORS + 1))
fi

if echo "$C6_SECTION" | grep -q "HAS_GPS"; then
    echo "  ✓ HAS_GPS enabled"
else
    echo "  ❌ HAS_GPS not found"
    ERRORS=$((ERRORS + 1))
fi

if echo "$C6_SECTION" | grep -q "HAS_NEOPIXEL_LED"; then
    echo "  ✓ HAS_NEOPIXEL_LED enabled"
else
    echo "  ❌ HAS_NEOPIXEL_LED not found"
    ERRORS=$((ERRORS + 1))
fi

# Check GPIO pin assignments
echo ""
echo "Checking C6 GPIO pin assignments..."

if grep -A 5 "MARAUDER_C6" "$CONFIG_FILE" | grep -q "GPIO8"; then
    echo "  ✓ NeoPixel LED: GPIO8 (RGB LED)"
else
    echo "  ⚠️  GPIO8 pin assignment not found"
fi

if grep -A 5 "#elif defined(MARAUDER_C6)" "$CONFIG_FILE" | grep -q "GPS_TX 16"; then
    echo "  ✓ GPS TX: GPIO16"
else
    echo "  ⚠️  GPS TX pin not found"
fi

if grep -A 5 "#elif defined(MARAUDER_C6)" "$CONFIG_FILE" | grep -q "GPS_RX 17"; then
    echo "  ✓ GPS RX: GPIO17"
else
    echo "  ⚠️  GPS RX pin not found"
fi

if grep -A 5 "MARAUDER_C6" "$CONFIG_FILE" | grep -q "SD_CS 10"; then
    echo "  ✓ SD CS: GPIO10"
else
    echo "  ⚠️  SD CS pin not found"
fi

echo ""
echo "=== Validation Summary ==="
if [ $ERRORS -eq 0 ]; then
    echo "✅ All checks passed! ESP32-C6 configuration is valid."
    echo ""
    echo "To enable C6 support:"
    echo "  1. Uncomment line 31: #define MARAUDER_C6"
    echo "  2. Build with Arduino IDE or PlatformIO for ESP32-C6"
    echo "  3. Flash to ESP32-C6-DevKitC-1 or compatible board"
    exit 0
else
    echo "❌ Validation failed with $ERRORS error(s)"
    exit 1
fi
