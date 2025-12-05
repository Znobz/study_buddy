class ClassGrade {
  final Map<String, Map<String, dynamic>> courseDict = {};
  double? currAvg;

  ClassGrade([List<String>? assignTypes, List<double>? weights]) {
    // Initialize with default types if none provided
    final defaultTypes = assignTypes ?? ['Homework', 'Quiz', 'Exam'];
    final defaultWeights = weights ?? [0.3, 0.3, 0.4];

    for (int i = 0; i < defaultTypes.length; i++) {
      courseDict[defaultTypes[i]] = {
        'weight': defaultWeights[i],
        'grades': [],
        'avg': null
      };
    }
  }

  // Existing grade management methods
  void addGrade(String type, String name, double grade) {
    if (courseDict.containsKey(type)) {
      courseDict[type]!['grades'].add({'name': name, 'grade': grade});
    }
  }

  void removeGrade(String type, String name) {
    if (courseDict.containsKey(type)) {
      courseDict[type]!['grades'].removeWhere((g) => g['name'] == name);
    }
  }

  void calcTypeAvg(String type) {
    final grades = courseDict[type]!['grades'] as List;
    if (grades.isEmpty) {
      courseDict[type]!['avg'] = null;
      return;
    }
    final avg = grades.fold<double>(0, (sum, g) => sum + g['grade']) / grades.length;
    courseDict[type]!['avg'] = avg;
  }

  void calcGradeAvg() {
    currAvg = 0;
    double totalWeight = 0;

    for (final type in courseDict.keys) {
      calcTypeAvg(type);
      final avg = courseDict[type]!['avg'];
      final weight = courseDict[type]!['weight'] as double;

      if (avg != null) {
        currAvg = currAvg! + (avg * weight);
        totalWeight += weight;
      }
    }

    // Handle case where total weight might not be 1.0 (100%)
    if (totalWeight > 0 && totalWeight != 1.0) {
      currAvg = currAvg! / totalWeight;
    }
  }

  double get totalAvg => currAvg ?? 0;

  // New grade type management methods
  void addGradeType(String typeName, double weight) {
    if (!courseDict.containsKey(typeName)) {
      courseDict[typeName] = {
        'weight': weight,
        'grades': [],
        'avg': null
      };
    }
  }

  void removeGradeType(String typeName) {
    courseDict.remove(typeName);
  }

  void updateGradeTypeWeight(String typeName, double newWeight) {
    if (courseDict.containsKey(typeName)) {
      courseDict[typeName]!['weight'] = newWeight;
    }
  }

  void updateGradeTypeName(String oldName, String newName) {
    if (courseDict.containsKey(oldName) && !courseDict.containsKey(newName)) {
      final data = courseDict[oldName]!;
      courseDict.remove(oldName);
      courseDict[newName] = data;
    }
  }

  List<String> get gradeTypes => courseDict.keys.toList();

  double getGradeTypeWeight(String typeName) {
    return courseDict[typeName]?['weight'] ?? 0.0;
  }

  bool hasGradesInType(String typeName) {
    if (!courseDict.containsKey(typeName)) return false;
    final grades = courseDict[typeName]!['grades'] as List;
    return grades.isNotEmpty;
  }

  // Get total weight of all grade types (useful for validation)
  double get totalWeight {
    return courseDict.values.fold<double>(0, (sum, data) => sum + (data['weight'] as double));
  }
}