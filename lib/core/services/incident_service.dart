import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nitoroute/core/config/app_config.dart';
import '../models/incident.dart';
import 'auth_service.dart';

class IncidentService {
  final http.Client _client;
  final AuthService _authService;

  IncidentService({
    http.Client? client,
    AuthService? authService,
  })  : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  Future<List<Incident>> getIncidents({
    String? tripId,
    String? type,
    String? severity,
    String? status,
    String? search,
    int perPage = 15,
    int page = 1,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final queryParams = <String, String>{
        'per_page': perPage.toString(),
        'page': page.toString(),
      };

      if (tripId != null) queryParams['trip_id'] = tripId;
      if (type != null) queryParams['type'] = type;
      if (severity != null) queryParams['severity'] = severity;
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse('${AppConfig.baseUrl}/incidents').replace(
        queryParameters: queryParams,
      );

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final incidentsList = data['data'] as List;
          return incidentsList
              .map((incidentJson) => Incident.fromJson(incidentJson))
              .toList();
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('Failed to load incidents: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching incidents: $e');
    }
  }

  Future<Incident> getIncident(String incidentId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/incidents/$incidentId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Incident.fromJson(data['data']);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('Failed to load incident: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching incident: $e');
    }
  }

  Future<Incident> reportIncident({
    required String tripId,
    required String type,
    required String description,
    double? lat,
    double? lng,
    String severity = 'medium',
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final incidentData = {
        'trip_id': tripId,
        'type': type,
        'description': description,
        'lat': lat,
        'lng': lng,
        'severity': severity,
      };

      final response = await _client.post(
        Uri.parse('${AppConfig.baseUrl}/incidents'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(incidentData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Incident.fromJson(data['data']);
        }
        throw Exception('Invalid response format');
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Failed to report incident';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error reporting incident: $e');
    }
  }

  Future<Incident> updateIncident({
    required String incidentId,
    String? type,
    String? description,
    String? severity,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final updateData = <String, dynamic>{};
      if (type != null) updateData['type'] = type;
      if (description != null) updateData['description'] = description;
      if (severity != null) updateData['severity'] = severity;

      final response = await _client.put(
        Uri.parse('${AppConfig.baseUrl}/incidents/$incidentId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Incident.fromJson(data['data']);
        }
        throw Exception('Invalid response format');
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Failed to update incident';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error updating incident: $e');
    }
  }

  Future<Incident> resolveIncident({
    required String incidentId,
    String? resolutionNotes,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final resolutionData = <String, dynamic>{};
      if (resolutionNotes != null) {
        resolutionData['resolution_notes'] = resolutionNotes;
      }

      final response = await _client.post(
        Uri.parse('${AppConfig.baseUrl}/incidents/$incidentId/resolve'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(resolutionData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Incident.fromJson(data['data']);
        }
        throw Exception('Invalid response format');
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Failed to resolve incident';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error resolving incident: $e');
    }
  }

  Future<void> deleteIncident(String incidentId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _client.delete(
        Uri.parse('${AppConfig.baseUrl}/incidents/$incidentId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Failed to delete incident';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error deleting incident: $e');
    }
  }

  Future<Map<String, dynamic>> getIncidentStats() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/incidents/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('Failed to load incident stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching incident stats: $e');
    }
  }

  Future<List<Incident>> getIncidentsForRoute(String routeId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/routes/$routeId/incidents'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final incidentsList = data['data'] as List;
          return incidentsList
              .map((incidentJson) => Incident.fromJson(incidentJson))
              .toList();
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('Failed to load route incidents: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching route incidents: $e');
    }
  }
}
