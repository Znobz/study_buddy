class ClassGrade {
  final Map<String, Map<String, dynamic>> courseDict = {};
  double? currAvg;

  ClassGrade(List<String> assignTypes, List<double> weights) {
    for (int i = 0; i < assignTypes.length; i++) {
      courseDict[assignTypes[i]] = {'weight': weights[i], 'grades': [], 'avg': null};
    }
  }

  void addGrade(String type, String name, double grade) {
    if (courseDict.containsKey(type)) {
      courseDict[type]!['grades'].add({'name': name, 'grade': grade});
    }
  }

  void removeGrade(String type, String name) {
    courseDict[type]!['grades'].removeWhere((g) => g['name'] == name);
  }

  void calcTypeAvg(String type) {
    final grades = courseDict[type]!['grades'] as List;
    if (grades.isEmpty) return;
    final avg = grades.fold<double>(0, (sum, g) => sum + g['grade']) / grades.length;
    courseDict[type]!['avg'] = avg;
  }

  void calcGradeAvg() {
    currAvg = 0;
    for (final type in courseDict.keys) {
      calcTypeAvg(type);
      currAvg = currAvg! + (courseDict[type]!['avg'] ?? 0) * (courseDict[type]!['weight']);
    }
  }

  double get totalAvg => currAvg ?? 0;
}