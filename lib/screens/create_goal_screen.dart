import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/firebase_goal.dart';
import '../services/firebase_goal_service.dart';
import '../services/content_moderation_service.dart';
import '../utils/date_formatter.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _unitController = TextEditingController();
  final _stakeController = TextEditingController();
  final _milestonesController = TextEditingController();
  
  GoalCategory _selectedCategory = GoalCategory.health;
  DateTime? _endDate;
  bool _isLoading = false;
  File? _proofPhoto;
  
  final FirebaseGoalService _goalService = FirebaseGoalService();
  final ContentModerationService _contentModerationService = ContentModerationService();

  @override
  void initState() {
    super.initState();
    _goalService.initialize();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    _stakeController.dispose();
    _milestonesController.dispose();
    super.dispose();
  }

  Future<void> _pickProofPhoto() async {
    try {
      // Show source selection dialog first
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Photo Source'),
            content: const Text('Choose how you want to add your starting proof photo:'),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (source == null) return;

      // Request appropriate permissions based on selected source
      bool hasPermission = false;
      
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.status;
        if (cameraStatus.isGranted) {
          hasPermission = true;
        } else if (cameraStatus.isDenied) {
          final result = await Permission.camera.request();
          hasPermission = result.isGranted;
        } else if (cameraStatus.isPermanentlyDenied) {
          _showPermissionDeniedDialog('Camera', 'take photos');
          return;
        }
      } else {
        // Gallery permissions
        if (Platform.isAndroid) {
          var photosStatus = await Permission.photos.status;
          if (photosStatus.isGranted) {
            hasPermission = true;
          } else if (photosStatus.isDenied) {
            var photosResult = await Permission.photos.request();
            if (photosResult.isGranted) {
              hasPermission = true;
            } else {
              var storageStatus = await Permission.storage.status;
              if (storageStatus.isGranted) {
                hasPermission = true;
              } else if (storageStatus.isDenied) {
                var storageResult = await Permission.storage.request();
                hasPermission = storageResult.isGranted;
              }
            }
          } else if (photosStatus.isPermanentlyDenied) {
            _showPermissionDeniedDialog('Photo Library', 'select photos');
            return;
          }
        } else {
          // iOS
          var photosStatus = await Permission.photos.status;
          if (photosStatus.isGranted) {
            hasPermission = true;
          } else if (photosStatus.isDenied) {
            var photosResult = await Permission.photos.request();
            hasPermission = photosResult.isGranted;
          } else if (photosStatus.isPermanentlyDenied) {
            _showPermissionDeniedDialog('Photo Library', 'select photos');
            return;
          }
        }
      }

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${source == ImageSource.camera ? 'Camera' : 'Photo library'} access is required'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      // Pick image
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);
        if (await file.exists()) {
          // Show loading indicator while analyzing content
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('Analyzing photo content...'),
                  ],
                ),
                duration: Duration(seconds: 10),
              ),
            );
          }
          
          // Analyze image content for inappropriate material
          final moderationResult = await _contentModerationService.analyzeImage(file);
          
          // Hide loading indicator
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
          
          if (moderationResult.isAppropriate) {
            // Photo is appropriate, set it as the proof photo
            setState(() {
              _proofPhoto = file;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Starting proof photo accepted!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            // Photo contains inappropriate content, reject it
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Photo Rejected'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'The selected photo contains inappropriate content and cannot be used as proof.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Reason: ${moderationResult.details}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Please select a different photo that shows your commitment to starting this goal.',
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _pickProofPhoto(); // Let user try again
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking photo: $e')),
        );
      }
    }
  }

  void _showPermissionDeniedDialog(String permission, String purpose) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
          '$permission access has been permanently denied. Please enable it in your device settings to $purpose.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _removeProofPhoto() {
    setState(() {
      _proofPhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Goal'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 32),
              _buildCategorySection(),
              const SizedBox(height: 32),
              _buildTargetSection(),
              const SizedBox(height: 32),
              _buildDeadlineSection(),
              const SizedBox(height: 32),
              _buildStakeSection(),
              const SizedBox(height: 32),
              _buildMilestonesSection(),
              const SizedBox(height: 32),
              _buildProofSection(),
              const SizedBox(height: 32),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProofSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Starting Proof (Optional)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a photo showing your commitment to starting this goal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_proofPhoto != null) ...[
              const Text('Starting Proof Photo:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _proofPhoto!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _pickProofPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Retake'),
                  ),
                  TextButton.icon(
                    onPressed: _removeProofPhoto,
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickProofPhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Add Starting Proof Photo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                hintText: 'What do you want to achieve?',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a goal title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your goal in detail',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: GoalCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        size: 18,
                        color: isSelected ? Colors.white : category.color,
                      ),
                      const SizedBox(width: 8),
                      Text(category.displayName),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  backgroundColor: category.color.withValues(alpha: 0.1),
                  selectedColor: category.color,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _targetController,
                    decoration: const InputDecoration(
                      labelText: 'Target Value',
                      hintText: '10',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a target value';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      hintText: 'lbs',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a unit';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deadline (Optional)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectEndDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _endDate != null 
                          ? DateFormatter.formatDate(_endDate!)
                          : 'Select deadline',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _endDate != null 
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    if (_endDate != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStakeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stakes (Optional)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add financial stakes to increase commitment',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stakeController,
              decoration: const InputDecoration(
                labelText: 'Stake Amount',
                hintText: '50',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Milestones (Optional)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Break down your goal into smaller milestones (one per line)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _milestonesController,
              decoration: const InputDecoration(
                labelText: 'Milestones',
                hintText: 'Lose 5 lbs\nLose 10 lbs\nLose 15 lbs',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedCategory.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Create Goal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? proofPhotoUrl;
      
      // Upload proof photo if selected
      if (_proofPhoto != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_starting_proof.jpg';
        final path = 'goals/starting_proof/$fileName';
        
        proofPhotoUrl = await _goalService.uploadPhoto(_proofPhoto!, path);
        
        if (proofPhotoUrl == null) {
          // Photo upload failed, ask user if they want to continue without photo
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Photo Upload Failed'),
              content: const Text(
                'Unable to upload starting proof photo. This might be due to:\n\n'
                '• Firebase Storage not enabled\n'
                '• Network connection issues\n'
                '• Storage permissions\n\n'
                'Would you like to create the goal without the photo?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue Without Photo'),
                ),
              ],
            ),
          );
          
          if (shouldContinue != true) {
            return; // User chose to cancel
          }
        }
      }

      // Parse milestones
      List<String> milestones = [];
      if (_milestonesController.text.isNotEmpty) {
        milestones = _milestonesController.text
            .split('\n')
            .where((text) => text.trim().isNotEmpty)
            .map((text) => text.trim())
            .toList();
      }

      // Create goal using the service method signature
      await _goalService.createGoal(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        startDate: DateTime.now(),
        endDate: _endDate,
        targetValue: double.parse(_targetController.text.trim()),
        unit: _unitController.text.trim(),
        stakeAmount: _stakeController.text.isNotEmpty 
            ? double.parse(_stakeController.text.trim())
            : 0.0,
        milestones: milestones,
        imageUrl: proofPhotoUrl, // Include the starting proof photo
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(proofPhotoUrl != null 
              ? 'Goal created successfully with starting proof!'
              : 'Goal created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating goal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 