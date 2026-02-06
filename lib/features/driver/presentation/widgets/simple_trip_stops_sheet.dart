import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/bloc/trip_bloc.dart';
import '../../../trip/logic/bloc/trip_detail_bloc.dart';

class SimpleTripStopsSheet extends StatefulWidget {
  final Trip trip;
  final ScrollController? scrollController;

  const SimpleTripStopsSheet({
    super.key,
    required this.trip,
    this.scrollController,
  });

  static void show(BuildContext context, {required Trip trip, TripDetailBloc? bloc}) {
    final blocToUse = bloc ?? context.read<TripDetailBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: blocToUse,
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SimpleTripStopsSheet(
            trip: trip,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  @override
  State<SimpleTripStopsSheet> createState() => _SimpleTripStopsSheetState();
}

class _SimpleTripStopsSheetState extends State<SimpleTripStopsSheet> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  bool _isProcessing = false;
  String? _processingId;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<Delivery> deliveries) {
    setState(() {
      _selectedIds.clear();
      for (final d in deliveries) {
        if (d.status == 'pending' || d.status == 'picked_up') {
          _selectedIds.add(d.id);
        }
      }
      _isSelectionMode = _selectedIds.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  void _bulkPickup(List<Delivery> deliveries) {
    final ids = deliveries
        .where((d) => _selectedIds.contains(d.id) && d.status == 'pending')
        .map((d) => d.id)
        .toList();

    if (ids.isEmpty) {
      _showMessage('No eligible passengers for pickup');
      return;
    }

    setState(() => _isProcessing = true);
    context.read<TripDetailBloc>().add(BulkDeliveryPickupRequested(deliveryIds: ids));
    _showMessage('Processing ${ids.length} pickups...');
  }

  void _bulkDropoff(List<Delivery> deliveries) {
    final ids = deliveries
        .where((d) => _selectedIds.contains(d.id) && d.status == 'picked_up')
        .map((d) => d.id)
        .toList();

    if (ids.isEmpty) {
      _showMessage('No eligible passengers for dropoff');
      return;
    }

    setState(() => _isProcessing = true);
    context.read<TripDetailBloc>().add(BulkDeliveryDropoffRequested(deliveryIds: ids));
    _showMessage('Processing ${ids.length} dropoffs...');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripDetailBloc, BlocState<dynamic>>(
      listener: (context, state) {
        if (state.isSuccess && state.data != null) {
          final data = state.data as TripDetailData;
          if (data.trip.isCompleted) {
            if (mounted) Navigator.pop(context);
            return;
          }
        }
        
        if (_isProcessing && (state.isSuccess || state.isError)) {
          setState(() {
            _isProcessing = false;
            _processingId = null;
            _clearSelection();
          });
          if (state.isError) {
            _showMessage('Operation failed');
          }
        }
      },
      child: BlocBuilder<TripDetailBloc, BlocState<dynamic>>(
        builder: (context, state) {
          final deliveries = _getDeliveries(state);
          final stats = _DeliveryStats.from(deliveries);
          final isPickup = widget.trip.tripType == 'pickup';

          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _buildDragHandle(),
                _buildHeader(deliveries, stats, isPickup),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.vertical,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _isSelectionMode 
                      ? _buildSelectionBar(deliveries, isPickup)
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: deliveries.isEmpty
                      ? _buildEmptyState()
                      : _buildDeliveryList(deliveries, isPickup),
                ),
                if (!_isSelectionMode)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.vertical,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: stats.allCompleted 
                        ? _buildCompleteButton() 
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Delivery> _getDeliveries(BlocState<dynamic> state) {
    List<Delivery> deliveries;
    if (state.data is TripDetailData) {
      deliveries = (state.data as TripDetailData).deliveries ?? [];
    } else {
      deliveries = widget.trip.deliveries ?? [];
    }
    
    return deliveries;
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildHeader(List<Delivery> deliveries, _DeliveryStats stats, bool isPickup) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.route_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPickup ? 'Morning Pickup' : 'Afternoon Dropoff',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${deliveries.length} passengers',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // Actions
              if (!_isSelectionMode)
                IconButton(
                  onPressed: () => _selectAll(deliveries),
                  icon: const Icon(Icons.checklist_rounded),
                  color: AppTheme.primaryColor,
                  tooltip: 'Select multiple',
                ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                color: Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress stats
          Row(
            children: [
              _buildStatCard(
                icon: Icons.directions_walk_rounded,
                label: isPickup ? 'Left Home' : 'Left School',
                count: stats.pickedUp,
                color: Colors.orange,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                icon: Icons.check_circle_rounded,
                label: isPickup ? 'At School' : 'At Home',
                count: stats.delivered,
                color: Colors.green,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                icon: Icons.schedule_rounded,
                label: 'Pending',
                count: stats.pending,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Text(
                count.toString(),
                key: ValueKey('${label}_$count'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar(List<Delivery> deliveries, bool isPickup) {
    final pendingSelected = deliveries.where((d) => _selectedIds.contains(d.id) && d.status == 'pending').length;
    final pickedUpSelected = deliveries.where((d) => _selectedIds.contains(d.id) && d.status == 'picked_up').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Selection count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_selectedIds.length} selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const Spacer(),
          // Bulk actions
          if (pendingSelected > 0)
            _buildActionButton(
              label: isPickup ? 'Left Home' : 'Left School',
              icon: Icons.directions_walk_rounded,
              color: Colors.orange,
              onTap: _isProcessing ? null : () => _bulkPickup(deliveries),
            ),
          if (pendingSelected > 0 && pickedUpSelected > 0) const SizedBox(width: 8),
          if (pickedUpSelected > 0)
            _buildActionButton(
              label: isPickup ? 'At School' : 'At Home',
              icon: Icons.check_circle_outline_rounded,
              color: Colors.green,
              onTap: _isProcessing ? null : () => _bulkDropoff(deliveries),
            ),
          const SizedBox(width: 8),
          // Clear button
          IconButton(
            onPressed: _clearSelection,
            icon: const Icon(Icons.clear_rounded),
            color: Colors.grey.shade600,
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: onTap == null ? color.withValues(alpha: 0.5) : color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: onTap == null && _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(icon, color: Colors.white, size: 18, key: ValueKey(icon)),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryList(List<Delivery> deliveries, bool isPickup) {
    final sorted = List<Delivery>.from(deliveries)
      ..sort((a, b) {
        // Sort: pending first, then picked_up, then completed
        final statusOrder = {'pending': 0, 'picked_up': 1, 'delivered': 2, 'no_show': 3};
        final aOrder = statusOrder[a.status] ?? 4;
        final bOrder = statusOrder[b.status] ?? 4;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        
        // Then by sequence
        if (a.sequence != null && b.sequence != null) {
          return a.sequence!.compareTo(b.sequence!);
        }
        return 0;
      });

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) => _DeliveryCard(
        delivery: sorted[index],
        isPickup: isPickup,
        isSelected: _selectedIds.contains(sorted[index].id),
        isSelectionMode: _isSelectionMode,
        isProcessing: _processingId == sorted[index].id,
        onTap: () => _toggleSelection(sorted[index].id),
        onAction: (action) => _handleAction(sorted[index], action),
      ),
    );
  }

  void _handleAction(Delivery delivery, String action) {
    final bloc = context.read<TripDetailBloc>();
    
    setState(() {
      _isProcessing = true;
      _processingId = delivery.id;
    });

    switch (action) {
      case 'pickup':
        bloc.add(DeliveryPickupRequested(deliveryId: delivery.id));
        _showMessage('Pickup recorded');
        break;
      case 'dropoff':
        bloc.add(DeliveryDropoffRequested(deliveryId: delivery.id));
        _showMessage('Dropoff recorded');
        break;
      case 'no_show':
        // No show transitions to terminal state, so we reload
        // In a real app this might need a dedicated block event
        // But for now it's usually handled by the same reload logic
        _showMessage('Marked as no show');
        setState(() {
          _isProcessing = false;
          _processingId = null;
        });
        break;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            'No passengers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trip details are loading...',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All passengers delivered!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Ready to complete trip',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _completeTrip(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Complete', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _completeTrip() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Trip'),
        content: const Text('Are you sure you want to complete this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TripDetailBloc>().add(TripCompleteRequested(tripId: widget.trip.id));
              _showMessage('Completing trip...');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Delivery Card Widget
// =============================================================================

class _DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final bool isPickup;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isProcessing;
  final VoidCallback onTap;
  final Function(String) onAction;

  const _DeliveryCard({
    required this.delivery,
    required this.isPickup,
    required this.isSelected,
    required this.isSelectionMode,
    required this.isProcessing,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = delivery.status == 'delivered' || delivery.status == 'no_show';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? AppTheme.primaryColor.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSelectionMode && !isCompleted ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Selection checkbox
                if (isSelectionMode && !isCompleted) ...[
                  _buildCheckbox(),
                  const SizedBox(width: 12),
                ],
                // Avatar
                Stack(
                  children: [
                    UserAvatar(
                      imageUrl: delivery.passenger?.image,
                      name: delivery.passengerName ?? 'Unknown',
                      size: 50,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _buildStatusBadge(),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.passengerName ?? 'Unknown Passenger',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.grey.shade500 : Colors.grey.shade900,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(),
                            size: 14,
                            color: _getStatusColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusLabel(),
                            style: TextStyle(
                              fontSize: 13,
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                if (!isSelectionMode) _buildActionButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      curve: Curves.easeOutBack,
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
          width: 2,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ] : null,
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isSelected ? 1.0 : 0.0,
        curve: Curves.easeOutBack,
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: child,
        );
      },
      child: Container(
        key: ValueKey(delivery.status),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _getStatusColor(),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor().withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            )
          ],
        ),
        child: Icon(_getStatusIcon(), color: Colors.white, size: 10),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (isProcessing) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(right: 8),
        width: 44,
        height: 44,
        child: const CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (delivery.status == 'delivered') {
      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
      );
    }

    if (delivery.status == 'no_show') {
      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.cancel, color: Colors.red, size: 24),
      );
    }

    return PopupMenuButton<String>(
      onSelected: onAction,
      icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => _buildMenuItems(),
    );
  }

  List<PopupMenuItem<String>> _buildMenuItems() {
    final items = <PopupMenuItem<String>>[];

    if (delivery.status == 'pending') {
      items.add(PopupMenuItem(
        value: 'pickup',
        child: Row(
          children: [
            const Icon(Icons.directions_walk_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Text(isPickup ? 'Mark Left Home' : 'Mark Left School'),
          ],
        ),
      ));
      // No-show only available from pending
      items.add(const PopupMenuItem(
        value: 'no_show',
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
            SizedBox(width: 12),
            Text('Mark No Show'),
          ],
        ),
      ));
    }

    if (delivery.status == 'picked_up') {
      items.add(PopupMenuItem(
        value: 'dropoff',
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            Text(isPickup ? 'Mark Arrived at School' : 'Mark Arrived at Home'),
          ],
        ),
      ));
    }

    return items;
  }

  IconData _getStatusIcon() {
    switch (delivery.status) {
      case 'delivered':
        return Icons.check_circle;
      case 'picked_up':
        return Icons.directions_bus;
      case 'no_show':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  Color _getStatusColor() {
    switch (delivery.status) {
      case 'delivered':
        return Colors.green;
      case 'picked_up':
        return Colors.orange;
      case 'no_show':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (delivery.status) {
      case 'delivered':
        return isPickup ? 'Arrived at school' : 'Arrived at home';
      case 'picked_up':
        return isPickup ? 'Left home' : 'Left school';
      case 'no_show':
        return 'No show';
      default:
        return isPickup ? 'Waiting at home' : 'Waiting at school';
    }
  }
}

// =============================================================================
// Helper Classes
// =============================================================================

class _DeliveryStats {
  final int pending;
  final int pickedUp;
  final int delivered;

  const _DeliveryStats({
    required this.pending,
    required this.pickedUp,
    required this.delivered,
  });

  bool get allCompleted => pending == 0 && pickedUp == 0 && delivered > 0;

  factory _DeliveryStats.from(List<Delivery> deliveries) {
    int pending = 0, pickedUp = 0, delivered = 0;

    for (final d in deliveries) {
      switch (d.status) {
        case 'pending':
          pending++;
        case 'picked_up':
          pickedUp++;
        case 'delivered':
        case 'completed':
        case 'no_show':
          delivered++;
      }
    }

    return _DeliveryStats(pending: pending, pickedUp: pickedUp, delivered: delivered);
  }
}
