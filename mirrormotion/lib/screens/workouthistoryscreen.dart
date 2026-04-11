import 'package:flutter/material.dart';
import 'package:mirrormotion/components/chart.dart';
import 'package:mirrormotion/services/data.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  static const int _pageSize = 12;

  final ScrollController _scrollController = ScrollController();
  int _visibleWeeks = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final ScrollPosition position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 200) {
      return;
    }

    setState(() {
      _visibleWeeks += _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final DataService dataService = DataService();

    return Scaffold(
      backgroundColor: const Color(0xFF8B7D7D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: dataService,
          builder: (BuildContext context, Widget? child) {
            final List<WeeklyUsageSummary> fullHistory = dataService
                .getWorkoutHistory(minimumWeeks: 3);
            final int visibleCount = _visibleWeeks.clamp(0, fullHistory.length);
            final List<WeeklyUsageSummary> history = fullHistory
                .take(visibleCount)
                .toList();
            final bool hasMore = visibleCount < fullHistory.length;

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workout History',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB7CBD4),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(40, 0, 0, 0),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      child: Column(
                        children: [
                          for (
                            int index = 0;
                            index < history.length;
                            index++
                          ) ...[
                            _WorkoutHistoryEntry(summary: history[index]),
                            if (index != history.length - 1 || hasMore)
                              const SizedBox(height: 36),
                          ],
                          if (hasMore) ...[
                            Text(
                              'Scroll for older weeks',
                              style: const TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorkoutHistoryEntry extends StatelessWidget {
  const _WorkoutHistoryEntry({required this.summary});

  final WeeklyUsageSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 122,
          child: Text(
            _formatDateRange(summary.weekStart, summary.weekEnd),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: SizedBox(
            height: 250,
            child: BarChartWidget(
              weeklyData: summary.points,
              barColor: const Color(0xFF16BEDB),
              goalHitBarColor: const Color(0xFF16BEDB),
              goalBarColor: const Color(0xFFAAA7A8),
              labelColor: Colors.white,
              tooltipColor: const Color(0xFF7A7070),
              barWidth: 24,
              labelFontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    return '${_formatDate(start)}-\n${_formatDate(end)}';
  }

  String _formatDate(DateTime value) {
    return '${value.month}/${value.day}/${value.year}';
  }
}
