import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HallLocationWidget extends StatelessWidget {
  final String propertyName;
  final String? address;

  const HallLocationWidget({
    Key? key,
    required this.propertyName,
    this.address,
  }) : super(key: key);

  void _openInMaps(BuildContext context) async {
    if (address == null || address!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address not available')),
      );
      return;
    }

    Uri uri;

    // If address is in lat,lng format, use directly
    if (RegExp(r'^-?\d+(\.\d+)?,-?\d+(\.\d+)?$').hasMatch(address!)) {
      uri = Uri.parse("geo:$address?q=$address($propertyName)");
    } else {
      // Otherwise, use search query
      final encoded = Uri.encodeComponent(address!);
      uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encoded");
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.shade200),
        color: Colors.deepPurple.shade50,
      ),
      child: InkWell(
        onTap: () => _openInMaps(context),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.deepPurple.shade800,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address ?? 'Address not available',
                      style: TextStyle(
                        color: Colors.deepPurple.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Text(
                    'View Map',
                    style: TextStyle(
                      color: Colors.deepPurple.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.deepPurple.shade600,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
