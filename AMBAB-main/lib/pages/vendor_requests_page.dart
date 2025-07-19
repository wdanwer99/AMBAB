import 'package:agriplant/services/supabase_service.dart';
import 'package:flutter/material.dart';

class VendorRequestsPage extends StatefulWidget {
  const VendorRequestsPage({super.key});

  @override
  State<VendorRequestsPage> createState() => _VendorRequestsPageState();
}

class _VendorRequestsPageState extends State<VendorRequestsPage> {
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = true;
  String _filter = 'All'; // New: filter state

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> vendors = await SupabaseService.getAllVendors();
      setState(() {
        _vendors = vendors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading vendors: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vendors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveVendor(Map<String, dynamic> vendor) async {
    try {
      await SupabaseService.approveVendor(vendor['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vendor ${vendor['name']} approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadVendors();
    } catch (e) {
      print('Error approving vendor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving vendor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectVendor(Map<String, dynamic> vendor) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Vendor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    if (reason != null && reason.isNotEmpty) {
      try {
        await SupabaseService.rejectVendor(vendor['id'], reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vendor ${vendor['name']} rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _loadVendors();
      } catch (e) {
        print('Error rejecting vendor: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting vendor: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<Map<String, dynamic>> get _filteredVendors {
    if (_filter == 'All') return _vendors;
    return _vendors.where((v) => (v['approval_status'] ?? '').toString().toLowerCase() == _filter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors Management'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVendors,
            tooltip: 'Refresh Vendors',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('pending'),
                const SizedBox(width: 8),
                _buildFilterChip('approved'),
                const SizedBox(width: 8),
                _buildFilterChip('rejected'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVendors.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredVendors.length,
                        itemBuilder: (context, index) {
                          final vendor = _filteredVendors[index];
                          return _buildVendorRequestCard(vendor);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return ChoiceChip(
      label: Text(label[0].toUpperCase() + label.substring(1)),
      selected: _filter == label,
      onSelected: (selected) {
        setState(() {
          _filter = label;
        });
      },
      selectedColor: Colors.green.shade200,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Colors.green.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Pending Requests',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'All vendor requests have been processed',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'All caught up!',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorRequestCard(Map<String, dynamic> vendor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with store name and date
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.green.shade100,
                  child: Icon(
                    Icons.store,
                    color: Colors.green.shade700,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor['store_name'] ?? 'Unknown Store',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Requested on: ${_formatDate(vendor['created_at'])}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PENDING',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Vendor details
            _buildDetailRow('Vendor Name', vendor['name'] ?? 'N/A'),
            _buildDetailRow('Email', vendor['email'] ?? 'N/A'),
            _buildDetailRow('Phone', vendor['phone']?.toString() ?? 'N/A'),
            _buildDetailRow('Location', vendor['location'] ?? 'N/A'),
            _buildDetailRow('Store Description', vendor['store_description'] ?? 'N/A'),
            
            const SizedBox(height: 16),
            
                            // Action buttons
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveVendor(vendor),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Approve',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectVendor(vendor),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text(
                          'Reject',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          vendor['is_disabled'] == true ? Icons.check_circle : Icons.block,
                          color: vendor['is_disabled'] == true ? Colors.green : Colors.orange,
                        ),
                        label: Text(
                          vendor['is_disabled'] == true ? 'Enable' : 'Disable',
                          style: TextStyle(
                            color: vendor['is_disabled'] == true ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          if (vendor['is_disabled'] == true) {
                            _enableVendor(vendor);
                          } else {
                            _disableVendor(vendor);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: vendor['is_disabled'] == true ? Colors.green.shade400 : Colors.orange.shade400,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
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

  Future<void> _disableVendor(Map<String, dynamic> vendor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Vendor'),
        content: Text('Are you sure you want to disable vendor "${vendor['store_name'] ?? vendor['name']}"? This will also delete all their products from the shopping page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await SupabaseService.disableVendor(vendor['id']);
        await SupabaseService.deleteAllProductsForVendor(vendor['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vendor and all their products have been disabled/deleted.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _loadVendors();
      } catch (e) {
        print('Error disabling vendor: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error disabling vendor: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _enableVendor(Map<String, dynamic> vendor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Vendor'),
        content: Text('Are you sure you want to enable vendor "${vendor['store_name'] ?? vendor['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await SupabaseService.enableVendor(vendor['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vendor account has been enabled.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadVendors();
      } catch (e) {
        print('Error enabling vendor: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error enabling vendor: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
} 