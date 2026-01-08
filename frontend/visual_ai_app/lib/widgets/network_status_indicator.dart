import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';

class NetworkStatusIndicator extends StatelessWidget {
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityResult>(
      builder: (context, connectivity, child) {
        final bool isOffline = connectivity == ConnectivityResult.none;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOffline ? 36.0 : 0.0,
          color: isOffline ? Colors.red.shade800 : Colors.green.shade700,
          child: isOffline
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'You are offline - Changes will sync when online',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
} 