import 'package:flutter/material.dart';
import 'db_helper.dart';

class AddTransactionPage extends StatefulWidget {
  final Function onAddTransaction;
  final Map<String, dynamic>? transactionToEdit;

  AddTransactionPage({required this.onAddTransaction, this.transactionToEdit});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedType;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      _titleController.text = widget.transactionToEdit!['title'];
      _amountController.text = widget.transactionToEdit!['amount'].toString();
      _selectedDate = DateTime.parse(widget.transactionToEdit!['date']);
      _selectedType = widget.transactionToEdit!['type'];
      _selectedCategory = widget.transactionToEdit!['category'];
    }
  }

  void _submitData() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedType != null && _selectedCategory != null) {
      final enteredTitle = _titleController.text;
      final enteredAmount = double.parse(_amountController.text);

      if (enteredTitle.isEmpty || enteredAmount <= 0) {
        print('Validation failed: Title is empty or amount is not greater than zero.');
        return;
      }

      final transaction = {
        'title': enteredTitle,
        'amount': enteredAmount,
        'date': _selectedDate!.toIso8601String(),
        'type': _selectedType,
        'category': _selectedCategory,
      };

      try {
        if (widget.transactionToEdit != null) {
          // Update existing transaction
          await DBHelper().updateTransaction(widget.transactionToEdit!['id'], transaction);
          print('Transaction updated successfully.');
        } else {
          // Insert new transaction
          await DBHelper().insertTransaction(transaction);
          print('Transaction inserted successfully.');
        }

        widget.onAddTransaction();

        Navigator.of(context).pop();
      } catch (error) {
        print('Error saving transaction: $error');
      }
    } else {
      print('Form validation failed or date/type/category not selected.');
    }
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionToEdit != null ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number.';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Please enter an amount greater than zero.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                items: ['Grocery', 'Entertainment', 'Other']
                    .map((type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a type.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text('Category'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Income'),
                      value: 'Income',
                      groupValue: _selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Expense'),
                      value: 'Expense',
                      groupValue: _selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'No Date Chosen!'
                          : 'Picked Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: Text(
                      'Choose Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitData,
                child: Text(widget.transactionToEdit != null ? 'Update Transaction' : 'Add Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}