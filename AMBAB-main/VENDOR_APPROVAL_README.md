# Vendor Approval System

This document describes the vendor approval system implemented in the multi-vendor agriculture app.

## Overview

The vendor approval system ensures that only verified vendors can sell products on the platform. When a user registers as a vendor, their application goes through an admin approval process before they can access vendor features.

## Features

### For Vendors
- **Application Process**: Vendors register with store details and wait for admin approval
- **Status Tracking**: Real-time status updates (Pending, Approved, Rejected)
- **Rejection Handling**: Clear feedback when applications are rejected
- **Reapplication**: Ability to apply again after rejection

### For Admins
- **Request Management**: Dedicated page to view and manage vendor requests
- **Approval/Rejection**: Easy approval or rejection with reason tracking
- **Bulk Operations**: View all pending requests in one place
- **Status Updates**: Automatic role updates when vendors are approved

### For the System
- **Security**: Only approved vendors can access vendor features
- **Data Integrity**: Proper validation and status tracking
- **Audit Trail**: Timestamps for all approval actions

## Workflow

### 1. Vendor Registration
```
User registers as vendor → Account created with 'pending' status → Redirected to home page
```

### 2. Admin Review
```
Admin views vendor requests → Reviews application details → Approves or rejects with reason
```

### 3. Status Updates
```
If Approved: Role updated to 'vendor' → Access to vendor dashboard
If Rejected: Status updated to 'rejected' → Can reapply
```

## Database Schema

### Vendors Table
- `is_approved`: Boolean flag for approval status
- `approval_status`: Text field ('pending', 'approved', 'rejected')
- `approved_at`: Timestamp when approved
- `rejected_at`: Timestamp when rejected
- `rejection_reason`: Text field for rejection feedback

### Users Table
- `role`: Updated to 'vendor' when approved
- `updated_at`: Timestamp for role changes

## Implementation Details

### API Methods
- `SupabaseService.getPendingVendorRequests()`: Get all pending vendor applications
- `SupabaseService.approveVendor()`: Approve a vendor and update their role
- `SupabaseService.rejectVendor()`: Reject a vendor with reason
- `SupabaseService.isVendorApproved()`: Check if vendor is approved

### UI Components
- **VendorRequestsPage**: Admin interface for managing requests
- **VendorPendingApprovalPage**: Vendor interface while waiting for approval
- **AuthWrapper**: Routes users based on role and approval status

### Security Features
- **RLS Policies**: Proper access control for vendor data
- **Role Validation**: Only admins can change approval status
- **Status Validation**: Prevents invalid status transitions

## Setup Instructions

### 1. Database Setup
Run the SQL script to set up the approval system:

```sql
-- Execute the vendor_approval_setup.sql file in your Supabase SQL editor
```

### 2. Verify Database Structure
Ensure the following columns exist in the vendors table:
- `is_approved` (BOOLEAN)
- `approval_status` (TEXT)
- `approved_at` (TIMESTAMP)
- `rejected_at` (TIMESTAMP)
- `rejection_reason` (TEXT)

### 3. Test the Workflow
1. Register a new vendor account
2. Check that they see the pending approval page
3. Login as admin and approve the vendor
4. Verify the vendor can now access the dashboard

## User Experience

### Vendor Registration Flow
1. User selects "Vendor" account type during signup
2. Fills in store details (name, description, etc.)
3. Account created with pending status
4. Redirected to home page with approval message
5. Can check status or wait for admin approval

### Admin Approval Flow
1. Admin navigates to "Vendor Requests" page
2. Views list of pending applications
3. Reviews vendor details and store information
4. Approves or rejects with optional reason
5. System automatically updates vendor status and role

### Vendor Dashboard Access
1. Vendor logs in after approval
2. AuthWrapper checks approval status
3. If approved: Access to vendor dashboard
4. If pending/rejected: Redirected to approval status page

## Error Handling

### Common Scenarios
- **Unauthorized Access**: Vendors without approval cannot access vendor features
- **Invalid Status Changes**: Only admins can change approval status
- **Missing Data**: Proper validation for required vendor information

### Error Messages
- "Please wait for admin approval" - For pending vendors
- "Application rejected" - For rejected vendors with reason
- "Only admins can change vendor approval status" - Security validation

## Security Considerations

### Access Control
- Vendors can only view their own data
- Admins can view and update all vendor data
- Approval status changes are restricted to admins only

### Data Validation
- Required fields validation during registration
- Status transition validation
- Role update validation

### Audit Trail
- Timestamps for all approval actions
- Rejection reasons for transparency
- User role change tracking

## Future Enhancements

### Potential Improvements
1. **Email Notifications**: Send approval/rejection emails to vendors
2. **Document Upload**: Allow vendors to upload business documents
3. **Approval Criteria**: Configurable approval requirements
4. **Bulk Operations**: Approve/reject multiple vendors at once
5. **Approval History**: Track all approval actions with admin details

### Technical Improvements
1. **Real-time Updates**: WebSocket notifications for status changes
2. **Push Notifications**: Mobile notifications for approval status
3. **Analytics**: Track approval rates and processing times
4. **Automated Screening**: Basic automated checks before admin review

## Troubleshooting

### Common Issues
1. **Vendor cannot access dashboard**: Check approval status in database
2. **Admin cannot see requests**: Verify RLS policies are active
3. **Status not updating**: Check database triggers and permissions
4. **Role not changing**: Verify user table update permissions

### Debug Steps
1. Check vendor approval status in Supabase dashboard
2. Verify RLS policies are correctly applied
3. Review database logs for trigger errors
4. Test admin permissions and role validation

## Conclusion

The vendor approval system provides a secure and user-friendly way to manage vendor onboarding. It ensures quality control while maintaining transparency and providing clear feedback to applicants. The system is scalable and can be extended with additional features as needed. 