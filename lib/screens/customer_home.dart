import 'package:flutter/material.dart';

import 'customer_home_screen.dart';

/// Entry point used by the older drawer. Use the same visit-only home as the
/// named customer route rather than exposing the retired booking flow.
class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) => const CustomerHomeScreen();
}
