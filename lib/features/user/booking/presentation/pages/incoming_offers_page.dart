import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/driver_offer.dart';
import '../bloc/booking_bloc.dart';
import '../widgets/driver_offer_card.dart';
import 'user_ride_tracking_page.dart';

class IncomingOffersPage extends StatefulWidget {
  final Ride ride;

  const IncomingOffersPage({
    super.key,
    required this.ride,
  });

  @override
  State<IncomingOffersPage> createState() => _IncomingOffersPageState();
}

class _IncomingOffersPageState extends State<IncomingOffersPage> {
  String? _acceptingOfferId;
  String? _rejectingOfferId;
  DriverOffer? _acceptedOffer;
  List<DriverOffer> _currentOffers = [];

  @override
  void initState() {
    super.initState();
    // Start listening to offers for this ride
    context.read<BookingBloc>().add(
          ListenToRideOffers(rideId: widget.ride.id),
        );
    
    // Load initial offers
    context.read<BookingBloc>().add(
          LoadRideOffers(rideId: widget.ride.id),
        );
  }

  void _acceptOffer(String offerId, DriverOffer offer) {
    setState(() {
      _acceptingOfferId = offerId;
      _acceptedOffer = offer;
    });
    context.read<BookingBloc>().add(
          AcceptDriverOffer(
            rideId: widget.ride.id,
            offerId: offerId,
          ),
        );
  }

  void _rejectOffer(String offerId) {
    setState(() => _rejectingOfferId = offerId);
    context.read<BookingBloc>().add(
          RejectDriverOffer(
            rideId: widget.ride.id,
            offerId: offerId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Offers'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is OfferAcceptedSuccessfully) {
            // Clear loading states
            setState(() {
              _acceptingOfferId = null;
              _rejectingOfferId = null;
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Offer accepted! Driver is on the way.'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Navigate to ride tracking page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserRideTrackingPage(
                  ride: state.ride,
                  acceptedOffer: _acceptedOffer,
                ),
              ),
            );
          } else if (state is OffersLoaded) {
            setState(() => _currentOffers = state.offers);
          } else if (state is SearchingForDrivers) {
            setState(() => _currentOffers = state.offers);
          } else if (state is OfferRejectedSuccessfully) {
            // Clear loading state
            setState(() => _rejectingOfferId = null);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Offer declined'),
              ),
            );
          } else if (state is BookingError) {
            // Clear loading states
            setState(() {
              _acceptingOfferId = null;
              _rejectingOfferId = null;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OffersLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is OffersLoaded) {
            final offers = state.offers;
            
            if (offers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Waiting for drivers...',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Nearby drivers will be notified. You\'ll receive offers soon!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
              );
            }
            
            // Sort offers: pending first, then by price
            final sortedOffers = List.of(offers)
              ..sort((a, b) {
                // Pending offers first
                if (a.status == 'pending' && b.status != 'pending') return -1;
                if (a.status != 'pending' && b.status == 'pending') return 1;
                // Then by price (lowest first)
                return a.offeredPrice.compareTo(b.offeredPrice);
              });
            
            return Column(
              children: [
                // Ride summary header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.primaryColor.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_taxi,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${widget.ride.vehicleType.toUpperCase()} • ${widget.ride.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'Est: ₨${widget.ride.estimatedFare.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.circle, 
                                    size: 8, 
                                    color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.ride.pickupLocationName ?? 'Pickup',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.circle, 
                                    size: 8, 
                                    color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.ride.dropoffLocationName ?? 'Dropoff',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Offers count
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        '${offers.length} ${offers.length == 1 ? 'Offer' : 'Offers'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Sorted by best price',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Offers list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<BookingBloc>().add(
                            LoadRideOffers(rideId: widget.ride.id),
                          );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: sortedOffers.length,
                      itemBuilder: (context, index) {
                        final offer = sortedOffers[index];
                        return DriverOfferCard(
                          offer: offer,
                          onAccept: () => _acceptOffer(offer.id, offer),
                          onReject: () => _rejectOffer(offer.id),
                          isAccepting: _acceptingOfferId == offer.id,
                          isRejecting: _rejectingOfferId == offer.id,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
          
          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
    );
  }
}
