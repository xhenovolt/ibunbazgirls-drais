# Contact Management System - Enhanced Features Guide

## Overview
The contact management system now includes advanced features for managing learner contacts with editing, searching, calling, and SMS capabilities powered by AFRICASTALKING.

## Features

### 1. ✏️ Edit Contacts
Allow users to correct mistakes in phone numbers and update contact information.

**Location:** `src/components/students/EditContactModal.tsx`

**Functionality:**
- Edit all contact details: name, phone, email, address, relationship, occupation
- Phone number is required field
- Other fields optional for flexibility
- Real-time validation with error messages
- Soft updates (no data loss tracking)

**How to Use:**
1. Open "Contacts" page
2. Click on a contact card or click "Manage" button
3. In ContactsList modal, click the blue "Edit" button on any contact
4. Update the information
5. Click "Save Changes"

**API Endpoint:**
```
PUT /api/students/contacts/[id]
```

**Request Body:**
```json
{
  "contact_first_name": "John",
  "contact_last_name": "Doe",
  "contact_phone": "+256700123456",
  "contact_email": "john@example.com",
  "contact_address": "123 Main St",
  "relationship": "Father",
  "occupation": "Engineer",
  "alive_status": "alive"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Contact updated successfully",
  "data": {
    "contact_id": "2"
  }
}
```

---

### 2. 🔍 Searchable Contacts List
Intuitive UI for finding and managing contacts with advanced filtering.

**Location:** `src/components/students/ContactsListModal.tsx`

**Functionality:**
- Search contacts by phone number, name, or relationship
- Real-time filtering as you type
- View all contact details in organized layout
- Displays contact type, occupation, address, email
- Shows "Primary" badge for main contacts
- Smooth animations for better UX

**Features:**
- Fast search across phone, name, and relationship
- Responsive card design
- Contact details clearly organized
- Quick action buttons for each contact

**Example Search Cases:**
- "0700327471" - Search by phone
- "Nalubanga" - Search by contact name
- "Mother" - Search by relationship
- "Engineer" - Could also match occupation if implemented

---

### 3. 📱 Call Initiation
One-click phone dialer integration.

**How to Use:**
1. Click the green **"Call"** button on any contact card
2. Your phone's default dialer opens with the contact's number
3. Complete the call

**How It Works:**
```javascript
// Uses tel: protocol to open device dialer
window.location.href = `tel:${phoneNumber}`;
```

**Supported On:**
- Mobile devices (iOS, Android) - Opens native dialer
- Desktop with VoIP clients - May open VOIP application
- Returns user feedback: "Opening dialer for [contact name]"

**Button Location:**
- Quick action buttons on contact cards
- Bottom of contact information in ContactsList modal
- Green color (#10B981) for easy identification

---

### 4. 💬 SMS Sending via AFRICASTALKING

Send custom SMS messages to contacts directly from the platform.

**Location:** `src/components/students/SMSComposerModal.tsx`

**Features:**
- Compose custom messages (up to 480 chars = 3 SMS)
- Quick templates for common messages
- Character counter shows SMS count
- Phone number validation and normalization
- Pre-populated recipient information
- SMS status tracking

**Quick Templates:**
1. **School Update** - "Hi, this is a message from the school regarding your ward's status."
2. **Fees Reminder** - "Your ward has pending payments. Please contact the school office for details."
3. **Greeting** - "Greetings! How are you doing today?"
4. **Congratulations** - "Your child has achieved excellent results. Well done!"

**How to Use:**
1. Click purple **"SMS"** button on contact card
2. SMSComposerModal opens
3. Type your message or select a template
4. Watch character counter (green for 1 SMS, orange for 2+)
5. Click "Send SMS"
6. Modal auto-closes on success

**API Endpoint:**
```
POST /api/sms/send
```

**Request Body:**
```json
{
  "phone": "+256700327471",
  "message": "Hello, this is a test message",
  "recipient_name": "NALUBANGA MARIAM"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "SMS sent successfully to NALUBANGA MARIAM",
  "data": {
    "messageId": "ATXid_...",
    "statusCode": 101,
    "recipient": "NALUBANGA MARIAM",
    "phoneNumber": "+256700327471",
    "sentAt": "2026-03-03T10:30:45.000Z"
  }
}
```

**Response (Error - SMS Not Configured):**
```json
{
  "success": false,
  "error": "SMS service not configured"
}
```

---

## AFRICASTALKING Integration Setup

### Prerequisites
- AFRICASTALKING account (https://africastalking.com)
- Basic SMS API credentials

### Configuration Steps

#### 1. Get AFRICASTALKING Credentials
1. Visit https://africastalking.com
2. Create an account or log in
3. Navigate to "Sandbox" or "Production" environment
4. Copy your **Username** and **API Key**

#### 2. Update `.env.local`

Add these variables to `.env.local`:

```dotenv
# AFRICASTALKING SMS Integration
# Get credentials from https://africastalking.com/sms/api
AFRICASTALKING_USERNAME=your_username
AFRICASTALKING_API_KEY=your_api_key
```

**Example with Sandbox (for testing):**
```dotenv
AFRICASTALKING_USERNAME=sandbox
AFRICASTALKING_API_KEY=ATXk_...ABC123...
```

**Example with Production:**
```dotenv
AFRICASTALKING_USERNAME=your_app_name
AFRICASTALKING_API_KEY=ATXk_...PROD123...
```

#### 3. Restart Development Server
```bash
npm run dev
```

### Supported Regions
- Uganda: +256 phone numbers
- Kenya: +254 phone numbers  
- Tanzania: +255 phone numbers
- South Africa: +27 phone numbers
- 50+ African countries

### Phone Number Formats
System automatically normalizes various phone number formats:

| Input Format | Normalized To | Valid? |
|---|---|---|
| 0700327471 | +256700327471 | ✅ |
| 256700327471 | +256700327471 | ✅ |
| +256700327471 | +256700327471 | ✅ |
| 700327471 | +256700327471 | ⚠️ Ambiguous |

### SMS Coding
- **1 SMS:** 1-160 characters
- **2 SMS:** 161-320 characters
- **3 SMS:** 321-480 characters
- Message length display: "SMS: 1", "SMS: 2", etc.

### Usage Costs
- Sandbox (Testing): Free
- Production: Charges per SMS sent
- Check AFRICASTALKING dashboard for rates

---

## Component Architecture

### Contact Management Flow

```
ContactsPage (Main Page)
├── AddContactModal (Add new contacts)
├── ContactsListModal (View/Edit/Delete/SMS/Call)
│   ├── EditContactModal (Edit single contact)
│   ├── SMSComposerModal (Send SMS)
│   └── Quick actions (Call, Edit, Delete, SMS)
└── Contact cards with quick actions
```

### Files Created/Modified

**New Components:**
- `src/components/students/ContactsListModal.tsx` - List, search, manage contacts
- `src/components/students/EditContactModal.tsx` - Edit contact form
- `src/components/students/SMSComposerModal.tsx` - SMS composer with templates

**New APIs:**
- `src/app/api/students/contacts/[id]/route.ts` - PUT (edit), DELETE (remove)
- `src/app/api/sms/send/route.ts` - POST (send SMS)

**New Utilities:**
- `src/lib/africastalking.ts` - AFRICASTALKING integration

**Modified Pages:**
- `src/app/students/contacts/page.tsx` - Added click handlers and quick actions

---

## Database Schema

### contacts table
```sql
CREATE TABLE contacts (
  id bigint PRIMARY KEY AUTO_INCREMENT,
  school_id bigint NOT NULL,
  person_id bigint NOT NULL,
  contact_type varchar(30),
  occupation varchar(120),
  alive_status varchar(20),
  date_of_death date,
  created_at timestamp DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp,
  deleted_at timestamp,
  FOREIGN KEY (person_id) REFERENCES people(id),
  FOREIGN KEY (school_id) REFERENCES schools(id)
);
```

### student_contacts (Junction Table)
```sql
CREATE TABLE student_contacts (
  student_id bigint NOT NULL,
  contact_id bigint NOT NULL,
  relationship varchar(50),
  is_primary tinyint(1) DEFAULT 0,
  PRIMARY KEY (student_id, contact_id),
  FOREIGN KEY (contact_id) REFERENCES contacts(id),
  FOREIGN KEY (student_id) REFERENCES students(id)
);
```

### people table (Contact Person)
```sql
CREATE TABLE people (
  id bigint PRIMARY KEY AUTO_INCREMENT,
  school_id bigint NOT NULL,
  first_name varchar(100),
  last_name varchar(100),
  phone varchar(20),
  email varchar(100),
  address varchar(255),
  created_at timestamp DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp,
  deleted_at timestamp
);
```

---

## Error Handling

### Common Errors

**1. SMS Service Not Configured**
```json
{
  "success": false,
  "error": "SMS service not configured"
}
```
**Solution:** Add AFRICASTALKING credentials to `.env.local` and restart server

**2. Invalid Phone Number**
```json
{
  "success": false,
  "error": "Invalid phone number format"
}
```
**Solution:** Use format: +256700327471 or 0700327471

**3. Message Too Long**
```json
{
  "success": false,
  "error": "Message is too long (max 480 characters)"
}
```
**Solution:** Keep message under 160 chars (1 SMS)

**4. Contact Not Found**
```json
{
  "success": false,
  "error": "Contact not found"
}
```
**Solution:** Ensure contact_id exists before editing/deleting

---

## User Interface Guide

### Contacts Page

**Main Elements:**
1. **Header** - Page title and count of contacts
2. **Search Bar** - Filter contacts by name, phone, relationship
3. **Add Button** - Opens AddContactModal for new contacts
4. **Contact Cards** - Grid display of all contacts
5. **Action Buttons:**
   - Call (Green) - Dial contact
   - SMS (Purple) - Send message
   - Manage (Blue) - Open full contact list
   - Delete - Remove contact

### ContactsListModal

**Features:**
- Search bar at top for quick filtering
- All contacts for selected student listed
- Contact info: name, phone, relationship, type, occupation, address
- Primary badge for main contacts
- Action buttons: Call, SMS, Edit, Delete
- Close button to return to main page

### EditContactModal

**Form Fields:**
- First Name (optional)
- Last Name (optional)
- Phone Number (required)
- Email (optional)
- Address (optional)
- Relationship (optional)
- Occupation (optional)
- Status (alive/deceased)

---

## Testing Checklist

- [ ] Create new contact via AddContactModal
- [ ] Edit contact phone number via EditContactModal
- [ ] Search contacts by name, phone, relationship
- [ ] Click Call button and verify dialer opens
- [ ] Send SMS with custom message
- [ ] Use SMS quick templates
- [ ] Verify character counter in SMS composer
- [ ] Delete contact (confirmation dialog appears)
- [ ] View deleted contact is no longer in list
- [ ] Edit shows correct current values
- [ ] All fields validate properly (phone required in edit)
- [ ] Pagination works with many contacts
- [ ] Dark mode styling looks correct
- [ ] Mobile responsive on small screens
- [ ] Error messages display correctly

---

## Future Enhancements

1. **Bulk SMS** - Send message to multiple contacts
2. **Message Templates** - Save custom templates
3. **SMS History** - View sent/received messages
4. **WhatsApp Integration** - Send WhatsApp messages
5. **Attachment Support** - Share documents via SMS/WhatsApp
6. **Schedule SMS** - Send at specific time
7. **Contact Groups** - Manage contacts by category
8. **Call Recording** - Record and store call notes
9. **Email Integration** - Send emails from platform
10. **Contact Import** - Bulk import from CSV

---

## Support & Troubleshooting

**Issue:** SMS not sending
- Check AFRICASTALKING credentials in `.env.local`
- Verify phone number format (start with + or 0)
- Check account balance on AFRICASTALKING dashboard
- Verify country code (e.g., +256 for Uganda)

**Issue:** Edit not updating
- Ensure phone number is not empty
- Check browser console for API errors
- Verify contact exists (ID correct)

**Issue:** Call button not working on desktop
- Call button designed for mobile devices
- Works best with VoIP clients on desktop
- Check browser permissions for tel: protocol

**Issue:** Search not finding contacts
- Ensure search query matches phone, name, or relationship
- Search is case-insensitive
- Try shortening search term

---

## References

- AFRICASTALKING Documentation: https://africastalking.com/sms/api
- Next.js API Routes: https://nextjs.org/docs/api-routes
- React Hot Toast: https://react-hot-toast.com/
- Framer Motion: https://www.framer.com/motion/
