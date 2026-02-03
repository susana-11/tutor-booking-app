import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SessionTimer extends StatefulWidget {
  final int durationMinutes;
  final DateTime? startTime;
  final VoidCallback? onTimeUp;
  final VoidCallback? onWarning; // Called 5 minutes before end
  final bool showWarning;

  const SessionTimer({
    Key? key,
    required this.durationMinutes,
    this.startTime,
    this.onTimeUp,
    this.onWarning,
    this.showWarning = true,
  }) : super(key: key);

  @override
  State<SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends State<SessionTimer> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _warningShown = false;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    if (widget.startTime == null) {
      _remainingTime = Duration(minutes: widget.durationMinutes);
      return;
    }

    final now = DateTime.now();
    final endTime = widget.startTime!.add(Duration(minutes: widget.durationMinutes));
    final difference = endTime.difference(now);

    if (difference.isNegative) {
      _remainingTime = Duration.zero;
      if (widget.onTimeUp != null) {
        Future.microtask(() => widget.onTimeUp!());
      }
    } else {
      _remainingTime = difference;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);

          // Check for 5-minute warning
          if (widget.showWarning &&
              !_warningShown &&
              _remainingTime.inMinutes == 5 &&
              _remainingTime.inSeconds == 0) {
            _warningShown = true;
            if (widget.onWarning != null) {
              widget.onWarning!();
            }
          }

          // Check if time is up
          if (_remainingTime.inSeconds == 0) {
            timer.cancel();
            if (widget.onTimeUp != null) {
              widget.onTimeUp!();
            }
          }
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  Color _getTimerColor() {
    if (_remainingTime.inMinutes <= 5) {
      return Colors.red;
    } else if (_remainingTime.inMinutes <= 10) {
      return Colors.orange;
    } else {
      return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = _getTimerColor();
    final progress = widget.durationMinutes > 0
        ? _remainingTime.inSeconds / (widget.durationMinutes * 60)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLG,
        vertical: AppTheme.spacingMD,
      ),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: timerColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                color: timerColor,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Text(
                _formatTime(_remainingTime),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: timerColor,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(timerColor),
              minHeight: 6,
            ),
          ),
          if (_remainingTime.inMinutes <= 5 && _remainingTime.inSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSM),
              child: Text(
                'Session ending soon!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

// Compact version for app bar
class CompactSessionTimer extends StatefulWidget {
  final int durationMinutes;
  final DateTime? startTime;

  const CompactSessionTimer({
    Key? key,
    required this.durationMinutes,
    this.startTime,
  }) : super(key: key);

  @override
  State<CompactSessionTimer> createState() => _CompactSessionTimerState();
}

class _CompactSessionTimerState extends State<CompactSessionTimer> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    if (widget.startTime == null) {
      _remainingTime = Duration(minutes: widget.durationMinutes);
      return;
    }

    final now = DateTime.now();
    final endTime = widget.startTime!.add(Duration(minutes: widget.durationMinutes));
    final difference = endTime.difference(now);

    _remainingTime = difference.isNegative ? Duration.zero : difference;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isLowTime = _remainingTime.inMinutes <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isLowTime ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(_remainingTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
