import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../services/account_service.dart';

class AccountsState {
  final List<TransactionModel> transactions;
  final List<String> categories;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double cashInHand;
  final double bankBalance;
  final double outstandingReceivables;

  AccountsState({
    this.transactions = const [],
    this.categories = const ['All Categories'],
    this.totalIncome = 0,
    this.totalExpenses = 0,
    this.netProfit = 0,
    this.cashInHand = 0,
    this.bankBalance = 0,
    this.outstandingReceivables = 0,
  });

  AccountsState copyWith({
    List<TransactionModel>? transactions,
    List<String>? categories,
    double? totalIncome,
    double? totalExpenses,
    double? netProfit,
    double? cashInHand,
    double? bankBalance,
    double? outstandingReceivables,
  }) {
    return AccountsState(
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      cashInHand: cashInHand ?? this.cashInHand,
      bankBalance: bankBalance ?? this.bankBalance,
      outstandingReceivables: outstandingReceivables ?? this.outstandingReceivables,
    );
  }
}

class AccountsNotifier extends AsyncNotifier<AccountsState> {
  @override
  Future<AccountsState> build() async {
    return _fetchData();
  }

  Future<void> loadTransactions({
    String selectedPeriod = 'All Time',
    String selectedType = 'All Types',
    String selectedCategory = 'All Categories',
    String searchQuery = '',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData(
          selectedPeriod: selectedPeriod,
          selectedType: selectedType,
          selectedCategory: selectedCategory,
          searchQuery: searchQuery,
        ));
  }

  Future<AccountsState> _fetchData({
    String selectedPeriod = 'All Time',
    String selectedType = 'All Types',
    String selectedCategory = 'All Categories',
    String searchQuery = '',
  }) async {
    final allTxns = await TransactionService.getTransactions();
    
    // Dynamically build category list from all transactions
    final Set<String> catSet = {};
    for (var t in allTxns) {
      if (t.category.isNotEmpty) catSet.add(t.category);
    }
    final List<String> loadedCategories = ['All Categories', ...catSet.toList()..sort()];
    
    // Validate selected category
    String safeCategory = selectedCategory;
    if (!loadedCategories.contains(safeCategory)) {
      safeCategory = 'All Categories';
    }
    
    final now = DateTime.now();
    final DateFormat format = DateFormat('dd MMM yyyy');
    
    List<TransactionModel> filteredTxns = [];
    
    for (var txn in allTxns) {
      try {
        final txnDate = format.parse(txn.date);
        bool include = false;
        
        switch (selectedPeriod) {
          case 'Today':
            include = txnDate.year == now.year && txnDate.month == now.month && txnDate.day == now.day;
            break;
          case 'This Week':
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            include = txnDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
            break;
          case 'This Month':
            include = txnDate.year == now.year && txnDate.month == now.month;
            break;
          case 'This Year':
            include = txnDate.year == now.year;
            break;
          case 'All Time':
          default:
            include = true;
            break;
        }
        
        if (include && selectedType != 'All Types' && txn.type != selectedType) {
          include = false;
        }

        if (include && safeCategory != 'All Categories' && txn.category != safeCategory) {
          include = false;
        }

        if (include && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          if (!txn.description.toLowerCase().contains(query) &&
              !txn.category.toLowerCase().contains(query)) {
            include = false;
          }
        }
        
        if (include) {
          filteredTxns.add(txn);
        }
      } catch (e) {
        if (selectedType != 'All Types' && txn.type != selectedType) continue;
        if (safeCategory != 'All Categories' && txn.category != safeCategory) continue;
        filteredTxns.add(txn);
      }
    }
    
    double runningBal = 0.0;
    for (int i = filteredTxns.length - 1; i >= 0; i--) {
      final txn = filteredTxns[i];
      if (txn.type == 'Income') runningBal += txn.amount;
      else if (txn.type == 'Expense') runningBal -= txn.amount;
      txn.runningBalance = runningBal;
    }

    final summary = await AccountService.getSummary();

    return AccountsState(
      categories: loadedCategories,
      transactions: filteredTxns,
      totalIncome: summary.totalIncome,
      totalExpenses: summary.totalExpenses,
      netProfit: summary.netProfit,
      cashInHand: summary.cashInHand,
      bankBalance: summary.bankBalance,
      outstandingReceivables: 0, 
    );
  }

  Future<void> addTransaction(Map<String, dynamic> data) async {
    await TransactionService.saveTransaction(data);
    await loadTransactions();
  }
}
