import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../user/booking/domain/entities/ride.dart';
import '../bloc/driver_rides_bloc.dart';
import '../bloc/driver_rides_event.dart';

class CreateOfferBottomSheet extends StatefulWidget {
  final Ride ride;

  const CreateOfferBottomSheet({
    super.key,
    required this.ride,
  });

  @override
  State<CreateOfferBottomSheet> createState() => _CreateOfferBottomSheetState();
}

class _CreateOfferBottomSheetState extends State<CreateOfferBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _etaController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set suggested price (slightly lower than estimated fare)
    final suggestedPrice = (widget.ride.estimatedFare * 0.95).roundToDouble();
    _priceController.text = suggestedPrice.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _etaController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitOffer() {
    if (_formKey.currentState!.validate()) {
      final offeredPrice = double.parse(_priceController.text);
      final eta = _etaController.text.isEmpty ? null : int.parse(_etaController.text);
      final message = _messageController.text.isEmpty ? null : _messageController.text;

      context.read<DriverRidesBloc>().add(
            CreateRideOffer(
              rideId: widget.ride.id,
              offeredPrice: offeredPrice,
              estimatedArrivalMin: eta,
              message: message,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Send Your Offer',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Suggest your price and arrival time',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              
              // Ride info summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Distance',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          '${widget.ride.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Fare',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          '₨${widget.ride.estimatedFare.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Offered Price
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Your Offer Price *',
                  hintText: 'Enter your price',
                  prefixText: '₨ ',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          final current = int.tryParse(_priceController.text) ?? 0;
                          if (current > 10) {
                            _priceController.text = (current - 10).toString();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final current = int.tryParse(_priceController.text) ?? 0;
                          _priceController.text = (current + 10).toString();
                        },
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your offer price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Estimated Arrival Time
              TextFormField(
                controller: _etaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Arrival Time (Optional)',
                  hintText: 'Minutes to reach',
                  suffixText: 'min',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Message
              TextFormField(
                controller: _messageController,
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: 'Message to Rider (Optional)',
                  hintText: 'Add a note...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Info text
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your offer will expire in 5 minutes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      onPressed: _submitOffer,
                      text: 'Send Offer',
                      backgroundColor: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
