import 'package:flutter/material.dart';
import '../models/class_grade.dart';

class ClassGradesScreen extends StatefulWidget {
  const ClassGradesScreen({super.key});

  @override
  State<ClassGradesScreen> createState() => _ClassGradesScreenState();
}

class _ClassGradesScreenState extends State<ClassGradesScreen> {
  late ClassGrade classGrade;

  // Controllers for grade entry
  final TextEditingController nameController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();
  String? selectedGradeType;

  // Controllers for grade type management
  final TextEditingController newTypeController = TextEditingController();
  final TextEditingController newWeightController = TextEditingController();
  bool showAddTypeForm = false;

  @override
  void initState() {
    super.initState();
    classGrade = ClassGrade(); // Uses default types
    selectedGradeType = classGrade.gradeTypes.first;
  }

  @override
  void dispose() {
    nameController.dispose();
    gradeController.dispose();
    newTypeController.dispose();
    newWeightController.dispose();
    super.dispose();
  }

  void _addGrade() {
    if (selectedGradeType == null ||
        nameController.text.isEmpty ||
        gradeController.text.isEmpty) return;

    final grade = double.tryParse(gradeController.text);
    if (grade == null) return;

    setState(() {
      classGrade.addGrade(selectedGradeType!, nameController.text, grade);
      classGrade.calcGradeAvg();
    });

    nameController.clear();
    gradeController.clear();
  }

  void _addGradeType() {
    if (newTypeController.text.isEmpty || newWeightController.text.isEmpty) return;

    final weight = double.tryParse(newWeightController.text);
    if (weight == null) return;

    // Convert percentage to decimal (e.g., 15% -> 0.15)
    final weightDecimal = weight / 100;

    setState(() {
      classGrade.addGradeType(newTypeController.text, weightDecimal);
      if (selectedGradeType == null) {
        selectedGradeType = newTypeController.text;
      }
      showAddTypeForm = false;
    });

    newTypeController.clear();
    newWeightController.clear();
  }

  void _removeGradeType(String typeName) {
    if (classGrade.hasGradesInType(typeName)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('$typeName has existing grades. Are you sure you want to delete it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmRemoveGradeType(typeName);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      _confirmRemoveGradeType(typeName);
    }
  }

  void _confirmRemoveGradeType(String typeName) {
    setState(() {
      classGrade.removeGradeType(typeName);
      if (selectedGradeType == typeName) {
        selectedGradeType = classGrade.gradeTypes.isNotEmpty ? classGrade.gradeTypes.first : null;
      }
      classGrade.calcGradeAvg();
    });
  }

  void _editGradeType(String typeName) {
    final currentWeight = (classGrade.getGradeTypeWeight(typeName) * 100).toStringAsFixed(1);
    final nameController = TextEditingController(text: typeName);
    final weightController = TextEditingController(text: currentWeight);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Grade Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Type Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weight (%)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newWeight = double.tryParse(weightController.text);

              if (newName.isNotEmpty && newWeight != null) {
                setState(() {
                  if (newName != typeName) {
                    classGrade.updateGradeTypeName(typeName, newName);
                    if (selectedGradeType == typeName) {
                      selectedGradeType = newName;
                    }
                  }
                  classGrade.updateGradeTypeWeight(newName, newWeight / 100);
                  classGrade.calcGradeAvg();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Grades')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Grade Entry Section (Top)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedGradeType,
                      decoration: const InputDecoration(labelText: 'Type (e.g. Homework)'),
                      items: classGrade.gradeTypes.map((type) {
                        final weight = (classGrade.getGradeTypeWeight(type) * 100).toStringAsFixed(1);
                        return DropdownMenuItem(
                          value: type,
                          child: Text('$type ($weight%)'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGradeType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Assignment Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: gradeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Grade (%)'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addGrade,
                      child: const Text('Add Grade'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Assignment Listings Section with integrated grade type management
            Expanded(
              child: ListView(
                children: [
                  // Add Grade Type Button (above assignment lists)
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('Add Grade Type'),
                          onTap: () {
                            setState(() {
                              showAddTypeForm = !showAddTypeForm;
                            });
                          },
                        ),
                        if (showAddTypeForm)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TextField(
                                  controller: newTypeController,
                                  decoration: const InputDecoration(labelText: 'Grade Type Name'),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: newWeightController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Weight (%)'),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          showAddTypeForm = false;
                                        });
                                        newTypeController.clear();
                                        newWeightController.clear();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: _addGradeType,
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Assignment Lists with editable headers
                  ...classGrade.courseDict.entries.map((entry) {
                    final type = entry.key;
                    final data = entry.value;
                    final avg = data['avg']?.toStringAsFixed(2) ?? '--';
                    final weight = ((data['weight'] as double) * 100).toStringAsFixed(1);
                    final grades = data['grades'] as List;

                    return Card(
                      child: ExpansionTile(
                        title: GestureDetector(
                          onTap: () => _editGradeType(type),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('$type - Avg: $avg% (Weight: $weight%)'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () => _editGradeType(type),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  size: 16,
                                  color: classGrade.hasGradesInType(type) ? Colors.orange : Colors.red,
                                ),
                                onPressed: () => _removeGradeType(type),
                              ),
                            ],
                          ),
                        ),
                        children: [
                          ...grades.map((g) => ListTile(
                            title: Text(g['name']),
                            subtitle: Text('${g['grade']}%'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  classGrade.removeGrade(type, g['name']);
                                  classGrade.calcGradeAvg();
                                });
                              },
                            ),
                          )),
                          if (grades.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No assignments yet'),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Current Average (Very Bottom)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Current Average: ${classGrade.totalAvg.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total Weight: ${(classGrade.totalWeight * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: classGrade.totalWeight == 1.0 ? Colors.green : Colors.orange,
                      ),
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