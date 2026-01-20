import 'package:flutter/material.dart';

/// Driver documents management page
/// Shows document upload status and allows uploading/re-uploading documents
class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Verification status banner
          _buildVerificationBanner(context),
          const SizedBox(height: 24),
          
          // Required documents section
          _buildSectionHeader('Required Documents'),
          const SizedBox(height: 12),
          _buildDocumentItem(
            context,
            icon: Icons.person,
            title: 'Profile Photo',
            status: 'pending',
          ),
          _buildDocumentItem(
            context,
            icon: Icons.credit_card,
            title: 'CNIC (Front)',
            status: 'approved',
          ),
          _buildDocumentItem(
            context,
            icon: Icons.credit_card_outlined,
            title: 'CNIC (Back)',
            status: 'approved',
          ),
          _buildDocumentItem(
            context,
            icon: Icons.badge,
            title: 'Driving License (Front)',
            status: 'not_uploaded',
          ),
          _buildDocumentItem(
            context,
            icon: Icons.badge_outlined,
            title: 'Driving License (Back)',
            status: 'not_uploaded',
          ),
          _buildDocumentItem(
            context,
            icon: Icons.directions_car,
            title: 'Vehicle Registration',
            status: 'rejected',
            rejectionReason: 'Image is blurry, please upload a clear photo',
          ),
          
          const SizedBox(height: 24),
          
          // Optional documents section
          _buildSectionHeader('Optional Documents'),
          const SizedBox(height: 12),
          _buildDocumentItem(
            context,
            icon: Icons.shield,
            title: 'Vehicle Insurance',
            status: 'not_uploaded',
            isOptional: true,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner(BuildContext context) {
    // TODO: Get actual verification status from BLoC
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.pending, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please upload all required documents to start accepting rides.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDocumentItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String status,
    String? rejectionReason,
    bool isOptional = false,
  }) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending Review';
        statusIcon = Icons.schedule;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Not Uploaded';
        statusIcon = Icons.upload;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to document upload page
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isOptional)
                          Text(
                            'Optional',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              if (rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rejectionReason,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
