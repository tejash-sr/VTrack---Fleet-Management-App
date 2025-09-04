import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';
import '../../services/firestore_service.dart';
import '../../services/realtime_service.dart';
import '../../services/auth_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _isSending = false;
  String? _customMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Alert'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: Consumer4<LocationService, FirestoreService, RealtimeService, AuthService>(
        builder: (context, locationService, firestoreService, realtimeService, authService, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Warning Card
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 60,
                          color: Colors.red[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Emergency Alert',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This will send an emergency alert to the management team with your current location.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Location Info
                if (locationService.currentPosition != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (locationService.currentAddress != null) ...[
                            Text(
                              locationService.currentAddress!,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                          ],
                          Text(
                            'Lat: ${locationService.currentPosition!.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Lng: ${locationService.currentPosition!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
                
                // Custom Message
                TextField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Custom Message (Optional)',
                    hintText: 'Add any additional information...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _customMessage = value;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Emergency Contacts
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall('911'),
                        icon: const Icon(Icons.phone),
                        label: const Text('Call 911'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall('+1234567890'), // Replace with actual emergency number
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Manager'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Send SOS Alert Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : () => _sendSOSAlert(
                      locationService,
                      firestoreService,
                      realtimeService,
                      authService,
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.warning),
                    label: Text(_isSending ? 'Sending Alert...' : 'Send SOS Alert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Future<void> _sendSOSAlert(
    LocationService locationService,
    FirestoreService firestoreService,
    RealtimeService realtimeService,
    AuthService authService,
  ) async {
    if (authService.user == null || locationService.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send alert - location or user not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final position = locationService.currentPosition!;
      final message = _customMessage?.isNotEmpty == true 
          ? _customMessage! 
          : 'SOS - Driver needs help';

      // Send to Firestore
      await firestoreService.createSOSAlert(
        driverId: authService.user!.uid,
        latitude: position.latitude,
        longitude: position.longitude,
        message: message,
      );

      // Send to Realtime Database
      await realtimeService.sendSOSAlert(
        driverId: authService.user!.uid,
        latitude: position.latitude,
        longitude: position.longitude,
        message: message,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS Alert sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
  
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making phone call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
