import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Manager',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ---------------- Login Screen ----------------

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Teacher Login")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Enter Username'),
                validator: (value) => value!.isEmpty ? 'Username required' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Login"),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DashboardScreen(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Dashboard Screen ----------------

class DashboardScreen extends StatelessWidget {
  final List<String> classList = ['BSCS 6A', 'BSCS 6B'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: ListView.builder(
        itemCount: classList.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(classList[index]),
          trailing: Icon(Icons.arrow_forward),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceScreen(classList[index]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Attendance Screen ----------------

class AttendanceScreen extends StatefulWidget {
  final String className;
  AttendanceScreen(this.className);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final List<Map<String, dynamic>> students = [];
  final TextEditingController _nameController = TextEditingController();
  final dbRef = FirebaseDatabase.instance.ref();
  bool showSubmitted = false;

  void _addStudent() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        students.add({'name': name, 'status': false});
        _nameController.clear();
      });
    }
  }

  void _submitAttendance() async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      for (var student in students) {
        await dbRef
            .child("attendance")
            .child(widget.className.replaceAll(" ", "_"))
            .child(formattedDate)
            .child(student['name'])
            .set(student['status'] ? 'Present' : 'Absent');
      }
      if (!mounted) return;
      setState(() => showSubmitted = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Attendance submitted to Firebase!")),
      );
    } catch (e) {
      print("Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit attendance")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance - ${widget.className.replaceAll(" ", "_")}")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Student Name'),
                  ),
                ),
                IconButton(onPressed: _addStudent, icon: Icon(Icons.add)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) => CheckboxListTile(
                title: Text(students[index]['name']),
                value: students[index]['status'],
                onChanged: (val) => setState(() => students[index]['status'] = val),
              ),
            ),
          ),
          ElevatedButton(
            child: Text("Submit Attendance"),
            onPressed: students.isNotEmpty ? _submitAttendance : null,
          ),
          if (showSubmitted)
            Expanded(
              child: ListView(
                children: students
                    .map((s) => ListTile(
                  title: Text(s['name']),
                  subtitle: Text(s['status'] ? 'Present' : 'Absent'),
                ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
