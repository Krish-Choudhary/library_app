// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:library_app/model/library_book.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() {
    return _AdminState();
  }
}

class _AdminState extends State<AdminHome> {
  final _form = GlobalKey<FormState>();
  final _form2 = GlobalKey<FormState>();
  String bookName = '';
  bool _sendingData = false;
  String authorName = '';
  bool isAvailable = true;
  DateTime? _selectedDate;
  File? _selectedImage;

  void _uploadBook() async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('cover_pages')
          .child('${bookName}_${DateTime.now()}.jpg');
      await storageRef.putFile(_selectedImage!);
      final imageUrl = await storageRef.getDownloadURL();
      final Map<String, dynamic> bookData = {
        'Book name': bookName,
        'Author name': authorName,
        'Availability': isAvailable,
        'Availability date': isAvailable ? DateTime.now() : _selectedDate,
        'Cover page': imageUrl,
      };
      await FirebaseFirestore.instance
          .collection('books')
          .doc(bookName)
          .set(bookData);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString()),
          duration: const Duration(seconds: 2),
        ));
      }
    }
    setState(() {
      bookName = '';
      authorName = '';
      _sendingData = false;
      _selectedDate = null;
      _selectedImage = null;
    });
    _form.currentState!.reset();
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Book Uploaded'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  void _saveBook() {
    final isValid = _form.currentState!.validate();
    if (!isValid) {
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Upload Cover page'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    if (!isAvailable && _selectedDate == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select Availability Date'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    _form.currentState!.save();
    setState(() {
      _sendingData = true;
    });
    _uploadBook();
  }

  void _selectPicture() async {
    ImageSource? source;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withAlpha(178),
                      size: 100,
                    ),
                    onTap: () {
                      setState(() {
                        source = ImageSource.camera;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const Text(
                    'Camera',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    child: Icon(
                      Icons.image,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withAlpha(178),
                      size: 100,
                    ),
                    onTap: () {
                      setState(() {
                        source = ImageSource.gallery;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const Text(
                    'Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: source!,
      maxWidth: 600,
    );

    if (pickedImage == null) {
      return;
    }
    setState(() {
      _selectedImage = File(pickedImage.path);
    });
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year, now.month, now.day + 30),
    );
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  int _selectedPageIndex = 0;
  String _username = '';
  bool issue = true;

  void issueBook() async {
    final isValid = _form2.currentState!.validate();
    if (!isValid) return;
    if (issue && _selectedDate == null) {
      return;
    }
    setState(() {
      _sendingData = true;
    });
    _form2.currentState!.save();
    await FirebaseFirestore.instance
        .collection('books')
        .doc(bookName)
        .update({'Availability': !issue});
    if (issue) {
      await FirebaseFirestore.instance
          .collection('books')
          .doc(bookName)
          .update({'Availability date': _selectedDate});
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: issue ? const Text('Book issued') : const Text("Book returned"),
      duration: const Duration(seconds: 2),
    ));

    setState(() {
      _sendingData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget dropDown = DropdownButtonFormField(
      decoration: const InputDecoration(labelText: "Availability"),
      value: isAvailable,
      items: const [
        DropdownMenuItem(
          value: true,
          child: Text('Available',
              style: TextStyle(color: Color.fromARGB(255, 17, 145, 21))),
        ),
        DropdownMenuItem(
          value: false,
          child: Text(
            'Not-Available',
            style: TextStyle(color: Color.fromARGB(255, 150, 27, 19)),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          isAvailable = value!;
        });
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add book"),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add book',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervised_user_circle),
            label: 'Issue/Return book',
          ),
        ],
        currentIndex: _selectedPageIndex,
        onTap: (value) {
          setState(() {
            _selectedPageIndex = value;
          });
        },
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: _selectedPageIndex == 0
                  ? Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedImage != null)
                            GestureDetector(
                                onTap: _selectPicture,
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.fitHeight,
                                  height: 200,
                                )),
                          if (_selectedImage == null)
                            TextButton.icon(
                              icon: const Icon(Icons.camera_alt),
                              label: const Text("Take Picture"),
                              onPressed: _selectPicture,
                            ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Book Name'),
                            autocorrect: false,
                            initialValue: bookName,
                            validator: (value) {
                              if (value == null) {
                                return 'Book name can\'t be null';
                              }
                              if (value.trim().length < 2) {
                                return 'Book name is too short';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              setState(() {
                                bookName = newValue!;
                              });
                            },
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Author Name'),
                            autocorrect: false,
                            keyboardType: TextInputType.name,
                            initialValue: authorName,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null) {
                                return 'Author name can\'t be null';
                              }
                              if (value.trim().length < 4) {
                                return 'Author name is too short';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              setState(() {
                                authorName = newValue!;
                              });
                            },
                          ),
                          isAvailable
                              ? Center(
                                  child: SizedBox(
                                    width: 150,
                                    child: dropDown,
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(child: dropDown),
                                    const SizedBox(width: 25),
                                    _selectedDate == null
                                        ? const Text(
                                            'No date selected',
                                            style: TextStyle(fontSize: 16),
                                          )
                                        : Text(
                                            formatter.format(_selectedDate!),
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                    const SizedBox(width: 15),
                                    SizedBox(
                                        width: 20,
                                        child: GestureDetector(
                                          onTap: _presentDatePicker,
                                          child:
                                              const Icon(Icons.calendar_month),
                                        )),
                                    const SizedBox(width: 15),
                                  ],
                                ),
                          const SizedBox(height: 15),
                          Center(
                            child: ElevatedButton(
                              onPressed: _sendingData ? null : _saveBook,
                              child: _sendingData
                                  ? const CircularProgressIndicator()
                                  : const Text('Add book'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Form(
                      key: _form2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Book Name'),
                            autocorrect: false,
                            initialValue: bookName,
                            validator: (value) {
                              if (value == null) {
                                return 'Book name can\'t be null';
                              }
                              if (value.trim().length < 2) {
                                return 'Book name is too short';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              setState(() {
                                bookName = newValue!;
                              });
                            },
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Username'),
                            autocorrect: false,
                            initialValue: _username,
                            validator: (value) {
                              if (value == null) {
                                return 'Username can\'t be null';
                              }
                              if (value.trim().length < 2) {
                                return 'Username is too short';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              setState(() {
                                _username = newValue!;
                              });
                            },
                          ),
                          if (!issue)
                            DropdownButtonFormField(
                              items: const [
                                DropdownMenuItem(
                                    value: true,
                                    child: Text(
                                      'Issue',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 15, 144, 19)),
                                    )),
                                DropdownMenuItem(
                                    value: false,
                                    child: Text(
                                      'Return',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 114, 19, 12)),
                                    )),
                              ],
                              value: issue,
                              onChanged: (value) {
                                setState(() {
                                  issue = value!;
                                });
                              },
                            ),
                          if (issue)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField(
                                    items: const [
                                      DropdownMenuItem(
                                          value: true,
                                          child: Text(
                                            'Issue',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromARGB(
                                                    255, 15, 144, 19)),
                                          )),
                                      DropdownMenuItem(
                                          value: false,
                                          child: Text(
                                            'Return',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromARGB(
                                                    255, 114, 19, 12)),
                                          )),
                                    ],
                                    value: issue,
                                    onChanged: (value) {
                                      setState(() {
                                        issue = value!;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 25),
                                _selectedDate == null
                                    ? const Text(
                                        'No date selected',
                                        style: TextStyle(fontSize: 16),
                                      )
                                    : Text(
                                        formatter.format(_selectedDate!),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                const SizedBox(width: 15),
                                SizedBox(
                                    width: 20,
                                    child: GestureDetector(
                                      onTap: _presentDatePicker,
                                      child: const Icon(Icons.calendar_month),
                                    )),
                                const SizedBox(width: 15),
                              ],
                            ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _sendingData ? null : issueBook,
                            child: _sendingData
                                ? const CircularProgressIndicator()
                                : const Text('Submit'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
