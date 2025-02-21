import 'package:dailyhunt/home.dart';
import 'package:flutter/material.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  // Dictionary with language names as keys and language codes as values
  final Map<String, String> languages = {
    "English": "en",
    "Spanish": "es",
    "French": "fr",
    "German": "de",
    "Hindi": "hi",
    "Mandarin": "zh",
    "Japanese": "ja",
    "Arabic": "ar",
    "Marathi":"mr"
  };

  // Store selected language code
  String? _selectedLanguageCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Language"),
        backgroundColor: const Color(0xFF001A6E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Languages",
              style: TextStyle(
                color: Color(0xFF001A6E),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: "CustomPoppins"
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: languages.entries.map((entry) {
                  return Card(
                    elevation: 2,
                    child: RadioListTile<String>(
                      title: Text(entry.key), // Display language name
                      value: entry.value, // Use language code as value
                      groupValue: _selectedLanguageCode,
                      onChanged: (value) {
                        setState(() {
                          _selectedLanguageCode = value;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_selectedLanguageCode != null) {
            debugPrint("Selected Language: $_selectedLanguageCode");
            // Pass selected language code to API or next screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Selected Language: $_selectedLanguageCode")),
            );
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return Home(lang: _selectedLanguageCode!);
            }));
          }
        },
        label: const Text("Confirm",style: TextStyle(color: Colors.white),),
        icon: const Icon(Icons.check,color: Colors.white,),
        backgroundColor: const Color(0xFF001A6E),
      ),
    );
  }
}
