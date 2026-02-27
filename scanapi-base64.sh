#!/bin/bash

# Configuration
MOBICARD_VERSION="2.0"
MOBICARD_MODE="LIVE"
MOBICARD_MERCHANT_ID="4"
MOBICARD_API_KEY="YmJkOGY0OTZhMTU2ZjVjYTIyYzFhZGQyOWRiMmZjMmE2ZWU3NGIxZWM3ZTBiZSJ9"
MOBICARD_SECRET_KEY="NjIwYzEyMDRjNjNjMTdkZTZkMjZhOWNiYjIxNzI2NDQwYzVmNWNiMzRhMzBjYSJ9"
MOBICARD_TOKEN_ID=$(shuf -i 1000000-1000000000 -n 1)
MOBICARD_TXN_REFERENCE=$(shuf -i 1000000-1000000000 -n 1)
MOBICARD_SERVICE_ID="20000"
MOBICARD_SERVICE_TYPE="2"
MOBICARD_EXTRA_DATA="your_custom_data_here_will_be_returned_as_is"

# Convert image to base64
SCANNED_CARD_PHOTO_PATH="/path/to/your/card_image.jpg"
# OR use a URL
# SCANNED_CARD_PHOTO_PATH="https://mobicardsystems.com/scan_card_photo_one.jpg"
MOBICARD_SCAN_CARD_PHOTO_BASE64=$(base64 -w0 "$SCANNED_CARD_PHOTO_PATH")

# Create JWT Header
JWT_HEADER=$(echo -n '{"typ":"JWT","alg":"HS256"}' | base64 | tr '+/' '-_' | tr -d '=')

# Create JWT Payload
PAYLOAD_JSON=$(cat << EOF
{
  "mobicard_version": "$MOBICARD_VERSION",
  "mobicard_mode": "$MOBICARD_MODE",
  "mobicard_merchant_id": "$MOBICARD_MERCHANT_ID",
  "mobicard_api_key": "$MOBICARD_API_KEY",
  "mobicard_service_id": "$MOBICARD_SERVICE_ID",
  "mobicard_service_type": "$MOBICARD_SERVICE_TYPE",
  "mobicard_token_id": "$MOBICARD_TOKEN_ID",
  "mobicard_txn_reference": "$MOBICARD_TXN_REFERENCE",
  "mobicard_scan_card_photo_base64_string": "$MOBICARD_SCAN_CARD_PHOTO_BASE64",
  "mobicard_extra_data": "$MOBICARD_EXTRA_DATA"
}
EOF
)

JWT_PAYLOAD=$(echo -n "$PAYLOAD_JSON" | base64 | tr '+/' '-_' | tr -d '=')

# Generate Signature
HEADER_PAYLOAD="$JWT_HEADER.$JWT_PAYLOAD"
JWT_SIGNATURE=$(echo -n "$HEADER_PAYLOAD" | openssl dgst -sha256 -hmac "$MOBICARD_SECRET_KEY" -binary | base64 | tr '+/' '-_' | tr -d '=')

# Create Final JWT
MOBICARD_AUTH_JWT="$JWT_HEADER.$JWT_PAYLOAD.$JWT_SIGNATURE"

# Make API Call
API_URL="https://mobicardsystems.com/api/v1/card_scan"

RESPONSE=$(curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"mobicard_auth_jwt\":\"$MOBICARD_AUTH_JWT\"}" \
  --silent)

# Parse and display response
echo "$RESPONSE" | python -m json.tool

# Check response status
if echo "$RESPONSE" | grep -q '"status":"SUCCESS"'; then
    echo "Scan successful!"
    
    # Extract specific fields
    CARD_NUMBER=$(echo "$RESPONSE" | grep -o '"card_number":"[^"]*"' | cut -d'"' -f4)
    CARD_EXPIRY=$(echo "$RESPONSE" | grep -o '"card_expiry_date":"[^"]*"' | cut -d'"' -f4)
    CARD_BRAND=$(echo "$RESPONSE" | grep -o '"card_brand":"[^"]*"' | cut -d'"' -f4)
    
    echo "Card Number: $CARD_NUMBER"
    echo "Expiry Date: $CARD_EXPIRY"
    echo "Card Brand: $CARD_BRAND"
else
    echo "Scan failed!"
    ERROR_MSG=$(echo "$RESPONSE" | grep -o '"status_message":"[^"]*"' | cut -d'"' -f4)
    echo "Error: $ERROR_MSG"
fi
