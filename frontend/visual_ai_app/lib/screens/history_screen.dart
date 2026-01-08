import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/prediction_card.dart';
import '../widgets/network_status_indicator.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.newest;
  double _confidenceThreshold = 0.0;
  bool _showFailedOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter predictions',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sort predictions',
          ),
        ],
      ),
      body: Column(
        children: [
          const NetworkStatusIndicator(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search predictions...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                final predictions = _filterAndSortPredictions(
                  appState.getAllPredictions(),
                );

                if (predictions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No predictions yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _confidenceThreshold > 0 ||
                            _showFailedOnly) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => appState.syncOfflinePredictions(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: predictions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final prediction = predictions[index];
                      return PredictionCard(
                        prediction: prediction,
                        onTap: () => _showPredictionDetails(prediction),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterAndSortPredictions(
    List<Map<String, dynamic>> predictions,
  ) {
    var filtered = predictions.where((prediction) {
      final label = prediction['label'].toString().toLowerCase();
      final confidence = prediction['confidence'] as double;
      final isFailed = prediction['is_synced'] == -1;

      if (_showFailedOnly && !isFailed) return false;
      if (confidence < _confidenceThreshold) return false;
      if (_searchQuery.isNotEmpty &&
          !label.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();

    switch (_sortOption) {
      case _SortOption.newest:
        filtered.sort((a, b) => DateTime.parse(b['timestamp'] as String)
            .compareTo(DateTime.parse(a['timestamp'] as String)));
      case _SortOption.oldest:
        filtered.sort((a, b) => DateTime.parse(a['timestamp'] as String)
            .compareTo(DateTime.parse(b['timestamp'] as String)));
      case _SortOption.highestConfidence:
        filtered.sort((a, b) =>
            (b['confidence'] as double).compareTo(a['confidence'] as double));
      case _SortOption.lowestConfidence:
        filtered.sort((a, b) =>
            (a['confidence'] as double).compareTo(b['confidence'] as double));
    }

    return filtered;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Predictions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Minimum confidence'),
              Slider(
                value: _confidenceThreshold,
                onChanged: (value) => setState(() => _confidenceThreshold = value),
                divisions: 20,
                label: '${(_confidenceThreshold * 100).round()}%',
              ),
              SwitchListTile(
                title: const Text('Show failed only'),
                value: _showFailedOnly,
                onChanged: (value) => setState(() => _showFailedOnly = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearFilters();
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                this.setState(() {});
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sort by'),
        children: _SortOption.values.map((option) {
          return RadioListTile<_SortOption>(
            title: Text(option.label),
            value: option,
            groupValue: _sortOption,
            onChanged: (value) {
              Navigator.pop(context);
              setState(() => _sortOption = value!);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showPredictionDetails(Map<String, dynamic> prediction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: PredictionCard(
                  prediction: prediction,
                  showImage: true,
                  isExpanded: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _confidenceThreshold = 0.0;
      _showFailedOnly = false;
    });
  }
}

enum _SortOption {
  newest('Newest first'),
  oldest('Oldest first'),
  highestConfidence('Highest confidence'),
  lowestConfidence('Lowest confidence');

  final String label;
  const _SortOption(this.label);
} 