import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/widgets/rating_stars.dart';
import '../../../../../core/services/rating_service.dart';

/// Page for rating driver after ride completion
class RateDriverPage extends StatefulWidget {
  final String rideId;
  final String driverName;
  final String? driverPhoto;
  final String? driverId;

  const RateDriverPage({
    super.key,
    required this.rideId,
    required this.driverName,
    this.driverPhoto,
    this.driverId,
  });

  @override
  State<RateDriverPage> createState() => _RateDriverPageState();
}

class _RateDriverPageState extends State<RateDriverPage> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;
  final Set<String> _selectedTags = {};
  late final RatingService _ratingService;

  final List<String> _feedbackOptions = [
    'Friendly driver',
    'Clean car',
    'Safe driving',
    'Good conversation',
    'On time',
    'Professional',
  ];

  @override
  void initState() {
    super.initState();
    _ratingService = RatingService(supabaseClient: Supabase.instance.client);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get driver ID from ride if not provided
      String? driverId = widget.driverId;
      if (driverId == null || driverId.isEmpty) {
        // Fetch driver ID from the ride
        final ride = await Supabase.instance.client
            .from('rides')
            .select('driver_id')
            .eq('id', widget.rideId)
            .maybeSingle();
        driverId = ride?['driver_id'] as String?;
      }

      if (driverId == null) {
        throw Exception('Driver ID not found');
      }

      // Submit rating to database
      await _ratingService.submitRating(
        rideId: widget.rideId,
        reviewerId: currentUser.id,
        revieweeId: driverId,
        rating: _rating,
        comment: _reviewController.text.trim().isNotEmpty 
            ? _reviewController.text.trim() 
            : null,
        tags: _selectedTags.isNotEmpty ? _selectedTags.toList() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Ride'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Driver avatar
            CircleAvatar(
              radius: 50,
              backgroundImage: widget.driverPhoto != null
                  ? NetworkImage(widget.driverPhoto!)
                  : null,
              child: widget.driverPhoto == null
                  ? Text(
                      widget.driverName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 36),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Driver name
            Text(
              widget.driverName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Rating prompt
            Text(
              'How was your ride?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Rating stars
            RatingInput(
              initialRating: _rating,
              size: 48,
              onRatingChanged: (rating) {
                setState(() => _rating = rating);
              },
            ),
            const SizedBox(height: 32),

            // Review text field
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write a review (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick feedback chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _feedbackOptions.map((label) => 
                FilterChip(
                  label: Text(label),
                  selected: _selectedTags.contains(label),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(label);
                      } else {
                        _selectedTags.remove(label);
                      }
                    });
                  },
                ),
              ).toList(),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Rating'),
              ),
            ),

            // Skip button
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}
