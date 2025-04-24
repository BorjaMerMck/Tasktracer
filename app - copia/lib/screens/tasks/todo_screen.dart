import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/task.dart';

class ToDoScreen extends StatefulWidget {
  @override
  _ToDoScreenState createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> with SingleTickerProviderStateMixin {
  final List<String> categories = ['Personal', 'Trabajo', 'Estudio', 'Otros'];
  final List<String> filters = ['Todas', 'Completadas', 'Incompletas'];
  String selectedFilter = 'Todas';

  List<Task> tasks = [];
  List<Map<String, dynamic>> homeMembers = [];
  String? selectedMember;

  late AnimationController _controller;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String homeId = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchUserHomeTasks();
  }

  Future<void> _fetchUserHomeTasks() async {
    final user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot snapshot = await _firestore
          .collection('homes')
          .where('members', arrayContains: {
        'uid': user.uid,
        'email': user.email,
      })
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          homeId = snapshot.docs.first.id;
        });
        await _loadTasks();
        await _loadHomeMembers();
      }
    }
  }

  Future<void> _loadTasks() async {
    try {
      final tasksSnapshot = await _firestore
          .collection('homes')
          .doc(homeId)
          .collection('tasks')
          .get();
      setState(() {
        tasks =
            tasksSnapshot.docs.map((doc) => Task.fromDocument(doc)).toList();
      });
    } catch (e) {
      print("Error loading tasks: $e");
    }
  }

  List<Task> _filterTasks() {
    if (selectedFilter == 'Completadas') {
      return tasks.where((task) => task.isCompleted).toList();
    } else if (selectedFilter == 'Incompletas') {
      return tasks.where((task) => !task.isCompleted).toList();
    } else {
      return tasks;
    }
  }


  Future<void> _loadHomeMembers() async {
    try {
      final homeDoc = await _firestore.collection('homes').doc(homeId).get();
      final List<dynamic> members = homeDoc['members'];

      setState(() {
        homeMembers = members
            .map((member) =>
        {
          'uid': member['uid'],
          'email': member['email'],
        })
            .toList();
      });
    } catch (e) {
      print("Error loading members: $e");
    }
  }

  Future<void> _addNewTask(String name, String category, bool isDaily) async {
    final newTask = Task(
      id: '',
      name: name,
      category: category,
      assignedTo: selectedMember ?? 'Unassigned',
      isCompleted: false,
      isDaily: isDaily,
    );
    final doc = await _firestore.collection('homes').doc(homeId).collection(
        'tasks').add(newTask.toMap());

    setState(() {
      tasks.add(Task(
        id: doc.id,
        name: name,
        category: category,
        assignedTo: selectedMember ?? 'Unassigned',
        isDaily: isDaily,
      ));
    });
  }

  Future<void> _toggleCompleteTask(int index) async {
    final task = tasks[index];
    task.isCompleted = !task.isCompleted;

    await _firestore.collection('homes').doc(homeId).collection('tasks').doc(
        task.id).update({
      'isCompleted': task.isCompleted,
    });

    setState(() {
      tasks[index] = task;
    });
    _controller.forward(from: 0); // Start the animation
  }

  Future<void> _deleteTask(int index) async {
    final task = tasks[index];
    await _firestore.collection('homes').doc(homeId).collection('tasks').doc(
        task.id).delete();

    setState(() {
      tasks.removeAt(index);
    });
  }

  void _showAddTaskDialog() {
    String newTask = '';
    String selectedCategory = categories[0];
    selectedMember = null;
    bool isDaily = false;
    List<String> selectedDays = [];

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(
                'Nueva tarea', style: TextStyle(fontWeight: FontWeight.bold)),
            content: StatefulBuilder(
              builder: (context, setState) =>
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        onChanged: (value) => newTask = value,
                        decoration: InputDecoration(
                          hintText: "Ingrese la tarea",
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        onChanged: (value) =>
                            setState(() => selectedCategory = value!),
                        decoration: InputDecoration(
                          labelText: "Categoría",
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedMember,
                        onChanged: (value) =>
                            setState(() => selectedMember = value!),
                        decoration: InputDecoration(
                          labelText: "Asignar a",
                          border: OutlineInputBorder(),
                        ),
                        items: homeMembers.map((member) {
                          return DropdownMenuItem<String>(
                            value: member['email'],
                            child: Text(member['email']),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 10),
                      SizedBox(height: 10),
             /**
                      Text("Días de la semana:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 4.0,
                        children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((
                            day) {
                          final isSelected = selectedDays.contains(day);
                          return ChoiceChip(
                            label: Text(day),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (isSelected) {
                                  selectedDays.remove(day);
                                } else {
                                  selectedDays.add(day);
                                }
                              });
                            },
                            selectedColor: Colors.blue,
                          );
                        }).toList(),
                      ),
                 */
                      CheckboxListTile(
                        title: Text("¿Repetir diariamente?"),
                        value: isDaily,
                        onChanged: (value) {
                          setState(() {
                            isDaily = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (newTask.isNotEmpty) {
                    _addNewTask(newTask, selectedCategory, isDaily);
                  }
                  Navigator.of(context).pop();
                },
                child: Text('Añadir'),
              ),
            ],
          ),
    );
  }


  void _showEditTaskDialog(int index) {
    final TextEditingController controller = TextEditingController(
        text: tasks[index].name);
    String selectedCategory = tasks[index].category;

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(
                'Editar tarea', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Ingrese la tarea actualizada",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Categoría",
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    _editTask(index, controller.text, selectedCategory);
                  }
                  Navigator.of(context).pop();
                },
                child: Text('Guardar'),
              ),
            ],
          ),
    );
  }

  Future<void> _editTask(int index, String newTaskName,
      String newCategory) async {
    final task = tasks[index];
    task.name = newTaskName;
    task.category = newCategory;

    await _firestore.collection('homes').doc(homeId).collection('tasks').doc(
        task.id).update(task.toMap());

    setState(() {
      tasks[index] = task;
    });
  }


  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filterTasks();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'Lista de Tareas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          DropdownButton<String>(
            value: selectedFilter,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedFilter = value;
                });
              }
            },
            items: filters.map((filter) {
              return DropdownMenuItem<String>(
                value: filter,
                child: Text(filter),
              );
            }).toList(),
          ),
        ],
      ),
      body: filteredTasks.isEmpty
          ? Center(child: Text('No hay tareas'))
          : ListView.builder(
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return Dismissible(
            key: ValueKey(task.id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _deleteTask(index);
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: task.isCompleted
                                ? Colors.green
                                : task.isDaily
                                ? Colors.blue[800]
                                : Colors.black,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      if (task.isDaily)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.repeat, size: 18, color: Colors.blueAccent),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${task.category} - Asignado a: ${task.assignedTo}',
                    style: TextStyle(color: Colors.indigo, fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: task.isCompleted ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => _toggleCompleteTask(index),
                        tooltip: 'Completar',
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert),
                        onSelected: (String choice) {
                          if (choice == 'Editar') {
                            _showEditTaskDialog(index);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'Editar',
                            child: Text('Editar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  children: task.isDaily
                      ? [
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                      child: Wrap(
                        spacing: 6.0,
                        children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) {
                          final selected = task.repeatDays.contains(day);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (day == 'D') {
                                  task.repeatDays = ['D'];
                                } else {
                                  if (task.repeatDays.contains('D')) {
                                    task.repeatDays.remove('D');
                                  }
                                  if (selected) {
                                    task.repeatDays.remove(day);
                                  } else {
                                    task.repeatDays.add(day);
                                  }
                                }

                                _firestore
                                    .collection('homes')
                                    .doc(homeId)
                                    .collection('tasks')
                                    .doc(task.id)
                                    .update({'repeatDays': task.repeatDays});
                              });
                            },
                            child: Container(
                              padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: selected ? Colors.green : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ]
                      : [],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Añadir nueva tarea',
        child: Icon(Icons.add_task_rounded, size: 28),
        backgroundColor: Colors.blue,
      ),
    );
  }
}