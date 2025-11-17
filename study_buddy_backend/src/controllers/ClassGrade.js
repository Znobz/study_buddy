class ClassGrade
{
    constructor(assignTypeBuffer, weights) {
        this.courseDict = {};
        this.currAvg = null;
        this.assignTypeBuffer = assignTypeBuffer;
        this.weights = weights;
        for (let i = 0; i < assignTypeBuffer.length; i++) {
            this.courseDict[assignTypeBuffer[i]] = {weight: this.weights[i], grades: [], avg : null};
        }
    }

    addGrade(assignType, name, grade) {
        if (this.courseDict[assignType]) {
            this.courseDict[assignType].grades.push({name : name, grade : grade});
        }
    }

    removeAssignment(assignType, name) {
        if (this.courseDict[assignType]) {
            this.courseDict[assignType].grades = this.courseDict[assignType].grades.filter(g => g.name !== assignmentName);
        }
    }


    calcTypeAvg(assignType) {
        let sum = 0;
        let len = this.courseDict[assignType].grades.length;
        this.courseDict[assignType].grades.forEach(grade => {
            sum += grade.grade;
        });
        this.courseDict[assignType].avg = (sum / len);
    }

    getTypeAvg(assignType) {
        if (this.courseDict[assignType].avg !== null) {
            return this.courseDict[assignType].avg;
        }
    }

    calcGradeAvg() {
        let gradeAve = 0;
        for (let type in this.courseDict) {
            gradeAve += this.getTypeAvg(type) * this.courseDict[type].weight;
        }
        this.currAvg = gradeAve;
    }

    getGradeAve() {
        if (this.currAvg != null) {
            return this.currAvg;
        }
    }

    getDict() {
        return this.courseDict;
    }

    // given the grade you want for the class, this calculates the greade you want for a particular
    // assignment type to pass the class
    calcPredGrade(desired_grade, assignType) {
        let type_sum = 0;
        let type_len = this.courseDict[assignType].grades.length + 1; // includes grade value we are trying to find
        let type_w = this.courseDict[assignType].weight;
        let tempAve = 0;
        // calculating current average except of the desired assignment type
        for (let type in this.courseDict) {
            if (type != assignType) {
                tempAve += this.getTypeAvg(type) * this.courseDict[type].weight;
            }
        }
        // Calculate current sum of grades in assignment type
        this.courseDict[assignType].grades.forEach(grade => {
            type_sum += grade.grade;
        });
        // return result of the assignment grade to obtain the value
        return ((desired_grade - tempAve) / type_w) * type_len - type_sum;
    }

    displayResults() {
        console.log("\n=== GRADE SUMMARY ===");
        console.log(`Class Average: ${this.getGradeAve().toFixed(2)}%`);
        console.log("\nAverage by Assignment Type:");
        for (let type in this.courseDict) {
            console.log(`  ${type}: ${this.getTypeAvg(type).toFixed(2)}%`);
        }
        console.log("=====================\n");
    }
}

import readline from 'readline';

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function question(prompt) {
    return new Promise(resolve => {
        rl.question(prompt, resolve);
    });
}


//Testing
async function main() {
    console.log("Welcome to the Class Grade Calculator!\n");

    // Step 1: Get assignment types and weights
    const typesInput = await question("Enter assignment types (comma-separated, e.g., 'Homework, Quizzes, Exams'): ");
    const types = typesInput.split(',').map(t => t.trim()).filter(t => t);

    const weightsInput = await question("Enter weights (comma-separated, e.g., '0.3, 0.3, 0.4'): ");
    const weights = weightsInput.split(',').map(w => parseFloat(w.trim())).filter(w => !isNaN(w));

    if (types.length === 0 || weights.length === 0 || types.length !== weights.length) {
        console.log("Error: Please enter matching numbers of assignment types and weights.");
        rl.close();
        return;
    }

    const gradeCalc = new ClassGrade(types, weights);

    // Step 2: Add initial grades
    console.log("\nNow add grades for each assignment type.");
    console.log("When done adding grades, type 'done'.\n");

    let addingGrades = true;
    while (addingGrades) {
        console.log("Available assignment types:", types.join(', '));
        const assignType = await question("Enter assignment type (or 'done' to finish): ");

        if (assignType.toLowerCase() === 'done') {
            addingGrades = false;
            break;
        }

        if (!types.includes(assignType)) {
            console.log("Invalid assignment type. Please try again.\n");
            continue;
        }

        const assignName = await question("Enter assignment name: ");
        const gradeInput = await question("Enter grade: ");
        const grade = parseFloat(gradeInput);

        if (isNaN(grade)) {
            console.log("Invalid grade. Please enter a number.\n");
            continue;
        }

        gradeCalc.addGrade(assignType, assignName, grade);
        console.log(`Added: ${assignName} (${assignType}) - Grade: ${grade}\n`);
    }

    // Step 3: Calculate and display initial results
    if (Object.values(gradeCalc.courseDict).every(type => type.grades.length === 0)) {
        console.log("No grades added. Exiting.");
        rl.close();
        return;
    }

    for (let type in gradeCalc.courseDict) {
        gradeCalc.calcTypeAvg(type);
    }
    console.log(gradeCalc.getDict());
    gradeCalc.calcGradeAvg();
    gradeCalc.displayResults();

    // Step 4: Add new assignments
    console.log("Now you can add new assignments to recalculate grades.");
    console.log("Type 'done' when finished.\n");

    let addingAssignments = true;
    while (addingAssignments) {
        const action = await question("Add a new assignment? (yes/no): ");

        if (action.toLowerCase() !== 'yes' && action.toLowerCase() !== 'y') {
            addingAssignments = false;
            break;
        }

        console.log("Available assignment types:", types.join(', '));
        const assignType = await question("Enter assignment type: ");

        if (!types.includes(assignType)) {
            console.log("Invalid assignment type. Please try again.\n");
            continue;
        }

        const assignName = await question("Enter assignment name: ");
        const gradeInput = await question("Enter grade: ");
        const grade = parseFloat(gradeInput);

        if (isNaN(grade)) {
            console.log("Invalid grade. Please enter a number.\n");
            continue;
        }

        gradeCalc.addGrade(assignType, assignName, grade);
        gradeCalc.calcGradeAvg();
        console.log(`\nAdded: ${assignName} (${assignType}) - Grade: ${grade}`);
        gradeCalc.displayResults();
    }

    // Step 5: Remove assignments
    console.log("Now you can remove assignments to recalculate grades.");
    console.log("Type 'done' when finished.\n");

    let removingAssignments = true;
    while (removingAssignments) {
        const action = await question("Remove an assignment? (yes/no): ");

        if (action.toLowerCase() !== 'yes' && action.toLowerCase() !== 'y') {
            removingAssignments = false;
            break;
        }

        console.log("\nAssignments by type:");
        for (let type in gradeCalc.courseDict) {
            if (gradeCalc.courseDict[type].grades.length > 0) {
                console.log(`\n${type}:`);
                gradeCalc.courseDict[type].grades.forEach((g, i) => {
                    console.log(`  ${i + 1}. ${g.name} - Grade: ${g.grade}`);
                });
            }
        }

        const assignType = await question("\nEnter assignment type: ");

        if (!gradeCalc.courseDict[assignType] || gradeCalc.courseDict[assignType].grades.length === 0) {
            console.log("Invalid assignment type or no assignments in this type.\n");
            continue;
        }

        const assignName = await question("Enter assignment name to remove: ");
        const assignment = gradeCalc.courseDict[assignType].grades.find(g => g.name === assignName);

        if (!assignment) {
            console.log("Assignment not found.\n");
            continue;
        }

        gradeCalc.removeAssignment(assignType, assignName);
        gradeCalc.calcGradeAvg();
        console.log(`\nRemoved: ${assignName}`);
        gradeCalc.displayResults();
    }

    console.log("Thank you for using the Grade Calculator!");
    rl.close();
}

main();