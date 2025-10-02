import 'package:flutter/foundation.dart';

class WorkerTaskService extends ChangeNotifier {
  static final WorkerTaskService _instance = WorkerTaskService._internal();
  factory WorkerTaskService() => _instance;
  WorkerTaskService._internal();

  List<Map<String, String>> _pendingComplaints = [
    {
      "id": "1",
      "title": "Pothole on Main Street",
      "description": "Large pothole near school causing vehicle damage",
      "location": "Main Street, near Central School",
      "priority": "High",
    },
    {
      "id": "2", 
      "title": "Streetlight not working",
      "description": "Dark area near park creating safety concerns",
      "location": "Oak Park entrance",
      "priority": "Medium",
    },
    {
      "id": "3",
      "title": "Garbage collection missed",
      "description": "Residential area garbage not collected for 3 days",
      "location": "Residential Block A",
      "priority": "Low",
    },
    {
      "id": "4",
      "title": "Broken sidewalk",
      "description": "Cracked sidewalk tiles causing tripping hazard",
      "location": "Downtown shopping district",
      "priority": "Medium",
    },
  ];

  List<Map<String, String>> _completedComplaints = [
    {
      "id": "5",
      "title": "Water leak fixed",
      "description": "Water main leak repaired successfully",
      "location": "Industrial area",
      "priority": "High",
      "completedAt": "2024-01-15 14:30",
    },
    {
      "id": "6",
      "title": "Traffic signal repaired",
      "description": "Malfunctioning traffic light restored",
      "location": "Main intersection",
      "priority": "High", 
      "completedAt": "2024-01-14 10:15",
    },
  ];

  List<Map<String, String>> get pendingComplaints => List.unmodifiable(_pendingComplaints);
  List<Map<String, String>> get completedComplaints => List.unmodifiable(_completedComplaints);
  
  int get pendingCount => _pendingComplaints.length;
  int get completedCount => _completedComplaints.length;

  void markComplaintAsCompleted(String complaintId) {
    final complaintIndex = _pendingComplaints.indexWhere((c) => c["id"] == complaintId);
    if (complaintIndex != -1) {
      final complaint = Map<String, String>.from(_pendingComplaints[complaintIndex]);
      complaint["completedAt"] = DateTime.now().toString();
      
      _pendingComplaints.removeAt(complaintIndex);
      _completedComplaints.insert(0, complaint);
      
      notifyListeners();
    }
  }

  void addNewPendingComplaint(Map<String, String> complaint) {
    complaint["id"] = DateTime.now().millisecondsSinceEpoch.toString();
    _pendingComplaints.insert(0, complaint);
    notifyListeners();
  }

  void refreshTasks() {
    // Simulate refresh - in real app, this would fetch from API
    notifyListeners();
  }
}
