# Quick Reference: Contact Management System Setup

## 🚀 Get Started in 3 Steps

### Step 1: Add AFRICASTALKING Credentials (2 minutes)

**Get credentials:**
1. Go to https://africastalking.com
2. Create free account
3. Copy Username and API Key

**Update `.env.local`:**
```dotenv
AFRICASTALKING_USERNAME=your_username_here
AFRICASTALKING_API_KEY=your_api_key_here
```

**Example:**
```dotenv
AFRICASTALKING_USERNAME=xhenovolt
AFRICASTALKING_API_KEY=atsk_3baf21e161cca165c4f5ccb67bc38f5a50a192e3208fafc3b575014f...
```

### Step 2: Restart Server (30 seconds)

```bash
npm run dev
```

### Step 3: Test SMS (1 minute)

```bash
curl -X POST "http://localhost:3000/api/sms/send" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+256700327471",
    "message": "Hello from DRAIS!",
    "recipient_name": "Test User"
  }' | jq '.'
```

**Expected response:**
```json
{
  "success": true,
  "message": "SMS sent successfully to Test User",
  "data": {
    "messageId": "ATXid_...",
    "status": "Success",
    "cost": "UGX 200",
    "phone": "+256700327471",
    "recipientName": "Test User"
  }
}
```

---

## 📱 Using the Features

### Add Contact
1. Navigate to **Students → Contacts**
2. Click **"Add Contact"** button
3. Search for learner
4. Enter phone number
5. Click **"Save Phone Number"**

### Edit Contact Phone
1. Click contact card
2. **ContactsListModal** opens
3. Click blue **"Edit"** button
4. Change phone number
5. Click **"Save Changes"**

### Send SMS
1. On contact card, click purple **"SMS"** button
2. **SMSComposerModal** opens
3. Type message OR select template
4. Click **"Send SMS"**
5. Toast confirms delivery

### Make Call
1. Click green **"Call"** button on contact
2. Device dialer opens
3. Complete call

### Search Contacts
1. Click **"Manage"** on contact card
2. Type in search box
3. Results filter by phone, name, relationship

---

## 📊 Data Overview

### Contact Table Structure
```sql
contacts:
- id (Primary Key)
- school_id (Foreign Key)
- person_id (Foreign Key to people)
- contact_type (guardian, parent, relative, emergency)
- occupation (optional)
- alive_status (alive, deceased)
- created_at, updated_at, deleted_at
```

### Student-Contact Link
```sql
student_contacts:
- student_id
- contact_id
- relationship (father, mother, uncle, etc)
- is_primary (boolean)
```

---

## 🔗 API Endpoints

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/api/students/contacts` | Create contact | ✅ |
| GET | `/api/students/contacts` | List contacts | ✅ |
| PUT | `/api/students/contacts/[id]` | Update contact | ✅ NEW |
| DELETE | `/api/students/contacts/[id]` | Delete contact | ✅ NEW |
| POST | `/api/sms/send` | Send SMS | ✅ NEW |

---

## 💬 SMS Validation

### Phone Number Format
| Input | Valid? | Result |
|-------|--------|--------|
| 0700327471 | ✅ | Converts to +256700327471 |
| +256700327471 | ✅ | Used as-is |
| 256700327471 | ✅ | Converts to +256700327471 |
| invalid | ❌ | Rejected with error |
| 700327471 | ❌ | Ambiguous - rejected |

### Message Length
- 1-160 chars = 1 SMS ✅
- 161-320 chars = 2 SMS ✅
- 321-480 chars = 3 SMS ✅
- 481+ chars = ERROR ❌

### SMS Templates
```
1. School Update
   → "Hi, this is a message from the school regarding your ward's status."

2. Fees Reminder
   → "Your ward has pending payments. Please contact the school office for details."

3. Greeting
   → "Greetings! How are you doing today?"

4. Congratulations
   → "Your child has achieved excellent results. Well done!"
```

---

## 🔐 Environment Variables

### Required for SMS
```dotenv
AFRICASTALKING_USERNAME=    # Your AFRICASTALKING app name
AFRICASTALKING_API_KEY=     # Your AFRICASTALKING API key
```

### Already Configured
```dotenv
DATABASE_MODE=auto          # TiDB first, MySQL fallback
TIDB_HOST=...               # TiDB Cloud endpoint
TIDB_USER=...               # TiDB credentials
TIDB_PASSWORD=...           # TiDB credentials
```

---

## 🎯 Common Tasks

### Task 1: Fix Phone Number Mistake
```bash
# API Call
curl -X PUT "/api/students/contacts/2" \
  -d '{"contact_phone": "+256700999888"}'

# UI Method
1. Contact Card → Manage
2. Edit button
3. Change phone
4. Save
```

### Task 2: Send Message to 20 Parent Contacts
```
# Currently (manual)
1. For each contact:
   - Open contact
   - Click SMS
   - Send message

# Future (bulk feature)
- Select multiple contacts
- Send to all at once
```

### Task 3: Search for All "Father" Contacts
```
# UI Method
1. Go to Contacts page
2. Search box → Type "father"
3. Filter shows all father contacts
```

### Task 4: Delete Wrong Contact Entry
```bash
# API Call
curl -X DELETE "/api/students/contacts/1"

# UI Method
1. Contact Card → Manage
2. Delete button
3. Confirm deletion
```

### Task 5: Check SMS Cost
```
1. Go to https://africastalking.com/sms
2. Check pricing for your country
3. Uganda: ~UGX 200-300/SMS
4. Kenya: ~KES 10-15/SMS
```

---

## ⚠️ Error Messages & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "SMS service not configured" | No credentials | Add to .env.local & restart |
| "Invalid phone number format" | Wrong format | Use +256700327471 or 0700327471 |
| "Message is too long" | >480 chars | Keep under 480 characters |
| "Phone number and message required" | Missing field | Provide both phone & message |
| "Contact not found" | Wrong ID | Verify contact ID exists |
| API error 500 | Server error | Check server logs |

---

## 📈 Performance Tips

1. **Search:** Filters in real-time, no API calls
2. **Edit:** Only updates changed fields
3. **Delete:** Soft delete, preserves data
4. **SMS:** Throttled to prevent abuse
5. **Contacts:** Cached with SWR (automatic refresh every 30s)

---

## 🔍 Testing Checklist

Run these to verify everything works:

```bash
# Test 1: Get contacts
curl "http://localhost:3000/api/students/contacts?school_id=1&student_id=65" | jq '.data | length'

# Test 2: Edit contact
curl -X PUT "http://localhost:3000/api/students/contacts/1" \
  -H "Content-Type: application/json" \
  -d '{"contact_phone": "0700327471"}' | jq '.success'

# Test 3: SMS API (no credentials)
curl -X POST "http://localhost:3000/api/sms/send" \
  -d '{"phone": "0700327471", "message": "test"}' | jq '.error'

# Test 4: SMS with credentials (after setup)
curl -X POST "http://localhost:3000/api/sms/send" \
  -d '{"phone": "+256700327471", "message": "test", "recipient_name": "user"}' | jq '.success'
```

---

## 📱 Device Support

| Device | Call | SMS | Edit | Search | Status |
|--------|------|-----|------|--------|--------|
| iPhone | ✅ | ✅ | ✅ | ✅ | Full |
| Android | ✅ | ✅ | ✅ | ✅ | Full |
| iPad | ✅ | ✅ | ✅ | ✅ | Full |
| Desktop | ~ | ✅ | ✅ | ✅ | VoIP Only |
| Dark Mode | ✅ | ✅ | ✅ | ✅ | Full |

---

## 💡 Pro Tips

**Tip 1: Use Templates**
- Save time with pre-written messages
- Click template button in SMS composer
- Customize if needed

**Tip 2: Phone Number Formats**
- Accept any format
- System normalizes automatically
- User doesn't need to know E.164

**Tip 3: Monitor SMS Costs**
- Check AFRICASTALKING dashboard weekly
- Set spending limit if needed
- ~200-300 messages per day = ~UGX 50,000-60,000/day

**Tip 4: Dark Mode**
- All components support dark mode
- Automatically follows system setting
- Reduces eye strain at night

**Tip 5: Search is Instant**
- No "Search" button needed
- Type and results appear
- Search by phone, name, relationship

---

## 📚 Complete Documentation

For detailed information, see:
- `CONTACT_MANAGEMENT_ENHANCED_GUIDE.md` - Full feature guide
- `AFRICASTALKING_SDK_SETUP_GUIDE.md` - SDK detailed setup
- `CONTACT_MANAGEMENT_IMPLEMENTATION_SUMMARY.md` - Technical details
- `CONTACT_MANAGEMENT_FINAL_REPORT.md` - Implementation report

---

## 🎓 SWR (Data Fetching)

The system uses SWR for intelligent data fetching:

**What is SWR?**
- Automatic data refreshing
- Caching
- Real-time synchronization
- Error recovery

**How it works:**
```javascript
// Automatically refreshes contacts every 30 seconds
// Caches locally
// Handles errors gracefully
const { data: contacts, mutate } = useSWR(
  '/api/students/contacts?school_id=1',
  fetcher,
  { refreshInterval: 30000 }
);

// Manually refresh on important changes
mutate();
```

---

## 🌍 Supported SMS Regions

**East Africa:**
- Uganda (+256) - UGX 200-300
- Kenya (+254) - KES 10-15
- Tanzania (+255) - TZS 200-300
- Rwanda (+250) - RWF 50-100

**Southern Africa:**
- South Africa (+27) - ZAR 0.50-1.00

**West Africa:**
- Nigeria (+234) - NGN 0.50-1.00
- Ghana (+233) - GHS 0.15-0.25

**North Africa:**
- Egypt (+20) - EGP 1-2
- Morocco (+212) - MAD 5-10

**Plus 40+ other African countries** - Check AFRICASTALKING for full list

---

## 💼 Business Intelligence

### Useful Metrics
```
- Total contacts: SELECT COUNT(*) FROM contacts
- Contacts per student: SELECT student_id, COUNT(*) FROM student_contacts GROUP BY student_id
- SMS sent per day: Check AFRICASTALKING dashboard
- Cost per student notification: Calculate from SMS cost
```

### Example Scenario
```
School with 500 students
Parent contact ratio: 1.5 contacts per student = 750 contacts
Monthly SMS volume: 4 messages per student = 2,000 SMS
Monthly cost (Uganda): 2,000 × UGX 250 = UGX 500,000 (~$130)
Year cost: ~$1,500-2,000
```

---

## 🔐 Security Notes

✅ **What's Secure:**
- Credentials in environment variables only
- Soft deletes preserve data
- Input validation before sending
- Phone number normalization prevents injection
- Error messages don't expose sensitive data

⚠️ **Best Practices:**
- Never hardcode credentials
- Rotate API keys annually
- Monitor AFRICASTALKING account access
- Use HTTPS in production
- Audit SMS logs monthly

---

## 📞 Quick Support

**Having Issues?**
1. Check error message in toast notification
2. Review server logs: `npm run dev` output
3. Test with curl commands above
4. Check AFRICASTALKING dashboard
5. Verify credentials in `.env.local`

**Contact Support:**
- AFRICASTALKING: support@africastalking.com
- Documentation: Full guides in repository

---

## ✅ Pre-Launch Checklist

Before announcing to users:
- [ ] AFRICASTALKING account created
- [ ] Credentials added to `.env.local`
- [ ] Server restarted
- [ ] Test SMS sent successfully
- [ ] Contact edit verified in database
- [ ] SMS templates populated
- [ ] Staff trained on usage
- [ ] Documentation reviewed
- [ ] Error handling tested
- [ ] Dark mode verified
- [ ] Mobile testing done

---

**Last Updated:** March 3, 2026
**Status:** ✅ READY FOR PRODUCTION
**Estimated Setup Time:** 30 minutes
