import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'production_context_menu_service.dart';
import 'context_menu_config_service.dart';

class ProcessingActivity {
  final String id;
  final DateTime timestamp;
  final String operation;
  final String originalText;
  final String processedText;
  final String sourceApp;
  final double processingTime;
  final bool success;
  final String? error;

  const ProcessingActivity({
    required this.id,
    required this.timestamp,
    required this.operation,
    required this.originalText,
    required this.processedText,
    required this.sourceApp,
    required this.processingTime,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'operation': operation,
      'originalText': originalText,
      'processedText': processedText,
      'sourceApp': sourceApp,
      'processingTime': processingTime,
      'success': success,
      'error': error,
    };
  }

  factory ProcessingActivity.fromJson(Map<String, dynamic> json) {
    return ProcessingActivity(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      operation: json['operation'] ?? '',
      originalText: json['originalText'] ?? '',
      processedText: json['processedText'] ?? '',
      sourceApp: json['sourceApp'] ?? 'Unknown',
      processingTime: (json['processingTime'] ?? 0.0).toDouble(),
      success: json['success'] ?? false,
      error: json['error'],
    );
  }

  ProcessingActivity copyWith({
    String? id,
    DateTime? timestamp,
    String? operation,
    String? originalText,
    String? processedText,
    String? sourceApp,
    double? processingTime,
    bool? success,
    String? error,
  }) {
    return ProcessingActivity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      operation: operation ?? this.operation,
      originalText: originalText ?? this.originalText,
      processedText: processedText ?? this.processedText,
      sourceApp: sourceApp ?? this.sourceApp,
      processingTime: processingTime ?? this.processingTime,
      success: success ?? this.success,
      error: error ?? this.error,
    );
  }
}

class ActivityStats {
  final int totalActivities;
  final int todayActivities;
  final double averageProcessingTime;
  final String mostUsedOperation;
  final int successfulActivities;
  final int failedActivities;
  final Map<String, int> operationCounts;
  final Map<String, int> sourceAppCounts;

  const ActivityStats({
    required this.totalActivities,
    required this.todayActivities,
    required this.averageProcessingTime,
    required this.mostUsedOperation,
    required this.successfulActivities,
    required this.failedActivities,
    required this.operationCounts,
    required this.sourceAppCounts,
  });
}

class ActivityService {
  static const String _activitiesKey = 'processing_activities';
  static const int _maxActivities = 1000; // Maximum activities to store

  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final List<ProcessingActivity> _activities = [];
  final StreamController<List<ProcessingActivity>> _activitiesController = 
      StreamController<List<ProcessingActivity>>.broadcast();
  
  StreamSubscription<ContextMenuAction>? _menuActionSubscription;
  bool _initialized = false;

  // Getters
  List<ProcessingActivity> get activities => List.unmodifiable(_activities);
  Stream<List<ProcessingActivity>> get activitiesStream => _activitiesController.stream;
  bool get isInitialized => _initialized;

  /// Initialize the activity service
  Future<void> initialize() async {
    print('ActivityService: Initialize called. Already initialized: $_initialized');
    
    if (_initialized) {
      print('ActivityService: Already initialized, skipping reload. Current activity count: ${_activities.length}');
      return;
    }

    print('ActivityService: Starting initialization...');
    
    // Load stored activities
    await _loadActivities();

    // Listen to context menu actions
    _subscribeToMenuActions();

    _initialized = true;
    print('ActivityService: Initialization complete. Activity count: ${_activities.length}');
  }

  /// Subscribe to context menu actions to track activities
  void _subscribeToMenuActions() {
    final contextMenuService = ProductionContextMenuService();
    
    _menuActionSubscription = contextMenuService.actionStream.listen((action) {
      _processContextMenuAction(action);
    });
  }

  /// Convert ContextMenuAction to ProcessingActivity
  void _processContextMenuAction(ContextMenuAction action) {
    final activity = ProcessingActivity(
      id: _generateId(),
      timestamp: action.timestamp,
      operation: action.menuId, // Use the actual menu ID instead of extracting
      originalText: action.originalText,
      processedText: action.processedText,
      sourceApp: _detectSourceApp(),
      processingTime: _calculateProcessingTime(action),
      success: action.success,
      error: action.error,
    );

    addActivity(activity);
  }

  /// Get display name for operation using context menu configurations
  Future<String> _getOperationDisplayName(String menuId) async {
    try {
      final configs = await ContextMenuConfigService.getEnabledConfigs();
      final config = configs.where((c) => c.id == menuId).firstOrNull;
      return config?.label ?? menuId;
    } catch (e) {
      return menuId; // Fallback to menu ID if configs can't be loaded
    }
  }

  /// Detect source application (simplified for now)
  String _detectSourceApp() {
    // TODO: Implement actual source app detection
    // For now, return a generic value
    return 'System';
  }

  /// Calculate processing time (simplified estimation)
  double _calculateProcessingTime(ContextMenuAction action) {
    // Estimate based on text length
    final textLength = action.originalText.length;
    final baseTime = 0.5; // Base processing time
    final timePerChar = 0.01; // Time per character
    
    return baseTime + (textLength * timePerChar);
  }

  /// Generate unique ID for activities
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Add a new activity
  Future<void> addActivity(ProcessingActivity activity) async {
    _activities.insert(0, activity); // Add to beginning (newest first)
    
    // Limit the number of stored activities
    if (_activities.length > _maxActivities) {
      _activities.removeRange(_maxActivities, _activities.length);
    }

    // Save to storage
    await _saveActivities();

    // Notify listeners
    _activitiesController.add(List.unmodifiable(_activities));
  }

  /// Get activities filtered by date range
  List<ProcessingActivity> getActivitiesByDateRange(DateTime start, DateTime end) {
    return _activities.where((activity) {
      return activity.timestamp.isAfter(start) && 
             activity.timestamp.isBefore(end);
    }).toList();
  }

  /// Get today's activities
  List<ProcessingActivity> getTodayActivities() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getActivitiesByDateRange(startOfDay, endOfDay);
  }

  /// Get activities by operation type
  List<ProcessingActivity> getActivitiesByOperation(String operation) {
    return _activities.where((activity) => activity.operation == operation).toList();
  }

  /// Get activities by source app
  List<ProcessingActivity> getActivitiesBySourceApp(String sourceApp) {
    return _activities.where((activity) => activity.sourceApp == sourceApp).toList();
  }

  /// Calculate comprehensive statistics (synchronous version for backwards compatibility)
  ActivityStats calculateStats() {
    if (_activities.isEmpty) {
      return const ActivityStats(
        totalActivities: 0,
        todayActivities: 0,
        averageProcessingTime: 0.0,
        mostUsedOperation: 'None',
        successfulActivities: 0,
        failedActivities: 0,
        operationCounts: {},
        sourceAppCounts: {},
      );
    }

    final todayActivities = getTodayActivities();
    final successfulActivities = _activities.where((a) => a.success).length;
    final failedActivities = _activities.length - successfulActivities;

    // Calculate average processing time
    final totalTime = _activities.fold<double>(
      0.0, 
      (sum, activity) => sum + activity.processingTime,
    );
    final averageTime = totalTime / _activities.length;

    // Count operations
    final operationCounts = <String, int>{};
    for (final activity in _activities) {
      operationCounts[activity.operation] = 
          (operationCounts[activity.operation] ?? 0) + 1;
    }

    // Count source apps
    final sourceAppCounts = <String, int>{};
    for (final activity in _activities) {
      sourceAppCounts[activity.sourceApp] = 
          (sourceAppCounts[activity.sourceApp] ?? 0) + 1;
    }

    // Find most used operation (use menu ID for now, display name will be resolved in UI)
    String mostUsedOperation = 'None';
    if (operationCounts.isNotEmpty) {
      final mostUsed = operationCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      mostUsedOperation = mostUsed.key; // Use menu ID instead of display name
    }

    return ActivityStats(
      totalActivities: _activities.length,
      todayActivities: todayActivities.length,
      averageProcessingTime: averageTime,
      mostUsedOperation: mostUsedOperation,
      successfulActivities: successfulActivities,
      failedActivities: failedActivities,
      operationCounts: operationCounts,
      sourceAppCounts: sourceAppCounts,
    );
  }

  /// Calculate comprehensive statistics
  Future<ActivityStats> calculateStatsAsync() async {
    if (_activities.isEmpty) {
      return const ActivityStats(
        totalActivities: 0,
        todayActivities: 0,
        averageProcessingTime: 0.0,
        mostUsedOperation: 'None',
        successfulActivities: 0,
        failedActivities: 0,
        operationCounts: {},
        sourceAppCounts: {},
      );
    }

    final todayActivities = getTodayActivities();
    final successfulActivities = _activities.where((a) => a.success).length;
    final failedActivities = _activities.length - successfulActivities;

    // Calculate average processing time
    final totalTime = _activities.fold<double>(
      0.0, 
      (sum, activity) => sum + activity.processingTime,
    );
    final averageTime = totalTime / _activities.length;

    // Count operations
    final operationCounts = <String, int>{};
    for (final activity in _activities) {
      operationCounts[activity.operation] = 
          (operationCounts[activity.operation] ?? 0) + 1;
    }

    // Count source apps
    final sourceAppCounts = <String, int>{};
    for (final activity in _activities) {
      sourceAppCounts[activity.sourceApp] = 
          (sourceAppCounts[activity.sourceApp] ?? 0) + 1;
    }

    // Find most used operation with display name
    String mostUsedOperation = 'None';
    if (operationCounts.isNotEmpty) {
      final mostUsed = operationCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      mostUsedOperation = await _getOperationDisplayName(mostUsed.key);
    }

    return ActivityStats(
      totalActivities: _activities.length,
      todayActivities: todayActivities.length,
      averageProcessingTime: averageTime,
      mostUsedOperation: mostUsedOperation,
      successfulActivities: successfulActivities,
      failedActivities: failedActivities,
      operationCounts: operationCounts,
      sourceAppCounts: sourceAppCounts,
    );
  }

  /// Search activities by text content
  List<ProcessingActivity> searchActivities(String query) {
    if (query.isEmpty) return _activities;

    final lowercaseQuery = query.toLowerCase();
    return _activities.where((activity) {
      return activity.originalText.toLowerCase().contains(lowercaseQuery) ||
             activity.processedText.toLowerCase().contains(lowercaseQuery) ||
             activity.operation.toLowerCase().contains(lowercaseQuery) ||
             activity.sourceApp.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Reprocess an activity (create new activity with same original text)
  Future<void> reprocessActivity(ProcessingActivity activity) async {
    try {
      final contextMenuService = ProductionContextMenuService();
      
      // Find the menu configuration by exact ID match
      final configs = contextMenuService.getActiveConfigurations();
      final config = configs.where((c) => c.id == activity.operation).firstOrNull;
      
      if (config == null) {
        throw Exception('Menu configuration not found for operation: ${activity.operation}');
      }

      // Process the text directly without trying to replace in active application
      final processedText = await contextMenuService.processTextOnly(activity.originalText, config.operation);
      
      // Create a new activity record manually (since we're not going through the normal menu flow)
      final newActivity = ProcessingActivity(
        id: _generateId(),
        timestamp: DateTime.now(),
        operation: activity.operation, // Same operation ID
        originalText: activity.originalText, // Same original text
        processedText: processedText, // New processed result
        sourceApp: 'Activity Monitor', // Different source to indicate reprocessing
        processingTime: 0.5, // Estimated time for reprocessing
        success: true, // Assume success if no exception thrown
      );

      // Add the new activity
      await addActivity(newActivity);
      
    } catch (e) {
      print('Error reprocessing activity: $e');
      
      // Create a failed reprocess activity
      final failedActivity = ProcessingActivity(
        id: _generateId(),
        timestamp: DateTime.now(),
        operation: activity.operation,
        originalText: activity.originalText,
        processedText: activity.originalText, // Keep original when failed
        sourceApp: 'Activity Monitor',
        processingTime: 0.0,
        success: false,
        error: 'Reprocess failed: ${e.toString()}',
      );

      await addActivity(failedActivity);
      rethrow; // Re-throw to let UI handle the error
    }
  }

  /// Copy text to clipboard
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Clear all activities
  Future<void> clearActivities() async {
    try {
      print('ActivityService: Clearing activities...');
      
      // Clear in-memory activities
      _activities.clear();
      
      // Clear from persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activitiesKey);
      
      // Verify it's actually cleared
      final test = prefs.getString(_activitiesKey);
      print('ActivityService: Storage cleared, verification: ${test == null ? "SUCCESS" : "FAILED"}');
      
      // Notify listeners
      _activitiesController.add([]);
      
      print('ActivityService: Activities cleared successfully. In-memory count: ${_activities.length}');
    } catch (e) {
      print('Error clearing activities: $e');
      rethrow;
    }
  }

  /// Export activities as JSON
  String exportActivitiesAsJson() {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'totalActivities': _activities.length,
      'activities': _activities.map((a) => a.toJson()).toList(),
    };
    
    return jsonEncode(data);
  }

  /// Load activities from storage
  Future<void> _loadActivities() async {
    try {
      print('ActivityService: Loading activities from storage...');
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = prefs.getString(_activitiesKey);
      
      if (activitiesJson != null) {
        print('ActivityService: Found stored activities data');
        final List<dynamic> activitiesList = jsonDecode(activitiesJson);
        _activities.clear();
        _activities.addAll(
          activitiesList.map((json) => ProcessingActivity.fromJson(json))
        );
        
        // Sort by timestamp (newest first)
        _activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        print('ActivityService: Loaded ${_activities.length} activities from storage');
      } else {
        print('ActivityService: No stored activities found');
      }
    } catch (e) {
      print('Error loading activities: $e');
    }
  }

  /// Save activities to storage
  Future<void> _saveActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = jsonEncode(
        _activities.map((activity) => activity.toJson()).toList()
      );
      await prefs.setString(_activitiesKey, activitiesJson);
    } catch (e) {
      print('Error saving activities: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    _menuActionSubscription?.cancel();
    _activitiesController.close();
    _initialized = false;
  }
}
