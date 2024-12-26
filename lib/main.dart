import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'add_expense_page.dart';
import 'widgets/transaction_list_sheet.dart';
import 'providers/transaction_provider.dart';
import 'pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'constants/supabase_constants.dart';
import 'pages/settings_page.dart';
import 'services/supabase_service.dart';
import 'pages/analytics_page.dart';
import 'constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화
  await supabase.Supabase.initialize(
    url: SupabaseConstants.SUPABASE_URL,
    anonKey: SupabaseConstants.SUPABASE_ANON_KEY,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      ChangeNotifierProvider(
        create: (_) => TransactionProvider(),
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '지출 캘린더',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF2B2B2B),
        brightness: Brightness.dark,
        textTheme: Theme.of(context).textTheme.apply(
              fontSizeFactor: 1.0,
              fontFamily: '.SF Pro Text',
            ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      home: FutureBuilder<bool>(
        future: _checkAuthState(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data == true
              ? const ExpenseCalendarPage()
              : const LoginPage();
        },
      ),
    );
  }

  Future<bool> _checkAuthState(BuildContext context) async {
    final session = SupabaseService.supabase.auth.currentSession;
    if (session != null) {
      final provider = context.read<TransactionProvider>();
      await provider.initializeDefaultCategories();
      await provider.loadInitialData();
      return true;
    }
    return false;
  }
}

class ExpenseCalendarPage extends StatefulWidget {
  const ExpenseCalendarPage({super.key});

  @override
  State<ExpenseCalendarPage> createState() => _ExpenseCalendarPageState();
}

class _ExpenseCalendarPageState extends State<ExpenseCalendarPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isExpense = true;
  final _currencyFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    // 삭제: 여기서는 데이터를 다시 로드하지 않음
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   final provider = context.read<TransactionProvider>();
    //   await provider.loadInitialData();
    // });
  }

  void _showTransactionsForDate(DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return TransactionListSheet(
            date: date,
            transactions: provider
                .getTransactionsForDate(date)
                .where((t) => t.isExpense == _isExpense)
                .toList(),
            isExpense: _isExpense,
            onDelete: () {
              setState(() {});
            },
          );
        },
      ),
    );
  }

  Widget _buildToggleButton(bool isExpense) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF404040),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFF505050)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonWidth = (constraints.maxWidth - 8) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment:
                    _isExpense ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: buttonWidth,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isExpense
                        ? const Color(0xFFFF6666)
                        : const Color(0xFF438BFF),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _isExpense = true),
                      child: Center(
                        child: Text(
                          '지출',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isExpense ? Colors.white : Colors.grey[300],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _isExpense = false),
                      child: Center(
                        child: Text(
                          '수입',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                !_isExpense ? Colors.white : Colors.grey[300],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalAmount() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final total =
            provider.getTotalForMonth(_focusedDay, isExpense: _isExpense);
        return Text(
          '${_currencyFormat.format(total.abs())}원',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
            color: Colors.white,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final total = provider.getTotalForMonth(_focusedDay, isExpense: _isExpense);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: const Color(0xFF2B2B2B),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.home,
                  color: Colors.white,
                ),
                title: const Text(
                  '홈',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                ),
                title: const Text(
                  '분석',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
                title: const Text(
                  '설정',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 메뉴와 토글 버튼
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildToggleButton(true)),
                ],
              ),
            ),
            // 새로고침 가능한 영역 시작
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _selectedDay = null;
                    _focusedDay = DateTime.now();
                  });
                  await context
                      .read<TransactionProvider>()
                      .refreshTransactions();
                },
                color: _isExpense
                    ? const Color(0xFFFF6666)
                    : const Color(0xFF438BFF),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // 총 지출/수입 표시
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${_focusedDay.month}월 ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFC7C7C7),
                                  ),
                                ),
                                Text(
                                  '총 ${_isExpense ? '지출' : '수입'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isExpense
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            _buildTotalAmount(),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      // 달력
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TableCalendar(
                          locale: 'ko-KR',
                          firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
                          lastDay:
                              DateTime.utc(DateTime.now().year + 2, 12, 31),
                          focusedDay: _focusedDay,
                          daysOfWeekHeight: 32,
                          rowHeight: 65,
                          availableCalendarFormats: const {
                            CalendarFormat.month: '월',
                          },
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              fontSize: 17.0,
                              color: Colors.white,
                            ),
                            leftChevronIcon:
                                Icon(Icons.chevron_left, color: Colors.white),
                            rightChevronIcon:
                                Icon(Icons.chevron_right, color: Colors.white),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            weekendStyle: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFF404040),
                                  width: 1.0,
                                ),
                              ),
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            defaultTextStyle: const TextStyle(
                              color: Color(0xFFDDDDDD),
                              fontSize: 18,
                            ),
                            selectedTextStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            todayTextStyle: const TextStyle(
                              color: Color(0xFFDDDDDD),
                              fontSize: 18,
                            ),
                            weekendTextStyle: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 18,
                            ),
                            cellMargin: const EdgeInsets.all(2),
                            cellPadding: const EdgeInsets.all(8),
                            defaultDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            weekendDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            outsideDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            todayDecoration: BoxDecoration(
                              color: const Color(0xFF404040),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            selectedDecoration: BoxDecoration(
                              color: const Color(0xFF606060),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            rangeStartDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            rangeEndDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            withinRangeDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            holidayDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            _showTransactionsForDate(selectedDay);
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              final transactions = context
                                  .read<TransactionProvider>()
                                  .getTransactionsForDate(date)
                                  .where((t) => t.isExpense == _isExpense)
                                  .fold<int>(
                                      0, (sum, t) => sum + t.amount.abs());

                              if (transactions == 0) return null;

                              return Positioned(
                                bottom: 8,
                                left: 4,
                                right: 4,
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      NumberFormat('#,###')
                                          .format(transactions),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _isExpense
                                            ? const Color(0xFFFF6666)
                                            : const Color(0xFF438BFF),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // 스크롤 가능하도록 추가 공간 확보
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddExpensePage(
                          selectedDate: _selectedDay ?? DateTime.now(),
                          isExpense: _isExpense,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _isExpense
                        ? const Color(0xFFFF6666)
                        : const Color(0xFF438BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isExpense ? '지출 추가하기' : '수입 추가하기',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
