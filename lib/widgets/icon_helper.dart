import 'package:flutter/material.dart';

/// Maps lucide-react icons to Flutter Material icons for exact design parity
class IconHelper {
  // Service categories
  static const IconData Plumber = Icons.home_repair_service;
  static const IconData electrician = Icons.electrical_services;
  static const IconData carpentry = Icons.handyman;
  static const IconData painting = Icons.brush;
  static const IconData ac = Icons.ac_unit;
  static const IconData cleaning = Icons.cleaning_services;

  // Navigation & UI
  static const IconData home = Icons.home;
  static const IconData search = Icons.search;
  static const IconData chat = Icons.chat;
  static const IconData settings = Icons.settings;
  static const IconData profile = Icons.person;
  static const IconData notification = Icons.notifications;
  static const IconData language = Icons.language;
  static const IconData menu = Icons.menu;
  static const IconData close = Icons.close;
  static const IconData back = Icons.arrow_back;

  // Job & Services
  static const IconData job = Icons.assignment;
  static const IconData calendar = Icons.calendar_today;
  static const IconData location = Icons.location_on;
  static const IconData mapIcon = Icons.map;
  static const IconData clock = Icons.schedule;
  static const IconData rupee = Icons.currency_rupee;
  static const IconData phone = Icons.phone;

  // Status & Action
  static const IconData checkCircle = Icons.check_circle;
  static const IconData cancel = Icons.cancel;
  static const IconData pending = Icons.pending_actions;
  static const IconData info = Icons.info;
  static const IconData warning = Icons.warning;
  static const IconData success = Icons.done_all;

  // User & Rating
  static const IconData star = Icons.star;
  static const IconData starOutline = Icons.star_outline;
  static const IconData rating = Icons.star_rate;
  static const IconData verified = Icons.verified;
  static const IconData badge = Icons.card_membership;

  // Additional
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData send = Icons.send;
  static const IconData call = Icons.call;
  static const IconData microphone = Icons.mic;
  static const IconData camera = Icons.camera;
  static const IconData wallet = Icons.account_balance_wallet;
  static const IconData upload = Icons.cloud_upload;
  static const IconData download = Icons.download;
  static const IconData filter = Icons.tune;
  static const IconData sort = Icons.sort;
  static const IconData logout = Icons.logout;
  static const IconData fingerprint = Icons.fingerprint;
}

/// Widget for animated icon with scale effect (matching React animations)
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final String? tooltip;

  const AnimatedIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color = Colors.teal,
    this.size = 24,
    this.tooltip,
  }) : super(key: key);

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              widget.icon,
              color: widget.color,
              size: widget.size,
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge widget for verification badges (matching React design)
class VerificationBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;

  const VerificationBadge({
    Key? key,
    required this.label,
    required this.icon,
    this.bgColor = Colors.green,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bgColor.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: bgColor),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: bgColor,
            ),
          ),
        ],
      ),
    );
  }
}
