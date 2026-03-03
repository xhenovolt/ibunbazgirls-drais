# AFRICASTALKING SDK Integration Guide

## Overview
The system now uses the official **AFRICASTALKING SDK** for Node.js/TypeScript instead of raw HTTP requests. This provides better reliability, detailed response handling, and follows official best practices.

## SDK Details

**Package:** `africastalking`
**Version:** ^0.7.7
**Status:** ✅ Installed and integrated

## Key Components

### 1. Official SDK Utility (`src/lib/africastalking.ts`)

The utility provides a clean wrapper around the AFRICASTALKING SDK:

```typescript
import { sendSMS, normalizePhoneNumber, logSMSActivity } from '@/lib/africastalking';

// Send SMS
const result = await sendSMS(
  phoneNumber,
  message,
  recipientName?,
  shortCode?
);
```

### 2. SMS API Endpoint (`src/app/api/sms/send/route.ts`)

**Endpoint:** `POST /api/sms/send`

**Request:**
```json
{
  "phone": "0700327471",
  "message": "Your message here",
  "recipient_name": "John Doe",
  "short_code": "DRAIS"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "SMS sent successfully to John Doe",
  "data": {
    "messageId": "ATXid_...",
    "status": "Success",
    "cost": "KES 0.80",
    "phone": "+254700327471",
    "recipientName": "John Doe",
    "sentAt": "2026-03-03T10:30:45.000Z"
  }
}
```

**Response (Error - No Credentials):**
```json
{
  "success": false,
  "error": "SMS service not configured"
}
```

## Setup Instructions

### Step 1: Get AFRICASTALKING Credentials

1. Visit https://africastalking.com
2. Create a free account or log in
3. Navigate to your **App Settings** (Dashboard → Your Apps)
4. Copy your:
   - **Username** (App Name)
   - **API Key** (Authentication Token)

### Step 2: Update `.env.local`

Add these environment variables:

```dotenv
# AFRICASTALKING SMS Integration
# Get credentials from https://africastalking.com/sms/api
AFRICASTALKING_USERNAME=your_username_here
AFRICASTALKING_API_KEY=your_api_key_here
```

**Example with Real Credentials:**
```dotenv
AFRICASTALKING_USERNAME=xhenovolt
AFRICASTALKING_API_KEY=atsk_3baf21e161cca165c4f5ccb67bc38f5a50a192e3208fafc3b575014f35793d9a
```

### Step 3: Restart Development Server

```bash
npm run dev
```

### Step 4: Test SMS Sending

```bash
curl -X POST "http://localhost:3000/api/sms/send" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+254700327471",
    "message": "Test message from DRAIS",
    "recipient_name": "Test User"
  }' | jq '.'
```

## Supported Regions

The SDK and phone number validation support these countries:

| Country | Country Code | Format | Example |
|---------|--------------|--------|---------|
| Uganda | +256 | 0700327471 | +256700327471 |
| Kenya | +254 | 0700327471 | +254700327471 |
| Tanzania | +255 | 0700327471 | +255700327471 |
| South Africa | +27 | 0700327471 | +27700327471 |
| Rwanda | +250 | 0700327471 | +250700327471 |
| Nigeria | +234 | 0700327471 | +234700327471 |

### Phone Number Formats

The system automatically normalizes phone numbers:

| Input | Normalized | Status |
|-------|-----------|--------|
| 0700327471 | +256700327471 | ✅ Valid |
| 256700327471 | +256700327471 | ✅ Valid |
| +256700327471 | +256700327471 | ✅ Valid |
| 700327471 | Invalid | ❌ Ambiguous |

## SDK Response Format

### Successful SMS Response

```typescript
interface SMSResponse {
  success: true;
  messageId: string;        // AFRICASTALKING message ID
  status: 'Success';        // Message status
  cost: string;             // SMS cost (e.g., "KES 0.80")
  phone: string;            // Normalized phone number
  recipientName?: string;   // Recipient name if provided
  details: {
    statusCode: string;     // AFRICASTALKING status
    sentAt: string;         // ISO timestamp
  };
}
```

### Failed SMS Response

```typescript
interface SMSResponse {
  success: false;
  error: string;            // Error message
  details?: {
    // AFRICASTALKING response details
  };
}
```

## API Features

### 1. Automatic Phone Normalization
- Converts `0700327471` → `+256700327471`
- Handles multiple formats automatically
- Validates against E.164 international standard

### 2. Message Validation
- Required fields: phone, message
- Max message length: 480 characters (3 SMS)
- Empty message validation
- Character count validation

### 3. Error Handling
- Missing credentials → Graceful error
- Invalid phone format → Clear error message
- Mission too long → Specific error
- SDK errors → Detailed error logs

### 4. Activity Logging
- Logs all SMS attempts (sent/failed)
- Includes timestamp, phone, status, message length
- Useful for debugging and audit trails

## Difference from Previous Implementation

### Previous (HTTP Request)
```javascript
// Made raw HTTP requests
const response = await fetch('https://api.sandbox.africastalking.com/...', {
  headers: { 'Authorization': `Bearer ${apiKey}` }
});
```

### Current (Official SDK)
```javascript
// Uses official SDK
const AfricasTalkingInstance = AfricasTalking({
  apiKey,
  username
});
const sms = AfricasTalkingInstance.SMS;
const result = await sms.send({ to: [...], message });
```

**Benefits:**
- ✅ Official support and maintenance
- ✅ Better error handling
- ✅ More detailed response data
- ✅ Automatic response parsing
- ✅ Built-in retries and reliability
- ✅ Type-safe responses

## Production Deployment

### Before Going Live

1. **Test with Sandbox Credentials**
   ```
   AFRICASTALKING_USERNAME=sandbox
   AFRICASTALKING_API_KEY=your_sandbox_key
   ```

2. **Verify Phone Numbers**
   - Test with real phone numbers in your region
   - Confirm message delivery
   - Monitor response times

3. **Check Pricing**
   - Visit AFRICASTALKING dashboard
   - Check SMS rates for your region
   - Set spending limits if needed

4. **Set Production Credentials**
   ```
   AFRICASTALKING_USERNAME=your_production_app
   AFRICASTALKING_API_KEY=your_production_api_key
   ```

5. **Monitor Costs**
   - SMS pricing varies by region
   - Example Uganda: ~0.07 USD per SMS
   - Check billing dashboard regularly

## Rate Limits

AFRICASTALKING typically supports:
- **Up to 100+ SMS/second** (varies by plan)
- **Burst capacity:** Depends on account tier
- **Throttling:** Adaptive based on queue

## SMS Costs

**Approximate Costs (verify on dashboard):**
- Uganda: UGX 200-300 per SMS (~0.05-0.08 USD)
- Kenya: KES 10-15 per SMS (~0.07-0.10 USD)
- Tanzania: TZS 200-300 per SMS (~0.08-0.12 USD)
- South Africa: ZAR 0.50-1.00 per SMS (~0.03-0.06 USD)

## Troubleshooting

### "SMS service not configured"
**Problem:** Environment variables not set correctly
**Solution:** 
1. Verify `.env.local` has both variables
2. Check variable names (case-sensitive)
3. Restart dev server
4. Check `echo $AFRICASTALKING_USERNAME`

### "Invalid phone number format"
**Problem:** Phone number doesn't match E.164 format
**Solution:**
1. Use format: `+256700327471` or `0700327471`
2. Ensure correct country code (+256 for Uganda)
3. 9 digits after country code

### "Message is too long"
**Problem:** Message exceeds 480 characters
**Solution:**
1. Keep single SMS message ≤160 chars
2. Max 480 chars = 3 SMS messages
3. Truncate or split message

### SDK throws "Unknown error"
**Problem:** Connection or API issues
**Solution:**
1. Check internet connection
2. Verify API credentials
3. Check AFRICASTALKING service status
4. Review server logs for details

## Code Examples

### Example 1: Send Simple SMS
```javascript
const response = await fetch('/api/sms/send', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    phone: '0700327471',
    message: 'Hello World',
    recipient_name: 'Student'
  })
});
const data = await response.json();
```

### Example 2: Send with Short Code
```javascript
const response = await fetch('/api/sms/send', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    phone: '+256700327471',
    message: 'Important school update',
    recipient_name: 'Parent',
    short_code: 'SCHOOL'  // Custom sender ID
  })
});
```

### Example 3: Handle Response
```javascript
const response = await fetch('/api/sms/send', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    phone: '0700327471',
    message: 'Test message',
    recipient_name: 'Test'
  })
});

const result = await response.json();

if (result.success) {
  console.log('SMS sent!');
  console.log('Message ID:', result.data.messageId);
  console.log('Cost:', result.data.cost);
} else {
  console.error('SMS failed:', result.error);
}
```

## Database Logging (Optional)

To store SMS history in database:

```sql
CREATE TABLE sms_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  phone VARCHAR(20) NOT NULL,
  message TEXT NOT NULL,
  recipient_name VARCHAR(100),
  message_id VARCHAR(100),
  status VARCHAR(20),
  cost VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## API Limits by Plan

**Free Tier:**
- Limited SMS/month
- Sandbox API only
- Good for development

**Production Tier:**
- Pay-as-you-go pricing
- Full production API
- Unlimited SMS
- Premium support

## References

- **Official SDK Docs:** https://github.com/AfricasTalkingLtd/africastalking-node.js
- **AFRICASTALKING Dashboard:** https://africastalking.com
- **API Documentation:** https://africastalking.com/sms/api
- **Pricing:** https://africastalking.com/sms

## Support

**For AFRICASTALKING Issues:**
- Email: support@africastalking.com
- Dashboard: Check account notifications
- Status: https://status.africastalking.com

**For Application Issues:**
- Check server logs
- Verify credentials in `.env.local`
- Test with curl commands above
- Review error messages in response

---

**Last Updated:** March 3, 2026
**SDK Version:** 0.7.7
**Status:** ✅ Production Ready
