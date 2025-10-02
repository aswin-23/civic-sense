import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:io';
import 'complaint_detail_screen.dart';
import '../models/complaint_item.dart';
import '../services/gemini_service.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final TextEditingController _complaintController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SpeechToText _speechToText = SpeechToText();
  
  List<ComplaintItem> _complaints = [];
  File? _selectedMedia;
  String _locationText = 'Getting location...';
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  double? _latitude;
  double? _longitude;
  bool _isImage = true; // true for image, false for video
  
  // Speech-to-text variables
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _addDummyComplaints();
    _initSpeech();
    _complaintController.addListener(() {
      setState(() {}); // Update character count
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    // Check microphone permission first
    PermissionStatus permissionStatus = await Permission.microphone.status;
    
    if (permissionStatus.isDenied) {
      permissionStatus = await Permission.microphone.request();
    }
    
    if (permissionStatus.isGranted) {
      if (!_speechEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        onSoundLevelChange: (level) {
          // Optional: Handle sound level changes
        },
      );
      
      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required to use speech-to-text.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _onSpeechResult(result) {
    if (mounted) {
      setState(() {
        _lastWords = result.recognizedWords;
        // Update text field with live transcription
        _complaintController.text = _lastWords;
      });
    }
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  void _addDummyComplaints() {
    _complaints = [
      ComplaintItem(
        id: '1',
        description: 'Pothole on Main Street near the intersection',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        imagePath: '/dummy/image1.jpg',
        status: 'Pending',
      ),
      ComplaintItem(
        id: '2',
        description: 'Broken streetlight on Oak Avenue',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'In Progress',
      ),
      ComplaintItem(
        id: '3',
        description: 'Garbage collection missed on Pine Street',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        videoPath: '/dummy/video1.mp4',
        status: 'Resolved',
      ),
    ];
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Location services disabled';
          _isLoadingLocation = false;
        });
        _showLocationError('Please enable location services in your device settings.');
        return;
      }

      // Check permissions using permission_handler
      PermissionStatus permissionStatus = await Permission.location.status;
      
      if (permissionStatus.isDenied) {
        permissionStatus = await Permission.location.request();
        if (permissionStatus.isDenied) {
          setState(() {
            _locationText = 'Location permission denied';
            _isLoadingLocation = false;
          });
          _showLocationError('Location permission is required to report issues.');
          return;
        }
      }

      if (permissionStatus.isPermanentlyDenied) {
        setState(() {
          _locationText = 'Location permission permanently denied';
          _isLoadingLocation = false;
        });
        _showLocationError('Location permission is permanently denied. Please enable it in app settings.');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationText = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
        _isLoadingLocation = false;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location obtained successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _locationText = 'Location unavailable';
        _isLoadingLocation = false;
      });
      _showLocationError('Failed to get location: ${e.toString()}');
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check current permission status first
      PermissionStatus permissionStatus = await Permission.location.status;
      
      if (permissionStatus.isGranted) {
        // Permission already granted, get location
        await _getCurrentLocation();
      } else if (permissionStatus.isDenied) {
        // Request permission
        permissionStatus = await Permission.location.request();
        
        if (permissionStatus.isGranted) {
          await _getCurrentLocation();
        } else if (permissionStatus.isDenied) {
          setState(() {
            _locationText = 'Location permission denied';
            _isLoadingLocation = false;
          });
          _showLocationError('Location permission denied. Enable from settings to use this feature.');
        } else if (permissionStatus.isPermanentlyDenied) {
          setState(() {
            _locationText = 'Location permission permanently denied';
            _isLoadingLocation = false;
          });
          _showLocationError('Location permission is permanently denied. Please enable it in app settings.');
        }
      } else if (permissionStatus.isPermanentlyDenied) {
        setState(() {
          _locationText = 'Location permission permanently denied';
          _isLoadingLocation = false;
        });
        _showLocationError('Location permission is permanently denied. Please enable it in app settings.');
      } else if (permissionStatus.isRestricted) {
        setState(() {
          _locationText = 'Location access restricted';
          _isLoadingLocation = false;
        });
        _showLocationError('Location access is restricted on this device.');
      }
    } catch (e) {
      setState(() {
        _locationText = 'Location unavailable';
        _isLoadingLocation = false;
      });
      _showLocationError('Failed to request location permission: ${e.toString()}');
    }
  }

  void _showLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _requestLocationPermission,
          ),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedMedia = File(image.path);
          _isImage = true;
        });
      }
    } catch (e) {
      _showMediaError('Error capturing image: ${e.toString()}');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      
      if (video != null) {
        setState(() {
          _selectedMedia = File(video.path);
          _isImage = false;
        });
      }
    } catch (e) {
      _showMediaError('Error recording video: ${e.toString()}');
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedMedia = null;
    });
  }

  void _showMediaError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitComplaint() async {
    if (_complaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a complaint message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare the payload for Gemini API
      final payload = {
        'description': _complaintController.text.trim(),
        'location': {
          'lat': _latitude,
          'long': _longitude,
        },
        'media': _selectedMedia != null ? [_selectedMedia!.path] : [],
        'audio_transcription': _lastWords,
      };

      // Process with Gemini API
      final processedComplaint = await GeminiService.processComplaint(payload);
      
      // Show confirmation dialog
      _showConfirmationDialog(processedComplaint);
      
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing complaint: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConfirmationDialog(Map<String, dynamic> processedComplaint) {
    final TextEditingController complaintIdController = TextEditingController(text: processedComplaint['complaint_id'] ?? '');
    final TextEditingController titleController = TextEditingController(text: processedComplaint['complaint_title'] ?? '');
    final TextEditingController statusController = TextEditingController(text: processedComplaint['status'] ?? '');
    final TextEditingController departmentController = TextEditingController(text: processedComplaint['department'] ?? '');
    final TextEditingController mobileController = TextEditingController(text: processedComplaint['mobile_number'] ?? '');
    final TextEditingController priorityController = TextEditingController(text: processedComplaint['priority'] ?? '');
    final TextEditingController categoryController = TextEditingController(text: processedComplaint['category'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: Colors.blue, size: 28),
              SizedBox(width: 12),
              Text('Review Complaint'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please review and edit the complaint details:'),
                const SizedBox(height: 16),
                TextField(
                  controller: complaintIdController,
                  decoration: const InputDecoration(
                    labelText: 'Complaint ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: statusController,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: mobileController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priorityController,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _isSubmitting = false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _acceptComplaint(processedComplaint, {
                  'complaint_id': complaintIdController.text,
                  'complaint_title': titleController.text,
                  'status': statusController.text,
                  'department': departmentController.text,
                  'mobile_number': mobileController.text,
                  'priority': priorityController.text,
                  'category': categoryController.text,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  void _acceptComplaint(Map<String, dynamic> originalData, Map<String, dynamic> editedData) {
    // Create the final complaint
    final finalComplaint = {
      ...originalData,
      ...editedData,
    };

    // Add to complaints list
    final newComplaint = ComplaintItem(
      id: finalComplaint['complaint_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      description: finalComplaint['original_description'] ?? '',
      createdAt: DateTime.parse(finalComplaint['submitted_at'] ?? DateTime.now().toIso8601String()),
      imagePath: finalComplaint['media']?.isNotEmpty == true && _isImage ? finalComplaint['media'][0] : null,
      videoPath: finalComplaint['media']?.isNotEmpty == true && !_isImage ? finalComplaint['media'][0] : null,
      status: finalComplaint['status'] ?? 'Pending',
      title: finalComplaint['complaint_title'],
      department: finalComplaint['department'],
      mobileNumber: finalComplaint['mobile_number'],
      priority: finalComplaint['priority'],
      category: finalComplaint['category'],
      audioTranscription: finalComplaint['audio_transcription'],
    );

    setState(() {
      _complaints.insert(0, newComplaint);
      _complaintController.clear();
      _selectedMedia = null;
      _lastWords = '';
      _isSubmitting = false;
    });

    // Show success dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Success!'),
            ],
          ),
          content: const Text('Complaint submitted successfully!'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Report Civic Issue'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            tooltip: 'View History',
          ),
        ],
      ),
      endDrawer: _buildComplaintsDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Report New Issue',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help improve your community by reporting civic issues',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              
              // Media Capture Section
              _buildMediaSection(),
              const SizedBox(height: 24),
              
              // Location Section
              _buildLocationSection(),
              const SizedBox(height: 24),
              
              // Complaint Message Section
              _buildMessageSection(),
              const SizedBox(height: 32),
              
              // Submit Button
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Capture Media (Optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('Record Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedMedia != null) ...[
          const SizedBox(height: 16),
          _buildMediaPreview(),
        ],
      ],
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _isImage
                ? Image.file(
                    _selectedMedia!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Video Selected',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _removeMedia,
                iconSize: 20,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isImage ? 'Photo' : 'Video',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: _isLoadingLocation ? Colors.grey : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoadingLocation ? _locationText : _getLocationDescription(),
                      style: TextStyle(
                        fontSize: 14,
                        color: _isLoadingLocation ? Colors.grey : Colors.black87,
                      ),
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Accuracy: ${_getLocationAccuracy()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isLoadingLocation)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Share Location Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoadingLocation ? null : _requestLocationPermission,
            icon: _isLoadingLocation 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.location_searching),
            label: Text(_isLoadingLocation ? 'Getting Location...' : 'Share Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Complaint Message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Microphone button
            IconButton(
              onPressed: _speechEnabled
                  ? (_isListening ? _stopListening : _startListening)
                  : null,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Colors.blue,
                size: 28,
              ),
              tooltip: _isListening ? 'Stop recording' : 'Start voice input',
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _complaintController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the issue in detail...\n\nExample: "There is a large pothole on Main Street near the intersection with Oak Avenue. It\'s causing damage to vehicles and is a safety hazard."',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: _isListening
                ? Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.red,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${_complaintController.text.length} characters',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (_isListening) ...[
              const SizedBox(width: 16),
              Text(
                'Listening...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitComplaint,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Submitting...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send),
                  SizedBox(width: 8),
                  Text(
                    'Submit Complaint',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildComplaintsDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
            ),
            child: const Row(
              children: [
                Icon(Icons.history, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Text(
                  'Complaints History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _complaints.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No complaints yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Submit your first complaint!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = _complaints[index];
                      return _buildComplaintCard(complaint);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintItem complaint) {
    return GestureDetector(
      onTap: () => _navigateToComplaintDetail(complaint),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  complaint.hasMedia
                      ? (complaint.isImage ? Icons.image : Icons.videocam)
                      : Icons.text_fields,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatTimestamp(complaint.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              complaint.message,
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToComplaintDetail(ComplaintItem complaint) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintDetailScreen(complaint: complaint),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }

  String _getLocationAccuracy() {
    // This would normally come from the position accuracy
    return 'High';
  }

  String _getLocationDescription() {
    if (_latitude == null || _longitude == null) {
      return 'Location not available';
    }
    
    // For demo purposes, return a formatted location
    // In a real app, you'd use reverse geocoding to get the actual address
    return 'Current Location (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})';
  }
}

