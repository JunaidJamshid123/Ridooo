import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/services/wallet_service.dart';

/// Clean and simple payment/wallet page for users
class UserPaymentPage extends StatefulWidget {
  const UserPaymentPage({super.key});

  @override
  State<UserPaymentPage> createState() => _UserPaymentPageState();
}

class _UserPaymentPageState extends State<UserPaymentPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  double _walletBalance = 0.0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  late final WalletService _walletService;
  
  // Mock payment methods
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: '1',
      type: PaymentMethodType.wallet,
      name: 'Ridooo Wallet',
      details: 'Rs. 0.00',
      icon: Icons.account_balance_wallet,
      iconColor: Colors.purple,
      isDefault: true,
    ),
    PaymentMethod(
      id: '2',
      type: PaymentMethodType.cash,
      name: 'Cash',
      details: 'Pay driver in cash',
      icon: Icons.money,
      iconColor: Colors.green,
      isDefault: false,
    ),
    PaymentMethod(
      id: '3',
      type: PaymentMethodType.jazzcash,
      name: 'JazzCash',
      details: '+92 300 1234567',
      icon: Icons.phone_android,
      iconColor: Colors.red,
      isDefault: false,
    ),
    PaymentMethod(
      id: '4',
      type: PaymentMethodType.card,
      name: 'Debit Card',
      details: '**** **** **** 4532',
      icon: Icons.credit_card,
      iconColor: Colors.blue,
      isDefault: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _walletService = WalletService(supabaseClient: Supabase.instance.client);
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final wallet = await _walletService.getOrCreateWallet(user.id);
      final transactions = await _walletService.getTransactions(user.id, limit: 10);

      if (mounted) {
        setState(() {
          _walletBalance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
          _transactions = transactions;
          _paymentMethods[0] = _paymentMethods[0].copyWith(
            details: 'Rs. ${_walletBalance.toStringAsFixed(2)}',
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading wallet data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: _showTransactionHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wallet Balance Card
                    _buildWalletCard(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 28),

                    // Payment Methods Section
                    _buildSectionHeader('Payment Methods'),
                    const SizedBox(height: 12),
                    _buildPaymentMethods(),
                  ],
                ),
              ),
            ),
    );
  }

  void _showTransactionHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _transactions.isEmpty
                    ? const Center(child: Text('No transactions yet'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _transactions.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final isCredit = tx['type'] == 'credit';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCredit 
                                  ? Colors.green.shade100 
                                  : Colors.red.shade100,
                              child: Icon(
                                isCredit ? Icons.add : Icons.remove,
                                color: isCredit ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(tx['description'] ?? 'Transaction'),
                            subtitle: Text(
                              DateTime.parse(tx['created_at']).toString().substring(0, 16),
                            ),
                            trailing: Text(
                              '${isCredit ? '+' : '-'}Rs. ${(tx['amount'] as num).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isCredit ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2D2D2D),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Ridooo Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rs. ${_walletBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _showAddMoneyDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Add Money',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: OutlinedButton(
                  onPressed: _showSendMoneyDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Send',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.qr_code_scanner,
            label: 'Scan & Pay',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR Scanner opening...')),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.receipt_long,
            label: 'Pay Bills',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bills payment coming soon')),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.phone_android,
            label: 'Recharge',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mobile recharge coming soon')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1A1A1A),
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: [
        ..._paymentMethods.map((method) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildPaymentMethodCard(method),
            )),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _showAddPaymentMethodDialog,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 8),
              Text(
                'Add Payment Method',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: method.isDefault ? const Color(0xFF1A1A1A) : Colors.grey[200]!,
          width: method.isDefault ? 2 : 1.5,
        ),
        boxShadow: [
          if (method.isDefault)
            BoxShadow(
              color: const Color(0xFF1A1A1A).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: method.iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(method.icon, color: method.iconColor, size: 26),
        ),
        title: Text(
          method.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            method.details,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        trailing: method.isDefault
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : PopupMenuButton(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Set as default'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Remove', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'default') {
                    setState(() {
                      for (var m in _paymentMethods) {
                        m.isDefault = m.id == method.id;
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${method.name} set as default')),
                    );
                  } else if (value == 'remove') {
                    _showRemoveDialog(method);
                  }
                },
              ),
      ),
    );
  }

  void _showAddMoneyDialog() {
    final TextEditingController amountController = TextEditingController();
    double? selectedAmount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Money to Wallet',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    selectedAmount = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick amounts:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [500, 1000, 2000, 5000].map((amount) {
                  return ChoiceChip(
                    label: Text('Rs. $amount'),
                    selected: selectedAmount == amount.toDouble(),
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedAmount = amount.toDouble();
                        amountController.text = amount.toString();
                      });
                    },
                    selectedColor: const Color(0xFF1A1A1A),
                    labelStyle: TextStyle(
                      color: selectedAmount == amount.toDouble()
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  Navigator.pop(context);
                  
                  // Show loading
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing...')),
                    );
                  }

                  try {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null) {
                      await _walletService.addMoney(
                        userId: user.id,
                        amount: amount,
                        description: 'Wallet top-up',
                      );
                      
                      // Reload wallet data
                      await _loadWalletData();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Rs. ${amount.toStringAsFixed(2)} added successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add money: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add Money'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendMoneyDialog() {
    final TextEditingController driverIdController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    String _selectedIdentifierType = 'email'; // 'email' or 'id'

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Send Money to Driver',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identifier Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email, size: 16),
                          SizedBox(width: 6),
                          Text('Email'),
                        ],
                      ),
                      selected: _selectedIdentifierType == 'email',
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            _selectedIdentifierType = 'email';
                          });
                        }
                      },
                      selectedColor: const Color(0xFF1A1A1A),
                      labelStyle: TextStyle(
                        color: _selectedIdentifierType == 'email'
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge, size: 16),
                          SizedBox(width: 6),
                          Text('Driver ID'),
                        ],
                      ),
                      selected: _selectedIdentifierType == 'id',
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            _selectedIdentifierType = 'id';
                          });
                        }
                      },
                      selectedColor: const Color(0xFF1A1A1A),
                      labelStyle: TextStyle(
                        color: _selectedIdentifierType == 'id'
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: driverIdController,
                keyboardType: _selectedIdentifierType == 'email'
                    ? TextInputType.emailAddress
                    : TextInputType.text,
                decoration: InputDecoration(
                  labelText: _selectedIdentifierType == 'email'
                      ? 'Driver Email'
                      : 'Driver ID',
                  hintText: _selectedIdentifierType == 'email'
                      ? 'driver@example.com'
                      : 'DRV123456',
                  prefixIcon: Icon(
                    _selectedIdentifierType == 'email'
                        ? Icons.email
                        : Icons.badge,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '0',
                  prefixText: 'Rs. ',
                  prefixIcon: const Icon(Icons.payments),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Make sure the driver information is correct',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final driverId = driverIdController.text.trim();
                final amount = double.tryParse(amountController.text);
                
                if (driverId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _selectedIdentifierType == 'email'
                            ? 'Please enter driver email'
                            : 'Please enter driver ID',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                if (amount > _walletBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Insufficient balance'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                setState(() {
                  _walletBalance -= amount;
                  _paymentMethods[0].details =
                      'Rs. ${_walletBalance.toStringAsFixed(2)}';
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rs. $amount sent to $driverId'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Send Money'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Payment Method',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _buildPaymentOption(
              icon: Icons.credit_card,
              iconColor: Colors.blue,
              title: 'Debit/Credit Card',
              onTap: () {
                Navigator.pop(context);
                _showAddCardDialog();
              },
            ),
            _buildPaymentOption(
              icon: Icons.phone_android,
              iconColor: Colors.red,
              title: 'JazzCash',
              onTap: () {
                Navigator.pop(context);
                _showAddMobileWalletDialog('JazzCash');
              },
            ),
            _buildPaymentOption(
              icon: Icons.phone_iphone,
              iconColor: Colors.green,
              title: 'EasyPaisa',
              onTap: () {
                Navigator.pop(context);
                _showAddMobileWalletDialog('EasyPaisa');
              },
            ),
            _buildPaymentOption(
              icon: Icons.account_balance,
              iconColor: Colors.purple,
              title: 'Bank Account',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bank linking coming soon')),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAddCardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Add Debit/Credit Card',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Card Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'MM/YY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Card added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Card'),
          ),
        ],
      ),
    );
  }

  void _showAddMobileWalletDialog(String wallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Link $wallet',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixText: '+92 ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$wallet linked successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Remove Payment Method',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('Are you sure you want to remove ${method.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _paymentMethods.removeWhere((m) => m.id == method.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${method.name} removed')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// Payment Method Model
class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String name;
  String details;
  final IconData icon;
  final Color iconColor;
  bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    required this.details,
    required this.icon,
    required this.iconColor,
    required this.isDefault,
  });

  PaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? name,
    String? details,
    IconData? icon,
    Color? iconColor,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      details: details ?? this.details,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

enum PaymentMethodType {
  wallet,
  cash,
  card,
  jazzcash,
  easypaisa,
  bank,
}
