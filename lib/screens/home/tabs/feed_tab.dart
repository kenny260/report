import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../models/incident_model.dart';
import '../../../providers/incident_provider.dart';
import '../../../widgets/category_chip.dart';
import '../../../widgets/incident_card.dart';
import '../../../widgets/loading_overlay.dart';
import '../../incident/incident_detail_screen.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidentProvider = context.watch<IncidentProvider>();
    final incidents = incidentProvider.incidents;

    return Column(
      children: [
        // Search & Filter Header Container
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // Search Input Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          incidentProvider.setSearchQuery(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search title, place, description...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    incidentProvider.setSearchQuery('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _showFilters ? Icons.filter_list_off : Icons.filter_list,
                      color:
                          (incidentProvider.selectedStatus != null ||
                              incidentProvider.selectedPriority != null)
                          ? AppTheme.primaryColor
                          : Colors.grey[700],
                    ),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    tooltip: 'Toggle Filters',
                  ),
                ],
              ),

              // Expandable Status / Priority Filters
              if (_showFilters) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _filterChoiceChip(
                        label: 'All',
                        isSelected: incidentProvider.selectedStatus == null,
                        onSelected: () => incidentProvider.setStatus(null),
                      ),
                      ...IncidentStatus.values.map(
                        (status) => _filterChoiceChip(
                          label: status.displayName,
                          isSelected: incidentProvider.selectedStatus == status,
                          onSelected: () => incidentProvider.setStatus(status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Priority: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _filterChoiceChip(
                        label: 'All',
                        isSelected: incidentProvider.selectedPriority == null,
                        onSelected: () => incidentProvider.setPriority(null),
                      ),
                      ...IncidentPriority.values.map(
                        (priority) => _filterChoiceChip(
                          label: priority.displayName,
                          isSelected:
                              incidentProvider.selectedPriority == priority,
                          onSelected: () =>
                              incidentProvider.setPriority(priority),
                        ),
                      ),
                      if (incidentProvider.selectedCategory != null ||
                          incidentProvider.selectedStatus != null ||
                          incidentProvider.selectedPriority != null ||
                          incidentProvider.searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            incidentProvider.clearFilters();
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Category Chips Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 10),
          child: CategoryChipBar(
            selectedCategory: incidentProvider.selectedCategory,
            onCategoryChanged: (category) {
              incidentProvider.setCategory(category);
            },
          ),
        ),

        const Divider(height: 1, thickness: 1),

        // Incident List / Feed
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              incidentProvider.initialize();
            },
            child: incidentProvider.isFeedLoading
                ? const Center(child: CircularProgressIndicator())
                : incidentProvider.feedError != null && incidents.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      EmptyStateWidget(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load incidents',
                        subtitle: incidentProvider.feedError!,
                        action: ElevatedButton.icon(
                          onPressed: incidentProvider.initialize,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ),
                    ],
                  )
                : incidents.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      EmptyStateWidget(
                        icon: Icons.find_in_page_outlined,
                        title: 'No Incidents Found',
                        subtitle: 'No reports match your current filters or search term.',
                        action: ElevatedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            incidentProvider.clearFilters();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Clear Filters'),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: incidents.length,
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemBuilder: (context, index) {
                      final incident = incidents[index];
                      return IncidentCard(
                        incident: incident,
                        onTap: () {
                          incidentProvider.selectIncident(incident);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  IncidentDetailScreen(incidentId: incident.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filterChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryDark : Colors.grey[700],
        ),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
