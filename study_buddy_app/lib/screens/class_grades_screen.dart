import 'package:flutter/material.dart';
import '../models/class_grade.dart';

class ClassGradesScreen extends StatefulWidget {
  const ClassGradesScreen({super.key});

  @override
  State<ClassGradesScreen> createState() => _ClassGradesScreenState();
}

class _ClassGradesScreenState extends State<ClassGradesScreen> {
  late ClassGrade classGrade;
  final TextEditingController typeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    classGrade = ClassGrade(['Homework', 'Quiz', 'Exam'], [0.3, 0.3, 0.4]);
  }

  void _addGrade() {
    if (typeController.text.isEmpty ||
        nameController.text.isEmpty ||
        gradeController.text.isEmpty) return;

    final grade = double.tryParse(gradeController.text);
    if (grade == null) return;

    setState(() {
      classGrade.addGrade(typeController.text, nameController.text, grade);
      classGrade.calcGradeAvg();
    });

    typeController.clear();
    nameController.clear();
    gradeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Grades')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: 'Type (e.g. Homework)'),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Assignment Name'),
            ),
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
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: classGrade.courseDict.entries.map((entry) {
                  final type = entry.key;
                  final data = entry.value;
                  final avg = data['avg']?.toStringAsFixed(2) ?? '--';
                  final grades = data['grades'] as List;
                  return Card(
                    child: ExpansionTile(
                      title: Text('$type - Avg: $avg'),
                      children: [
                        ...grades.map((g) => ListTile(
                              title: Text(g['name']),
                              subtitle: Text('${g['grade']}%'),
                            )),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Current Average: ${classGrade.totalAvg.toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
