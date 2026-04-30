import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyProject());
}

class MyProject extends StatelessWidget {
  const MyProject({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const BudgetScreen(),
    );
  }
}

class Transaction {
  final String title;
  final double amount;
  final bool isIncome;
  final String date;

  Transaction({
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'isIncome': isIncome,
    'date': date,

  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      title: json['title'],
      amount: json['amount'],
      isIncome: json['isIncome'],
      date: json['date'],
    );
  }
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  double income = 0;
  double expense = 0;

  final List<Transaction> transactions = [];

  final amountController = TextEditingController();
  final descController = TextEditingController();
  DateTime? selectedDate;
  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }
  //save a string - save data
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> txList =
    transactions.map((tx) => jsonEncode(tx.toJson())).toList();

    await prefs.setStringList('transactions', txList);
    await prefs.setDouble('income', income);
    await prefs.setDouble('expense', expense);
  }
//read data
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    List<String>? txList = prefs.getStringList('transactions');

    if (txList != null) {
      setState(() {
        transactions.clear();
        transactions.addAll(
          txList.map((tx) => Transaction.fromJson(jsonDecode(tx))).toList(),
        );
        income = prefs.getDouble('income') ?? 0;
        expense = prefs.getDouble('expense') ?? 0;
      });
    }
  }

  void addTransaction(bool isIncome) {
    double amount = double.tryParse(amountController.text) ?? 0;
    String desc = descController.text;

    if (amount <= 0 || desc.isEmpty) return;

    setState(() {
      String currentDate = selectedDate != null
          ? selectedDate!.toString().substring(0, 10)
          : DateTime.now().toString().substring(0, 10);

      transactions.add(
        Transaction(
          title: desc,
          amount: amount,
          isIncome: isIncome,
          date: currentDate,
        ),
      );

      if (isIncome) {
        income += amount;
      } else {
        expense += amount;
      }
    });

    saveData();

    amountController.clear();
    descController.clear();
    selectedDate = null;
  }

  @override
  Widget build(BuildContext context) {
    double balance = income - expense;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.blue],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.account_box, color: Colors.white, size: 40),
                  SizedBox(height: 10)
                  ,
                  Text(
                    "Budget Tracker",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text("Clear All Data"),
              onTap: () {
                Navigator.pop(context);

                setState(() {
                  transactions.clear();
                  income = 0;
                  expense = 0;
                });

                saveData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All data cleared")),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About"),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("About"),
                    content: const Text(
                        "Budget Tracker App\nBuilt with Flutter"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("cancel"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Budget Tracker"),
        centerTitle: true,
        elevation: 0,
      ),
      //total balance
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Text("Total Balance",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Text(
                    "₹ ${balance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: buildCard("Income", income, Colors.green)),
                const SizedBox(width: 10),
                Expanded(child: buildCard("Expense", expense, Colors.red)),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount",
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: "Description",
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 15),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickDate,
                    child: Text(
                      selectedDate == null
                          ? "Select Date"
                          : "${selectedDate!.toLocal()}".split(' ')[0],
                    ),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => addTransaction(true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: const Text("Add Income"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => addTransaction(false),
                    style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Add Expense"),

                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: transactions.isEmpty
                  ? const Center(child: Text("No Transactions Yet"))
                  : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];

                  return Dismissible(
                    key: ValueKey(tx),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete,
                          color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      final removedTx = tx;

                      setState(() {
                        transactions.removeAt(index);
                        if (removedTx.isIncome) {
                          income -= removedTx.amount;
                        } else {
                          expense -= removedTx.amount;
                        }
                      });

                      saveData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                          const Text("Transaction deleted"),
                          action: SnackBarAction(
                            label: "UNDO",
                            onPressed: () {
                              setState(() {
                                transactions.insert(index, removedTx);
                                if (removedTx.isIncome) {
                                  income += removedTx.amount;
                                } else {
                                  expense += removedTx.amount;
                                }
                              });

                              saveData();
                            },
                          ),
                        ),
                      );
                    },
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tx.isIncome
                              ? Colors.green
                              : Colors.red,
                          child: Icon(
                            tx.isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: Colors.white,
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.title),
                            Text(
                              tx.date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        trailing: Text(
                          "₹ ${tx.amount}",
                          style: TextStyle(
                            color: tx.isIncome
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 5),
          Text(
            "₹ ${amount.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }
}