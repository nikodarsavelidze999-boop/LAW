import 'package:flutter/material.dart';

// Dummy screen for Chat
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with AI')),
      body: Center(child: Text('AI Chat Screen')),
    );
  }
}

// Home Screen
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _controller = TextEditingController();
  bool _showSearch = false; // toggle search bar

  List<String> allTopics = [
    "Crimes Against the Person",
    "Cyber Crime",
    "Financial Crime",
    "Drug Offenses",
    "Property Crime"
  ];

  List<String> filteredTopics = [];

  @override
  void initState() {
    super.initState();
    filteredTopics = allTopics;
  }

  void _filterTopics(String query) {
    final results = allTopics.where((item) {
      return item.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredTopics = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F4F8),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen()),
          );
        },
        backgroundColor: Color(0xFF5B6F9F),
        child: Icon(Icons.chat_bubble_outline),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // Top Row with Toggle Search Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _showSearch
                      ? Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: Colors.grey),
                                SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    onChanged: _filterTopics,
                                    decoration: InputDecoration(
                                      hintText: "Filter topics...",
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _showSearch = false;
                                      _controller.clear();
                                      _filterTopics('');
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : Text(
                          "Home",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _showSearch = !_showSearch;
                      });
                    },
                  ),
                ],
              ),

              SizedBox(height: 20),

              // List of topics
              Expanded(
                child: ListView.builder(
                  itemCount: filteredTopics.length,
                  itemBuilder: (context, index) {
                    return _buildCard(filteredTopics[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  Card Widget
  Widget _buildCard(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          )
        ],
      ),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}