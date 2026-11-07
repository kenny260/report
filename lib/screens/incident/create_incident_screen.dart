import 'dart:io';

import 'package:flutter/material.dart';

import '../../widgets/photo_attachment_section.dart';
import '../../utils/validators.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/incident_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/loading_overlay.dart';

class CreateIncidentScreen extends StatefulWidget {
  const CreateIncidentScreen({super.key});

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customLocationController = TextEditingController();

  IncidentCategory _selectedCategory = IncidentCategory.brokenFacility;
  IncidentPriority _selectedPriority = IncidentPriority.medium;
  String _selectedLocation = AppConstants.campusLocations.first;
  bool _isCustomLocation = false;
  bool _isAnonymous = false;

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= AppConstants.maxImagesPerIncident) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum of ${AppConstants.maxImagesPerIncident} photos allowed per report.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 82,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Take a Photograph'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppTheme.secondaryColor,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final incidentProvider = Provider.of<IncidentProvider>(
      context,
      listen: false,
    );

    final user = authProvider.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit a report.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final location = _isCustomLocation
        ? _customLocationController.text.trim()
        : _selectedLocation;

    final success = await incidentProvider.createIncident(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      location: location,
      reportedBy: user.uid,
      reporterName: user.displayName,
      isAnonymous: _isAnonymous,
      images: _selectedImages.isNotEmpty ? _selectedImages : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Incident reported successfully! Our staff will review it.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final error = incidentProvider.errorMessage ?? 'Submission failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentProvider = context.watch<IncidentProvider>();

    return LoadingOverlay(
      isLoading: incidentProvider.isLoading,
      message: 'Uploading report and photographs...',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Report Campus Issue'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Picker Section
                const Text(
                  '1. Select Incident Category',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: IncidentCategory.values.map((category) {
                    final isSelected = _selectedCategory == category;
                    return CategoryChip(
                      category: category,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedCategory = category);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Issue Details Section
                const Text(
                  '2. Issue Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        CustomTextField(
                          controller: _titleController,
                          label: 'Incident Title',
                          hint: 'e.g. Broken water pipe in Cafeteria washroom',
                          prefixIcon: Icons.title,
                          maxLength: AppConstants.maxTitleLength,
                          validator: Validators.incidentTitle,
                        ),
                        const SizedBox(height: 14),

                        // Description
                        CustomTextField(
                          controller: _descriptionController,
                          label: 'Detailed Description',
                          hint: 'Describe what happened, exact room, severity, and any hazards...',
                          prefixIcon: Icons.description_outlined,
                          maxLines: 4,
                          maxLength: AppConstants.maxDescriptionLength,
                          validator: Validators.incidentDescription,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Location on Campus Section
                const Text(
                  '3. Campus Location',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLocation,
                          decoration: const InputDecoration(
                            labelText: 'Designated Location',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                          isExpanded: true,
                          items: AppConstants.campusLocations.map((loc) {
                            return DropdownMenuItem<String>(
                              value: loc,
                              child: Text(loc, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedLocation = val;
                                _isCustomLocation = (val == 'Other');
                              });
                            }
                          },
                        ),
                        if (_isCustomLocation) ...[
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _customLocationController,
                            label: 'Specific Location Details',
                            hint:
                                'Specify exact building, wing, room number...',
                            prefixIcon: Icons.edit_location_alt_outlined,
                            validator: (value) {
                              if (_isCustomLocation &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please specify the exact location';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Priority Selection
                const Text(
                  '4. Perceived Urgency / Priority',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: IncidentPriority.values.map((priority) {
                        final isSelected = _selectedPriority == priority;
                        final color = AppTheme.getPriorityColor(priority.name);
                        return ChoiceChip(
                          label: Text(priority.displayName),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedPriority = priority);
                          },
                          selectedColor: color.withValues(alpha: 0.2),
                          side: BorderSide(
                            color: isSelected ? color : Colors.grey[300]!,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? color : Colors.grey[700],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Image attachments (uploaded to Firebase Storage on submit)
                PhotoAttachmentSection(
                  images: _selectedImages,
                  maxImages: AppConstants.maxImagesPerIncident,
                  onAdd: _showImageSourceActionSheet,
                  onRemove: (index) =>
                      setState(() => _selectedImages.removeAt(index)),
                ),

                const SizedBox(height: 16),

                // Privacy: hide the reporter's name from other students
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SwitchListTile(
                    value: _isAnonymous,
                    onChanged: (value) => setState(() => _isAnonymous = value),
                    activeThumbColor: AppTheme.primaryColor,
                    secondary: const Icon(Icons.visibility_off_outlined),
                    title: const Text(
                      'Report anonymously',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Your name is hidden from other students. Campus staff '
                      'can still see who submitted it, so they can follow up '
                      'and prevent misuse.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: incidentProvider.isLoading
                        ? null
                        : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Submit Incident Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
