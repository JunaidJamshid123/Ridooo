import 'package:flutter/material.dart';
import '../../../../../core/widgets/rating_stars.dart';

/// Page for rating driver after ride completion
class RateDriverPage extends StatefulWidget {
  final String rideId;
  final String driverName;
  final String? driverPhoto;

  const RateDriverPage({
    super.key,
    required this.rideId,
    required this.driverName,
    this.driverPhoto,
  });

  @override
  State<RateDriverPage> createState() => _RateDriverPageState();
}

class _RateDriverPageState extends State<RateDriverPage> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

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

    // TODO: Implement rating submission via BLoC
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(true);
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
              children: [
                _FeedbackChip(label: 'Friendly driver'),
                _FeedbackChip(label: 'Clean car'),
                _FeedbackChip(label: 'Safe driving'),
                _FeedbackChip(label: 'Good conversation'),
                _FeedbackChip(label: 'On time'),
              ],
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

class _FeedbackChip extends StatefulWidget {
  final String label;

  const _FeedbackChip({required this.label});

  @override
  State<_FeedbackChip> createState() => _FeedbackChipState();
}

class _FeedbackChipState extends State<_FeedbackChip> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(widget.label),
      selected: _selected,
      onSelected: (selected) {
        setState(() => _selected = selected);
      },
    );
  }
}
