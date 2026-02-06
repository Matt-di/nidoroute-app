import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nitoroute/core/models/trip.dart';
import '../../../trip/logic/bloc/trip_detail_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/bloc/trip_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/delivery.dart';
import '../../../../core/widgets/user_avatar.dart';

class TripStopsBottomSheet extends StatefulWidget {
  final Trip trip;
  final ScrollController? scrollController;

  const TripStopsBottomSheet({
    super.key,
    required this.trip,
    this.scrollController,
  });

  static void show(BuildContext context, {required Trip trip}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => BlocProvider.value(
          value: BlocProvider.of<TripDetailBloc>(context),
          child: TripStopsBottomSheet(
            trip: trip,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  @override
  State<TripStopsBottomSheet> createState() => _TripStopsBottomSheetState();
}

class _TripStopsBottomSheetState extends State<TripStopsBottomSheet> {
  Set<String> _selectedDeliveryIds = {};
  bool _isSelectionMode = false;
  bool _isBulkOperationInProgress = false;

  @override
  void initState() {
    super.initState();
    // Ensure trip data is loaded when bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<TripDetailBloc>();
      if (bloc.state.isInitial) {
        bloc.loadTripDetails(widget.trip.id);
      }
    });
  }

  void _toggleSelection(String deliveryId) {
    setState(() {
      if (_selectedDeliveryIds.contains(deliveryId)) {
        _selectedDeliveryIds.remove(deliveryId);
        if (_selectedDeliveryIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedDeliveryIds.add(deliveryId);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAllDeliveries(List<Delivery> deliveries) {
    setState(() {
      _selectedDeliveryIds = deliveries.map((d) => d.id).toSet();
      _isSelectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedDeliveryIds.clear();
      _isSelectionMode = false;
    });
  }

  void _bulkPickup(List<Delivery> deliveries) {
    final selectedDeliveries = deliveries.where((d) => _selectedDeliveryIds.contains(d.id));
    final eligibleDeliveryIds = selectedDeliveries
        .where((d) => d.status == "pending")
        .map((d) => d.id)
        .toList();
    
    if (eligibleDeliveryIds.isEmpty) {
      _showFeedbackMessage('No eligible passengers for pickup');
      _clearSelection();
      return;
    }
    
    setState(() => _isBulkOperationInProgress = true);
    
    // Show loading message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing ${eligibleDeliveryIds.length} pickup${eligibleDeliveryIds.length == 1 ? '' : 's'}...'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
    
    context.read<TripDetailBloc>().add(
      BulkDeliveryPickupRequested(deliveryIds: eligibleDeliveryIds),
    );
    
    // UI will be updated by BlocListener when backend responds
  }

  void _bulkDropoff(List<Delivery> deliveries) {
    final selectedDeliveries = deliveries.where((d) => _selectedDeliveryIds.contains(d.id));
    final eligibleDeliveryIds = selectedDeliveries
        .where((d) => d.status == "picked_up")
        .map((d) => d.id)
        .toList();
    
    if (eligibleDeliveryIds.isEmpty) {
      _showFeedbackMessage('No eligible passengers for dropoff');
      _clearSelection();
      return;
    }
    
    setState(() => _isBulkOperationInProgress = true);
    
    // Show loading message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing ${eligibleDeliveryIds.length} dropoff${eligibleDeliveryIds.length == 1 ? '' : 's'}...'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
    
    context.read<TripDetailBloc>().add(
      BulkDeliveryDropoffRequested(deliveryIds: eligibleDeliveryIds),
    );
    
    // UI will be updated by BlocListener when backend responds
  }

  void _showFeedbackMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  bool _isAllDeliveriesCompleted(List<Delivery> deliveries) {
    if (deliveries.isEmpty) return false;
    return deliveries.every((delivery) => 
        delivery.status == "delivered" || delivery.status == "completed");
  }

  Widget _buildCompleteTripButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.successColor,
            Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _completeTrip(),
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: Colors.white,
                  size: AppTheme.fontSize16,
                ),
                SizedBox(width: AppTheme.spacing8),
                Text(
                  'Complete Trip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.fontSize14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _completeTrip() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Trip'),
          content: const Text('Are you sure you want to complete this trip? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<TripDetailBloc>().add(
                  TripCompleteRequested(tripId: widget.trip.id),
                );
                _showFeedbackMessage('Trip completion requested');
                Navigator.of(context).pop(); // Close bottom sheet
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripDetailBloc, BlocState<dynamic>>(
      listener: (context, state) {
        // Update UI when bulk operations complete
        if (_isBulkOperationInProgress) {
          if (state.isSuccess || state.isError) {
            setState(() {
              _isBulkOperationInProgress = false;
              _selectedDeliveryIds.clear();
              _isSelectionMode = false;
            });
            
            if (state.isError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Operation failed: ${state.errorMessage ?? "Unknown error"}'),
                  backgroundColor: Colors.red,
                ),
              );
            } else {
              _showFeedbackMessage('Operation completed successfully');
            }
          }
        }
      },
      child: BlocBuilder<TripDetailBloc, BlocState<dynamic>>(
      builder: (context, state) {
        // Get deliveries primarily from current bloc state
        List<Delivery> deliveries = [];
        if (state.data != null && state.data is TripDetailData) {
          final tripDetailData = state.data as TripDetailData;
          deliveries = tripDetailData.deliveries ?? [];
        }

        // Only use widget trip data as a remote fallback if state is empty
        if (deliveries.isEmpty) {
          deliveries = widget.trip.deliveries ?? [];
        }

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radius24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: AppTheme.spacing12),
                width: AppTheme.spacing32 * 1.25,
                height: AppTheme.spacing4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
              ),

              // Scrollable content
              Flexible(
                child: ListView(
                  controller: widget.scrollController,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    // Header
                    _buildHeader(context, deliveries),

                    // Content
                    if (deliveries.isEmpty)
                      _buildEmptyState(context)
                    else
                      _buildContent(context, deliveries),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    )
    );
  }

  Widget _buildHeader(BuildContext context, List<Delivery> deliveries) {
    final groupedStops = _groupDeliveriesByStop(deliveries);

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.textSecondary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: AppTheme.primaryColor,
                  size: AppTheme.fontSize24,
                ),
              ),
              SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Stops',
                      style: AppTheme.headlineMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontSize20,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing4),
                    Text(
                      '${deliveries.length} passengers • ${groupedStops.length} stops',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isSelectionMode)
                IconButton(
                  onPressed: () => setState(() => _isSelectionMode = true),
                  icon: Icon(
                    Icons.checklist_rounded,
                    color: AppTheme.primaryColor,
                    size: AppTheme.fontSize24,
                  ),
                )
              else
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _selectAllDeliveries(deliveries),
                      icon: Icon(
                        Icons.select_all_rounded,
                        color: AppTheme.primaryColor,
                        size: AppTheme.fontSize20,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _clearSelection(),
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey,
                        size: AppTheme.fontSize20,
                      ),
                    ),
                  ],
                ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppTheme.textSecondary,
                  size: AppTheme.fontSize24,
                ),
              ),
            ],
          ),
          if (_isSelectionMode && _selectedDeliveryIds.isNotEmpty) ...[
            SizedBox(height: AppTheme.spacing16),
            Container(
              padding: EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primaryColor,
                    size: AppTheme.fontSize20,
                  ),
                  SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Text(
                      '${_selectedDeliveryIds.length} passenger${_selectedDeliveryIds.length == 1 ? '' : 's'} selected',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: AppTheme.fontSize14,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildBulkActionButton(
                        'Pick Up',
                        Icons.people_rounded,
                        Colors.orange,
                        () => _bulkPickup(deliveries),
                        isLoading: _isBulkOperationInProgress,
                      ),
                      SizedBox(width: AppTheme.spacing8),
                      _buildBulkActionButton(
                        'Drop Off',
                        Icons.home_rounded,
                        Colors.green,
                        () => _bulkDropoff(deliveries),
                        isLoading: _isBulkOperationInProgress,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          // Trip completion section
          if (_isAllDeliveriesCompleted(deliveries) && !_isSelectionMode) ...[
            SizedBox(height: AppTheme.spacing16),
            Container(
              padding: EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.successColor,
                    size: AppTheme.fontSize24,
                  ),
                  SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Passengers Delivered',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w700,
                            fontSize: AppTheme.fontSize16,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacing4),
                        Text(
                          'You can now complete this trip',
                          style: TextStyle(
                            color: AppTheme.successColor.withOpacity(0.8),
                            fontSize: AppTheme.fontSize12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCompleteTripButton(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulkActionButton(String label, IconData icon, Color color, VoidCallback onPressed, {bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isLoading ? color.withOpacity(0.6) : color,
        borderRadius: BorderRadius.circular(AppTheme.radius8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radius8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: AppTheme.fontSize16,
                    height: AppTheme.fontSize16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                else ...[
                  Icon(
                    icon,
                    color: Colors.white,
                    size: AppTheme.fontSize16,
                  ),
                  SizedBox(width: AppTheme.spacing4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.fontSize12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacing24),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              color: AppTheme.textSecondary,
              size: 48,
            ),
          ),
          SizedBox(height: AppTheme.spacing20),
          Text(
            'No stops available',
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSize18,
            ),
          ),
          SizedBox(height: AppTheme.spacing8),
          Text(
            'Trip details are loading or no stops have been assigned yet.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          SizedBox(height: AppTheme.spacing24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded),
            label: Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textWhite,
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing24,
                vertical: AppTheme.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Delivery> deliveries) {
    final groupedStops = _groupDeliveriesByStop(deliveries);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress Summary
        _buildProgressSummary(deliveries),

        // Stops List
        ...groupedStops.asMap().entries.map((entry) {
          final index = entry.key;
          final stop = entry.value;
          final isLastStop = index == groupedStops.length - 1;
          return Padding(
            padding: EdgeInsets.only(
              left: AppTheme.spacing20,
              right: AppTheme.spacing20,
              bottom: index == groupedStops.length - 1
                  ? AppTheme.spacing20
                  : AppTheme.spacing12,
            ),
            child: _buildStopCard(context, stop, index + 1, isLastStop),
          );
        }),
      ],
    );
  }

  Widget _buildProgressSummary(List<Delivery> deliveries) {
    final pickedUp = deliveries.where((d) => d.status == "picked_up").length;
    final delivered = deliveries.where((d) => d.status == "delivered").length;
    final pending = deliveries.where((d) => d.status == "pending").length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
      padding: EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            'Trip Progress',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: AppTheme.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              _buildProgressItem(widget.trip.tripType == 'pickup' ? 'Picked Up' : 'Left School', pickedUp, AppTheme.warningColor),
              SizedBox(width: AppTheme.spacing12),
              _buildProgressItem(widget.trip.tripType == 'pickup' ? 'At School' : 'Dropped Off', delivered, AppTheme.successColor),
              SizedBox(width: AppTheme.spacing12),
              _buildProgressItem('Pending', pending, AppTheme.primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.spacing12,
          horizontal: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radius8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: AppTheme.headlineMedium.copyWith(
                color: color,
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontWeightBold,
              ),
            ),
            SizedBox(height: AppTheme.spacing4),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: color.withOpacity(0.8),
                fontWeight: AppTheme.fontWeightMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopCard(
    BuildContext context,
    List<Delivery> stopDeliveries,
    int stopNumber,
    bool isLastStop,
  ) {
    final firstDelivery = stopDeliveries.first;
    final isPickup = widget.trip.tripType == 'pickup';
    
    final allPickedUp = stopDeliveries.every((d) => d.status == "picked_up" || d.status == "delivered" || d.status == "no_show");
    final allDelivered = stopDeliveries.every((d) => d.status == 'delivered' || d.status == "no_show");
    final anyPending = stopDeliveries.any((d) => d.status == "pending");
    final anyPickedUp = stopDeliveries.any((d) => d.status == "picked_up");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stop Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getStopColor(allPickedUp, allDelivered, isLastStop),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStopIcon(stopNumber, isLastStop),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStopLabel(stopNumber, isLastStop),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${stopDeliveries.length} passenger${stopDeliveries.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStopStatus(allPickedUp, allDelivered, isLastStop),
            ],
          ),

          const SizedBox(height: 12),

          // Passengers List
          ...stopDeliveries.map(
            (delivery) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPassengerRow(context, delivery),
            ),
          ),

          // Action Buttons (only show if not completed)
          if (!allDelivered)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (anyPending && !(isPickup && isLastStop))
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _pickupAllAtStop(context, stopDeliveries),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: Colors.orange),
                        ),
                        child: Text(
                          isPickup ? 'Pick Up All' : 'Collect All',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (anyPending && anyPickedUp && !(isPickup && isLastStop)) 
                    const SizedBox(width: 8),
                  if (anyPickedUp && (!(!isPickup && stopNumber == 1) || (isPickup && isLastStop)))
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _dropoffAllAtStop(context, stopDeliveries),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          isPickup && isLastStop 
                              ? 'Arrive at School' 
                              : (isPickup ? 'Drop Off' : 'Drop Off All'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPassengerRow(BuildContext context, Delivery delivery) {
    final isSelected = _selectedDeliveryIds.contains(delivery.id);
    
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(delivery.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Selection Checkbox (only show in selection mode)
            if (_isSelectionMode) ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
            ],
            
            // Passenger Avatar
            UserAvatar(
              imageUrl: delivery.passenger?.image,
              name: delivery.passengerName ?? 'Unknown Passenger',
              size: 40,
            ),
            const SizedBox(width: 12),
            
            // Status Indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: delivery.status == "delivered"
                    ? Colors.green
                    : delivery.status == "picked_up"
                    ? Colors.orange
                    : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Passenger Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.passengerName ??
                        'Passenger ${delivery.id.substring(0, 4)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                  Text(
                    _getDeliveryStatusText(delivery),
                    style: TextStyle(
                      fontSize: 12, 
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Individual Actions (only show when not in selection mode)
            if (!_isSelectionMode && delivery.status != "delivered")
              PopupMenuButton<String>(
                onSelected: (action) =>
                    _handleIndividualAction(context, delivery, action),
                itemBuilder: (context) => [
                  if (delivery.status != "picked_up")
                    PopupMenuItem(
                      value: 'pickup',
                      child: Text(widget.trip.tripType == 'pickup' ? 'Mark Picked Up' : 'Mark Left School'),
                    ),
                  if (delivery.status == "picked_up" &&
                      delivery.status != "delivered")
                    PopupMenuItem(
                      value: 'dropoff',
                      child: Text(widget.trip.tripType == 'pickup' ? 'Mark Arrived' : 'Mark Dropped Off'),
                    ),
                  const PopupMenuItem(
                    value: 'no_show',
                    child: Text('Mark No Show'),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopStatus(
    bool allPickedUp,
    bool allDelivered,
    bool isLastStop,
  ) {
    String statusText;
    Color statusColor;

    if (allDelivered) {
      statusText = 'Completed';
      statusColor = Colors.green;
    } else if (allPickedUp) {
      statusText = isLastStop ? 'At School' : 'Picked Up';
      statusColor = Colors.orange;
    } else {
      statusText = 'Pending';
      statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleIndividualAction(
    BuildContext context,
    Delivery delivery,
    String action,
  ) {
    switch (action) {
      case 'pickup':
        context.read<TripDetailBloc>().add(
          DeliveryPickupRequested(deliveryId: delivery.id),
        );
        break;
      case 'dropoff':
        context.read<TripDetailBloc>().add(
          DeliveryDropoffRequested(deliveryId: delivery.id),
        );
        break;
      case 'no_show':
        // TODO: Implement no-show functionality
        break;
    }
  }

  void _pickupAllAtStop(BuildContext context, List<Delivery> deliveries) {
    for (final delivery in deliveries) {
      if (delivery.status == "pending") {
        context.read<TripDetailBloc>().add(
          DeliveryPickupRequested(deliveryId: delivery.id),
        );
      }
    }
  }

  void _dropoffAllAtStop(BuildContext context, List<Delivery> deliveries) {
    for (final delivery in deliveries) {
      if (delivery.status == "picked_up") {
        context.read<TripDetailBloc>().add(
          DeliveryDropoffRequested(deliveryId: delivery.id),
        );
      }
    }
  }

  List<List<Delivery>> _groupDeliveriesByStop(List<Delivery> deliveries) {
    if (deliveries.isEmpty) return [];

    final grouped = <List<Delivery>>[];
    final isPickup = widget.trip.tripType == 'pickup';

    if (isPickup) {
      // Morning: Group by home pickups, then one final school stop
      final homeGroups = <String, List<Delivery>>{};
      for (final delivery in deliveries) {
        final loc = delivery.pickupLocation;
        final key = '${loc?.latitude ?? 0}_${loc?.longitude ?? 0}';
        homeGroups.putIfAbsent(key, () => []).add(delivery);
      }
      
      final sortedHomes = homeGroups.values.toList()
        ..sort((a, b) => (a.first.scheduledPickupTime ?? DateTime.now())
            .compareTo(b.first.scheduledPickupTime ?? DateTime.now()));
            
      grouped.addAll(sortedHomes);
      
      // Add School stop at the end with all students
      grouped.add(List<Delivery>.from(deliveries));
    } else {
      // Afternoon: Group by school pickup first, then home drop-offs
      // Start with School stop
      grouped.add(List<Delivery>.from(deliveries));

      final homeGroups = <String, List<Delivery>>{};
      for (final delivery in deliveries) {
        final loc = delivery.dropoffLocation;
        final key = '${loc?.latitude ?? 0}_${loc?.longitude ?? 0}';
        homeGroups.putIfAbsent(key, () => []).add(delivery);
      }

      final sortedHomes = homeGroups.values.toList()
        ..sort((a, b) => (a.first.scheduledDropoffTime ?? DateTime.now())
            .compareTo(b.first.scheduledDropoffTime ?? DateTime.now()));
            
      grouped.addAll(sortedHomes);
    }

    return grouped;
  }

  Color _getStopColor(bool allPickedUp, bool allDelivered, bool isLastStop) {
    if (allDelivered) return Colors.green;
    if (allPickedUp) return Colors.orange;
    return Colors.grey;
  }

  String _getStopLabel(int stopNumber, bool isLastStop) {
    if (widget.trip.tripType == 'pickup') {
      return isLastStop ? 'School Drop-off' : 'Pickup Stop $stopNumber';
    } else {
      return stopNumber == 1 ? 'School Pickup' : 'Drop-off Stop ${stopNumber - 1}';
    }
  }

  IconData _getStopIcon(int index, bool isLastStop) {
    if (widget.trip.tripType == 'pickup') {
      return isLastStop ? Icons.school_rounded : Icons.home_rounded;
    } else {
      // In afternoon trip, the first stop (index 1) is the school
      return index == 1 ? Icons.school_rounded : Icons.home_rounded;
    }
  }

  String _getDeliveryStatusText(Delivery delivery) {
    if (delivery.status == "delivered") {
      return widget.trip.tripType == 'pickup' ? 'Arrived at School' : 'Dropped off';
    }
    if (delivery.status == "picked_up") {
      return widget.trip.tripType == 'pickup' ? 'On board' : 'Left school';
    }
    return widget.trip.tripType == 'pickup' ? 'Pending pickup' : 'Waiting at school';
  }
}
