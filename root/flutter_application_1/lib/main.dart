import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'privacy_policy_content.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  
  // Инициализация локальных уведомлений
  final notifications = FlutterLocalNotificationsPlugin();
  const initializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(
    const InitializationSettings(android: initializationSettings),
  );
  
  // Загрузка сохраненных данных
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MoneyCalculatorApp(),
    ),
  );
}

class MoneyCalculatorApp extends StatelessWidget {
  const MoneyCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    
    return MaterialApp(
      title: 'Калькулятор расходов',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B4D8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        // ИСПРАВЛЕНО: CardThemeData вместо CardTheme
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B4D8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        // ИСПРАВЛЕНО: CardThemeData вместо CardTheme
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      themeMode: settings.themeMode,
      home: const AppEntry(),
    );
  }
}

const String _privacyPolicyAcceptedKey = 'privacy_policy_accepted';

// ==================== МОДЕЛИ ДАННЫХ ====================

enum TransactionType { income, expense }
enum RepeatInterval { none, daily, weekly, monthly }

class TransactionCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final TransactionCategory category;
  final String? note;
  final String? imagePath;
  final bool isRecurring;
  final RepeatInterval? repeatInterval;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.note,
    this.imagePath,
    this.isRecurring = false,
    this.repeatInterval,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type.index,
    'categoryId': category.id,
    'note': note,
    'imagePath': imagePath,
    'isRecurring': isRecurring,
    'repeatInterval': repeatInterval?.index,
  };
}

class Budget {
  final TransactionCategory category;
  double limit;
  double spent;

  Budget({
    required this.category,
    required this.limit,
    this.spent = 0,
  });
}

// ==================== ПРЕДУСТАНОВЛЕННЫЕ КАТЕГОРИИ ====================

class CategoriesData {
  static List<TransactionCategory> get defaultCategories => [
    const TransactionCategory(
      id: 'food',
      name: 'Продукты',
      icon: Icons.restaurant,
      color: Colors.orange,
      type: TransactionType.expense,
    ),
    const TransactionCategory(
      id: 'transport',
      name: 'Транспорт',
      icon: Icons.directions_car,
      color: Colors.blue,
      type: TransactionType.expense,
    ),
    const TransactionCategory(
      id: 'entertainment',
      name: 'Развлечения',
      icon: Icons.movie,
      color: Colors.purple,
      type: TransactionType.expense,
    ),
    const TransactionCategory(
      id: 'shopping',
      name: 'Покупки',
      icon: Icons.shopping_bag,
      color: Colors.pink,
      type: TransactionType.expense,
    ),
    const TransactionCategory(
      id: 'health',
      name: 'Здоровье',
      icon: Icons.favorite,
      color: Colors.red,
      type: TransactionType.expense,
    ),
    const TransactionCategory(
      id: 'education',
      name: 'Образование',
      icon: Icons.school,
      color: Colors.teal,
      type: TransactionType.expense,
    ),
    const TransactionCategory(
      id: 'bills',
      name: 'Коммуналка',
      icon: Icons.home,
      color: Colors.brown,
      type: TransactionType.expense,
    ),
    const TransactionCategory(
      id: 'salary',
      name: 'Зарплата',
      icon: Icons.attach_money,
      color: Colors.green,
      type: TransactionType.income,
    ),
    const TransactionCategory(
      id: 'freelance',
      name: 'Фриланс',
      icon: Icons.work,
      color: Colors.cyan,
      type: TransactionType.income,
    ),
    const TransactionCategory(
      id: 'gift',
      name: 'Подарок',
      icon: Icons.card_giftcard,
      color: Colors.amber,
      type: TransactionType.income,
    ),
    const TransactionCategory(
      id: 'other_expense',
      name: 'Другое',
      icon: Icons.category,
      color: Colors.grey,
      type: TransactionType.expense,
    ),
    const TransactionCategory(
      id: 'other_income',
      name: 'Другое',
      icon: Icons.category,
      color: Colors.grey,
      type: TransactionType.income,
    ),
  ];
  
  static List<TransactionCategory> getExpenseCategories() {
    return defaultCategories.where((c) => c.type == TransactionType.expense).toList();
  }
  
  static List<TransactionCategory> getIncomeCategories() {
    return defaultCategories.where((c) => c.type == TransactionType.income).toList();
  }
  
  static TransactionCategory getCategoryById(String id) {
    return defaultCategories.firstWhere((c) => c.id == id);
  }
}

// ==================== PROVIDERS ====================

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Transaction> _recurringTransactions = [];
  String _searchQuery = '';
  DateTime? _selectedDate;
  TransactionType? _filterType;
  String? _filterCategoryId;

  TransactionProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    // Загрузка демо-данных для первого запуска
    _transactions = [
      Transaction(
        id: const Uuid().v4(),
        title: 'Пятерочка',
        amount: 1250,
        date: DateTime.now(),
        type: TransactionType.expense,
        category: CategoriesData.getCategoryById('food'),
        note: 'Продукты на неделю',
      ),
      Transaction(
        id: const Uuid().v4(),
        title: 'Яндекс.Такси',
        amount: 350,
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.expense,
        category: CategoriesData.getCategoryById('transport'),
      ),
      Transaction(
        id: const Uuid().v4(),
        title: 'Квартплата',
        amount: 4500,
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: TransactionType.expense,
        category: CategoriesData.getCategoryById('bills'),
      ),
      Transaction(
        id: const Uuid().v4(),
        title: 'Зарплата',
        amount: 75000,
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: TransactionType.income,
        category: CategoriesData.getCategoryById('salary'),
        note: 'Аванс',
      ),
    ];
  }

  List<Transaction> get transactions {
    var filtered = List<Transaction>.from(_transactions);
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) => 
        tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (tx.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    if (_selectedDate != null) {
      filtered = filtered.where((tx) =>
        tx.date.year == _selectedDate!.year &&
        tx.date.month == _selectedDate!.month &&
        tx.date.day == _selectedDate!.day
      ).toList();
    }
    
    if (_filterType != null) {
      filtered = filtered.where((tx) => tx.type == _filterType).toList();
    }
    
    if (_filterCategoryId != null) {
      filtered = filtered.where((tx) => tx.category.id == _filterCategoryId).toList();
    }
    
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  double get totalBalance {
    return _transactions.fold(0.0, (sum, item) {
      return item.type == TransactionType.income
          ? sum + item.amount
          : sum - item.amount;
    });
  }

  double get totalIncome {
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<TransactionCategory, double> getExpensesByCategory() {
    Map<TransactionCategory, double> result = {};
    for (var tx in _transactions.where((t) => t.type == TransactionType.expense)) {
      result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
    }
    return result;
  }

  List<Transaction> getTransactionsByCategory(
    String categoryId, {
    TransactionType? type,
  }) {
    return _transactions
        .where((tx) => tx.category.id == categoryId)
        .where((tx) => type == null || tx.type == type)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Map<String, dynamic>> getMonthlyStats() {
    Map<String, double> incomeByMonth = {};
    Map<String, double> expenseByMonth = {};
    
    for (var tx in _transactions) {
      String key = DateFormat('yyyy-MM').format(tx.date);
      if (tx.type == TransactionType.income) {
        incomeByMonth[key] = (incomeByMonth[key] ?? 0) + tx.amount;
      } else {
        expenseByMonth[key] = (expenseByMonth[key] ?? 0) + tx.amount;
      }
    }
    
    List<Map<String, dynamic>> result = [];
    for (var key in incomeByMonth.keys.toSet().union(expenseByMonth.keys.toSet())) {
      result.add({
        'month': key,
        'income': incomeByMonth[key] ?? 0,
        'expense': expenseByMonth[key] ?? 0,
        'saving': (incomeByMonth[key] ?? 0) - (expenseByMonth[key] ?? 0),
      });
    }
    result.sort((a, b) => a['month'].compareTo(b['month']));
    return result;
  }

  void addTransaction(Transaction tx) {
    _transactions.add(tx);
    if (tx.isRecurring && tx.repeatInterval != null) {
      _recurringTransactions.add(tx);
    }
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    _recurringTransactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }

  void updateTransaction(Transaction tx) {
    final index = _transactions.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      _transactions[index] = tx;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateFilter(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _filterType = type;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedDate = null;
    _filterType = null;
    _filterCategoryId = null;
    notifyListeners();
  }
}

class BudgetProvider with ChangeNotifier {
  List<Budget> _budgets = [];

  BudgetProvider() {
    _initBudgets();
  }

  void _initBudgets() {
    for (var category in CategoriesData.getExpenseCategories()) {
      _budgets.add(Budget(category: category, limit: 10000));
    }
  }

  List<Budget> get budgets => _budgets;
  
  double get totalBudgetLimit {
    return _budgets.fold(0.0, (sum, b) => sum + b.limit);
  }
  
  double get totalBudgetSpent {
    return _budgets.fold(0.0, (sum, b) => sum + b.spent);
  }
  
  Budget? getBudgetForCategory(String categoryId) {
    try {
      return _budgets.firstWhere((b) => b.category.id == categoryId);
    } catch (_) {
      return null;
    }
  }
  
  void updateBudget(String categoryId, double newLimit) {
    final index = _budgets.indexWhere((b) => b.category.id == categoryId);
    if (index != -1) {
      _budgets[index].limit = newLimit;
      notifyListeners();
    }
  }
  
  void updateSpent(String categoryId, double amount) {
    final index = _budgets.indexWhere((b) => b.category.id == categoryId);
    if (index != -1) {
      _budgets[index].spent += amount;
      notifyListeners();
    }
  }
}

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _currency = '₽';
  bool _notificationsEnabled = true;
  double _dailyBudgetLimit = 2000;
  
  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;
  bool get notificationsEnabled => _notificationsEnabled;
  double get dailyBudgetLimit => _dailyBudgetLimit;
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  
  void setCurrency(String currency) {
    _currency = currency;
    notifyListeners();
  }
  
  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
  }
  
  void setDailyBudgetLimit(double limit) {
    _dailyBudgetLimit = limit;
    notifyListeners();
  }
}

// ==================== UI КОМПОНЕНТЫ ====================

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _policyAccepted;

  @override
  void initState() {
    super.initState();
    _loadPolicyStatus();
  }

  Future<void> _loadPolicyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _policyAccepted = prefs.getBool(_privacyPolicyAcceptedKey) ?? false;
    });
  }

  Future<void> _onPolicyAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyPolicyAcceptedKey, true);
    if (!mounted) return;
    setState(() => _policyAccepted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_policyAccepted == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_policyAccepted!) {
      return const MainNavigationScreen();
    }
    return PrivacyPolicyScreen(
      onAccepted: _onPolicyAccepted,
      onDeclined: () => SystemNavigator.pop(),
    );
  }
}

class PrivacyPolicyScreen extends StatefulWidget {
  final Future<void> Function() onAccepted;
  final VoidCallback onDeclined;

  const PrivacyPolicyScreen({
    super.key,
    required this.onAccepted,
    required this.onDeclined,
  });

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _agreed = false;
  bool _isSaving = false;

  Future<void> _accept() async {
    if (!_agreed || _isSaving) return;
    setState(() => _isSaving = true);
    await widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onDeclined();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Политика конфиденциальности'),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: SelectionArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: [
                    Text(
                      'Версия $privacyPolicyVersion · действует с $privacyPolicyEffectiveDate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...privacyPolicySections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  section.body,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CheckboxListTile(
                      value: _agreed,
                      onChanged: _isSaving
                          ? null
                          : (value) => setState(() => _agreed = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Я ознакомился(ась) и принимаю условия',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _agreed && !_isSaving ? _accept : null,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Принять и продолжить'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _isSaving ? null : widget.onDeclined,
                      child: const Text('Отказаться'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryTransactionsScreen extends StatelessWidget {
  final TransactionCategory category;

  const CategoryTransactionsScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final transactions = transactionProvider.getTransactionsByCategory(
      category.id,
      type: category.type,
    );
    final total = transactions.fold<double>(
      0,
      (sum, tx) => sum + tx.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(category.icon, size: 64, color: category.color),
                  const SizedBox(height: 16),
                  Text(
                    'В категории «${category.name}» пока нет операций',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.color.withOpacity(0.2),
                        child: Icon(category.icon, color: category.color),
                      ),
                      title: Text(
                        category.type == TransactionType.expense
                            ? 'Всего потрачено'
                            : 'Всего получено',
                      ),
                      trailing: Text(
                        '${total.toStringAsFixed(0)} ${settings.currency}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: category.type == TransactionType.expense
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            tx.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm', 'ru')
                                    .format(tx.date),
                              ),
                              if (tx.note != null)
                                Text(
                                  tx.note!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: Text(
                            '${tx.type == TransactionType.income ? '+' : '-'} '
                            '${tx.amount.toStringAsFixed(0)} ${settings.currency}',
                            style: TextStyle(
                              color: tx.type == TransactionType.income
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const AnalyticsScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Аналитика',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'История',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const AddTransactionSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    
    return RefreshIndicator(
      onRefresh: () async {
        // Обновление данных
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Калькулятор расходов',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Карточка баланса
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Текущий баланс',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${transactionProvider.totalBalance.toStringAsFixed(0)} ${settings.currency}',
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'Доходы',
                                transactionProvider.totalIncome,
                                settings.currency,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'Расходы',
                                transactionProvider.totalExpense,
                                settings.currency,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Бюджет на сегодня
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Бюджет на сегодня',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${settings.dailyBudgetLimit.toStringAsFixed(0)} ${settings.currency}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (transactionProvider.totalExpense % settings.dailyBudgetLimit) / 
                                 settings.dailyBudgetLimit,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation(
                            transactionProvider.totalExpense > settings.dailyBudgetLimit
                                ? Colors.red
                                : Colors.green,
                          ),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Осталось: ${(settings.dailyBudgetLimit - (transactionProvider.totalExpense % settings.dailyBudgetLimit)).toStringAsFixed(0)} ${settings.currency}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Последние транзакции
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Последние операции',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...transactionProvider.transactions.take(5).map((tx) => 
                  _buildTransactionTile(context, tx, settings.currency),
                ),
                if (transactionProvider.transactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Нет операций. Добавьте первую!'),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, double amount, String currency, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(0)} $currency',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final expensesByCategory = transactionProvider.getExpensesByCategory();
    final monthlyStats = transactionProvider.getMonthlyStats();
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Аналитика'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pie_chart), text: 'Категории'),
              Tab(icon: Icon(Icons.show_chart), text: 'Динамика'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // График по категориям
            expensesByCategory.isEmpty
                ? const Center(child: Text('Нет данных для аналитики'))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: PieChart(
                            PieChartData(
                              sections: _buildPieSections(expensesByCategory),
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView.builder(
                            itemCount: expensesByCategory.entries.length,
                            itemBuilder: (context, index) {
                              final entry = expensesByCategory.entries.elementAt(index);
                              final percentage = (entry.value / transactionProvider.totalExpense * 100);
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: entry.key.color.withOpacity(0.2),
                                  child: Icon(entry.key.icon, color: entry.key.color, size: 20),
                                ),
                                title: Text(entry.key.name),
                                subtitle: const Text('Нажмите, чтобы увидеть покупки'),
                                trailing: Text(
                                  '${entry.value.toStringAsFixed(0)} ${settings.currency} (${percentage.toStringAsFixed(1)}%)',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CategoryTransactionsScreen(
                                        category: entry.key,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
            
            // График динамики
            monthlyStats.isEmpty
                ? const Center(child: Text('Нет данных для аналитики'))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 300,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: const FlTitlesData(show: true),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: monthlyStats.asMap().entries.map((e) => 
                                    FlSpot(e.key.toDouble(), e.value['income'] as double)
                                  ).toList(),
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 3,
                                  belowBarData: BarAreaData(show: false),
                                ),
                                LineChartBarData(
                                  spots: monthlyStats.asMap().entries.map((e) => 
                                    FlSpot(e.key.toDouble(), e.value['expense'] as double)
                                  ).toList(),
                                  isCurved: true,
                                  color: Colors.red,
                                  barWidth: 3,
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegend('Доходы', Colors.green),
                            const SizedBox(width: 24),
                            _buildLegend('Расходы', Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  
  List<PieChartSectionData> _buildPieSections(Map<TransactionCategory, double> expenses) {
    return expenses.entries.map((entry) {
      return PieChartSectionData(
        color: entry.key.color,
        value: entry.value,
        title: '${(entry.value / expenses.values.reduce((a, b) => a + b) * 100).toStringAsFixed(0)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
  
  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('История операций'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          if (transactionProvider._searchQuery.isNotEmpty ||
              transactionProvider._selectedDate != null ||
              transactionProvider._filterType != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => transactionProvider.clearFilters(),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => transactionProvider.setSearchQuery(value),
            ),
          ),
        ),
      ),
      body: transactionProvider.transactions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Нет операций', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Нажмите + чтобы добавить первую операцию'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: transactionProvider.transactions.length,
              itemBuilder: (context, index) {
                final tx = transactionProvider.transactions[index];
                return Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          _showEditDialog(context, tx);
                        },
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: 'Изменить',
                      ),
                      SlidableAction(
                        onPressed: (context) {
                          transactionProvider.deleteTransaction(tx.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Операция удалена')),
                          );
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Удалить',
                      ),
                    ],
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tx.category.color.withOpacity(0.2),
                        child: Icon(tx.category.icon, color: tx.category.color),
                      ),
                      title: Text(
                        tx.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('dd MMM yyyy, HH:mm', 'ru').format(tx.date)),
                          if (tx.note != null) Text(tx.note!, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: Text(
                        '${tx.type == TransactionType.income ? '+' : '-'} ${tx.amount.toStringAsFixed(0)} ${settings.currency}',
                        style: TextStyle(
                          color: tx.type == TransactionType.income ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
  
  void _showFilterDialog(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Тип операции:'),
            const SizedBox(height: 8),
            SegmentedButton<TransactionType?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Все')),
                ButtonSegment(value: TransactionType.income, label: Text('Доходы')),
                ButtonSegment(value: TransactionType.expense, label: Text('Расходы')),
              ],
              selected: {provider._filterType},
              onSelectionChanged: (Set<TransactionType?> selection) {
                provider.setTypeFilter(selection.first);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditDialog(BuildContext context, Transaction transaction) {
    // Реализация редактирования
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Редактирование в разработке')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль и настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Настройки',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('Тема'),
                    trailing: DropdownButton<ThemeMode>(
                      value: settings.themeMode,
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('Системная'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Светлая'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Темная'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) settings.setThemeMode(value);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: const Text('Валюта'),
                    trailing: DropdownButton<String>(
                      value: settings.currency,
                      // ИСПРАВЛЕНО: убрана константность для символов валют
                      items: [
                        const DropdownMenuItem(
                          value: '₽', 
                          child: Text('Рубль (₽)'),
                        ),
                        const DropdownMenuItem(
                          value: '\$',  // Экранирование доллара
                          child: Text('Доллар (\$)'),
                        ),
                        const DropdownMenuItem(
                          value: '€', 
                          child: Text('Евро (€)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) settings.setCurrency(value);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Уведомления'),
                    trailing: Switch(
                      value: settings.notificationsEnabled,
                      onChanged: (_) => settings.toggleNotifications(),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.today),
                    title: const Text('Дневной бюджет'),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '${settings.dailyBudgetLimit}',
                          suffixText: settings.currency,
                        ),
                        onSubmitted: (value) {
                          final limit = double.tryParse(value);
                          if (limit != null) settings.setDailyBudgetLimit(limit);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Бюджеты по категориям',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ...budgetProvider.budgets.map((budget) => ListTile(
                    title: Text(budget.category.name),
                    subtitle: Text('Потрачено: ${budget.spent.toStringAsFixed(0)} ${settings.currency}'),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '${budget.limit}',
                          suffixText: settings.currency,
                        ),
                        onSubmitted: (value) {
                          final limit = double.tryParse(value);
                          if (limit != null) budgetProvider.updateBudget(budget.category.id, limit);
                        },
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Советы по экономии',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildTip(
                    '📊', 
                    'Отслеживайте расходы', 
                    'Регулярно проверяйте аналитику, чтобы видеть куда уходят деньги'
                  ),
                  _buildTip(
                    '🎯', 
                    'Установите лимиты', 
                    'Используйте бюджеты по категориям, чтобы не тратить лишнего'
                  ),
                  _buildTip(
                    '💰', 
                    'Правило 50/30/20', 
                    '50% на нужды, 30% на желания, 20% на накопления'
                  ),
                  _buildTip(
                    '🏦', 
                    'Автоматические накопления', 
                    'Откладывайте 10% от каждого дохода сразу'
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTip(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  TransactionType _type = TransactionType.expense;
  TransactionCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  RepeatInterval? _repeatInterval;
  
  @override
  void initState() {
    super.initState();
    _selectedCategory = CategoriesData.getExpenseCategories().first;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Новая операция',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Тип операции
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Расход'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Доход'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<TransactionType> selection) {
                  setState(() {
                    _type = selection.first;
                    if (_type == TransactionType.expense) {
                      _selectedCategory = CategoriesData.getExpenseCategories().first;
                    } else {
                      _selectedCategory = CategoriesData.getIncomeCategories().first;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Название
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Сумма
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите сумму';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите корректную сумму';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Категория
              DropdownButtonFormField<TransactionCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: (_type == TransactionType.expense
                    ? CategoriesData.getExpenseCategories()
                    : CategoriesData.getIncomeCategories()
                ).map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Дата
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Дата'),
                subtitle: Text(DateFormat('dd MMMM yyyy', 'ru').format(_selectedDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Примечание
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Примечание (необязательно)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Повторяющиеся
              CheckboxListTile(
                title: const Text('Повторяющаяся операция'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value ?? false;
                  });
                },
              ),
              
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<RepeatInterval>(
                  value: _repeatInterval,
                  decoration: const InputDecoration(
                    labelText: 'Повторять каждые',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: RepeatInterval.daily,
                      child: Text('Каждый день'),
                    ),
                    DropdownMenuItem(
                      value: RepeatInterval.weekly,
                      child: Text('Каждую неделю'),
                    ),
                    DropdownMenuItem(
                      value: RepeatInterval.monthly,
                      child: Text('Каждый месяц'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _repeatInterval = value;
                    });
                  },
                ),
              ],
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saveTransaction,
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        id: const Uuid().v4(),
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _type,
        category: _selectedCategory!,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        isRecurring: _isRecurring,
        repeatInterval: _repeatInterval,
      );
      
      Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction);
      
      // Обновление бюджета
      if (_type == TransactionType.expense) {
        Provider.of<BudgetProvider>(context, listen: false).updateSpent(
          _selectedCategory!.id,
          double.parse(_amountController.text),
        );
      }
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Операция добавлена')),
      );
    }
  }
}

// Вспомогательная функция для создания виджета транзакции
Widget _buildTransactionTile(BuildContext context, Transaction tx, String currency) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: tx.category.color.withOpacity(0.2),
        child: Icon(tx.category.icon, color: tx.category.color),
      ),
      title: Text(tx.title),
      subtitle: Text(DateFormat('dd MMM yyyy', 'ru').format(tx.date)),
      trailing: Text(
        '${tx.type == TransactionType.income ? '+' : '-'} ${tx.amount.toStringAsFixed(0)} $currency',
        style: TextStyle(
          color: tx.type == TransactionType.income ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}