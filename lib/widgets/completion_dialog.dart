import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/firebase_goal_service.dart';
import '../services/content_moderation_service.dart';

class CompletionDialog extends StatefulWidget {
  final String goalId;
  final String? milestoneId;
  final String title;
  final VoidCallback onCompleted;

  const CompletionDialog({
    Key? key,
    required this.goalId,
    this.milestoneId,
    required this.title,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<CompletionDialog> {
  final _noteController = TextEditingController();
  final _goalService = FirebaseGoalService();
  final _contentModerationService = ContentModerationService();
  bool _isLoading = false;
  String? _photoUrl;
  File? _photoFile;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      // Show source selection dialog first
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Photo Source'),
            content: const Text('Choose how you want to add your photo:'),
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
        // Check current camera permission status
        final cameraStatus = await Permission.camera.status;
        print('Camera permission status: $cameraStatus');
        
        if (cameraStatus.isGranted) {
          hasPermission = true;
        } else if (cameraStatus.isDenied) {
          // Request camera permission - this will show the system dialog
          final result = await Permission.camera.request();
          print('Camera permission request result: $result');
          hasPermission = result.isGranted;
        } else if (cameraStatus.isPermanentlyDenied) {
          // Permission permanently denied, direct to settings
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Camera Permission Required'),
                content: const Text(
                  'Camera access has been permanently denied. Please enable it in your device settings to take photos.',
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
          return;
        }
        
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Camera access is required to take photos'),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      } else {
        // For gallery access, handle different Android versions
        if (Platform.isAndroid) {
          // Check current permission status for photos (Android 13+)
          var photosStatus = await Permission.photos.status;
          print('Photos permission status: $photosStatus');
          
          if (photosStatus.isGranted) {
            hasPermission = true;
          } else if (photosStatus.isDenied) {
            // Request photos permission - this will show the system dialog
            var photosResult = await Permission.photos.request();
            print('Photos permission request result: $photosResult');
            
            if (photosResult.isGranted) {
              hasPermission = true;
            } else {
              // Fall back to storage permission for older versions
              var storageStatus = await Permission.storage.status;
              print('Storage permission status: $storageStatus');
              
              if (storageStatus.isGranted) {
                hasPermission = true;
              } else if (storageStatus.isDenied) {
                var storageResult = await Permission.storage.request();
                print('Storage permission request result: $storageResult');
                hasPermission = storageResult.isGranted;
              }
            }
          } else if (photosStatus.isPermanentlyDenied) {
            // Try storage permission as fallback
            var storageStatus = await Permission.storage.status;
            if (storageStatus.isGranted) {
              hasPermission = true;
            } else if (storageStatus.isDenied) {
              var storageResult = await Permission.storage.request();
              hasPermission = storageResult.isGranted;
            } else if (storageStatus.isPermanentlyDenied) {
              // Both permissions permanently denied
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Photo Access Required'),
                    content: const Text(
                      'Photo library access has been permanently denied. Please enable it in your device settings to select photos.',
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
              return;
            }
          }
        } else {
          // iOS photos permission
          var photosStatus = await Permission.photos.status;
          print('iOS Photos permission status: $photosStatus');
          
          if (photosStatus.isGranted) {
            hasPermission = true;
          } else if (photosStatus.isDenied) {
            // Request photos permission - this will show the system dialog
            var photosResult = await Permission.photos.request();
            print('iOS Photos permission request result: $photosResult');
            hasPermission = photosResult.isGranted;
          } else if (photosStatus.isPermanentlyDenied) {
            // Permission permanently denied, direct to settings
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Photo Access Required'),
                  content: const Text(
                    'Photo library access has been permanently denied. Please enable it in your device settings to select photos.',
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
            return;
          }
        }
        
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Photo library access is required to select photos'),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }

      print('Attempting to pick image from ${source.name}...');
      
      // Use a fresh instance of ImagePicker for each request
      final picker = ImagePicker();
      
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
        requestFullMetadata: false, // Avoid metadata issues
      );

      if (image != null) {
        print('Photo selected successfully: ${image.path}');
        // Verify the file exists before setting it
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
          print('Analyzing image content for moderation...');
          final moderationResult = await _contentModerationService.analyzeImage(file);
          
          // Hide loading indicator
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
          
          print('Content moderation result: $moderationResult');
          
          if (moderationResult.isAppropriate) {
            // Photo is appropriate, set it as the selected photo
            setState(() {
              _photoFile = file;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photo accepted!'),
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
                        'Please select a different photo that shows your achievement without inappropriate content.',
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
                        _pickPhoto(); // Let user try again
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }
          }
        } else {
          throw Exception('Selected file does not exist');
        }
      } else {
        print('No photo selected by user');
      }
    } catch (e) {
      print('Error picking photo: $e');
      if (mounted) {
        String errorMessage = 'Error accessing camera/gallery';
        
        // Provide specific error messages for common issues
        if (e.toString().contains('channel-error')) {
          errorMessage = 'Camera service unavailable. Try restarting the app or using gallery instead.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Camera or storage permission denied. Please enable in settings.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _photoFile = null;
      _photoUrl = null;
    });
  }

  Future<void> _complete() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? photoUrl;
      
      // Upload photo if selected
      if (_photoFile != null) {
        final type = widget.milestoneId != null ? 'milestone' : 'goal';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.goalId}.jpg';
        final path = 'goals/${widget.goalId}/$type/$fileName';
        
        print('Attempting to upload photo...');
        photoUrl = await _goalService.uploadPhoto(_photoFile!, path);
        
        if (photoUrl == null) {
          // Photo upload failed, ask user if they want to continue without photo
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Photo Upload Failed'),
              content: const Text(
                'Unable to upload photo. This might be due to:\n\n'
                '• Firebase Storage not enabled\n'
                '• Network connection issues\n'
                '• Storage permissions\n\n'
                'Would you like to complete without the photo?'
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
          
          photoUrl = null; // Continue without photo
        } else {
          print('Photo uploaded successfully: $photoUrl');
        }
      }

      final note = _noteController.text.trim();
      
      // Complete milestone or goal
      if (widget.milestoneId != null) {
        await _goalService.completeMilestone(
          widget.goalId,
          widget.milestoneId!,
          note: note.isNotEmpty ? note : null,
          photoUrl: photoUrl,
        );
      } else {
        await _goalService.completeGoalWithDetails(
          goalId: widget.goalId,
          note: note.isNotEmpty ? note : null,
          photoUrl: photoUrl,
        );
      }

      widget.onCompleted();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.milestoneId != null ? 'Milestone' : 'Goal'} completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing: $e')),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Complete ${widget.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations on completing "${widget.title}"!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Photo section
            if (_photoFile != null) ...[
              const Text('Proof Photo:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    _photoFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Retake'),
                  ),
                  TextButton.icon(
                    onPressed: _removePhoto,
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Add Proof Photo (Optional)'),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Note section
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Completion Note (Optional)',
                hintText: 'Add a note about your achievement...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _complete,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Complete'),
        ),
      ],
    );
  }
}

// Helper function to show completion dialog
Future<void> showCompletionDialog(
  BuildContext context, {
  required String goalId,
  String? milestoneId,
  required String title,
  required VoidCallback onCompleted,
}) {
  return showDialog(
    context: context,
    builder: (context) => CompletionDialog(
      goalId: goalId,
      milestoneId: milestoneId,
      title: title,
      onCompleted: onCompleted,
    ),
  );
} 