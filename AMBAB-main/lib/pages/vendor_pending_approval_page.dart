import 'package:agriplant/services/supabase_service.dart';
import 'package:flutter/material.dart';

class VendorPendingApprovalPage extends StatefulWidget {
  const VendorPendingApprovalPage({super.key});

  @override
  State<VendorPendingApprovalPage> createState() => _VendorPendingApprovalPageState();
}

class _VendorPendingApprovalPageState extends State<VendorPendingApprovalPage> {
  Map<String, dynamic>? _vendorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        final vendor = await SupabaseService.getVendor(user.id);
        setState(() {
          _vendorData = vendor;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading vendor data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Approval'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVendorData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPendingApprovalContent(),
    );
  }

  Widget _buildPendingApprovalContent() {
    final approvalStatus = _vendorData?['approval_status'] ?? 'pending';
    final rejectionReason = _vendorData?['rejection_reason'];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: approvalStatus == 'rejected' 
                  ? Colors.red.shade100 
                  : Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              approvalStatus == 'rejected' 
                  ? Icons.cancel 
                  : Icons.schedule,
              size: 60,
              color: approvalStatus == 'rejected' 
                  ? Colors.red 
                  : Colors.orange,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Status Title
          Text(
            approvalStatus == 'rejected' 
                ? 'Application Rejected' 
                : 'Pending Approval',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Status Description
          Text(
            approvalStatus == 'rejected'
                ? 'Your vendor application has been rejected. Please review the reason below and consider applying again.'
                : 'Your vendor application is currently under review by our admin team. This process usually takes 1-2 business days.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Vendor Details Card
          if (_vendorData != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Store Name', _vendorData!['store_name'] ?? 'N/A'),
                    _buildDetailRow('Vendor Name', _vendorData!['name'] ?? 'N/A'),
                    _buildDetailRow('Email', _vendorData!['email'] ?? 'N/A'),
                    _buildDetailRow('Location', _vendorData!['location'] ?? 'N/A'),
                    _buildDetailRow('Phone', _vendorData!['phone']?.toString() ?? 'N/A'),
                    _buildDetailRow('Store Description', _vendorData!['store_description'] ?? 'N/A'),
                    _buildDetailRow('Applied On', _formatDate(_vendorData!['created_at'])),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
          
          // Rejection Reason (if rejected)
          if (approvalStatus == 'rejected' && rejectionReason != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rejection Reason',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rejectionReason,
                    style: TextStyle(
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
          
          // Action Buttons
          if (approvalStatus == 'rejected') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to signup page to reapply
                  Navigator.of(context).pushReplacementNamed('/signup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Apply Again',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadVendorData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Check Status',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    if (timestamp is String) {
      try {
        final date = DateTime.parse(timestamp);
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
      } catch (e) {
        return 'N/A';
      }
    }
    
    return 'N/A';
  }
} 