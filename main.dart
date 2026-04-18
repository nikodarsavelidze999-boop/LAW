import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'screens/intro_screen.dart';
import 'screens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
   WidgetsFlutterBinding.ensureInitialized();


     SharedPreferences prefs = await SharedPreferences.getInstance();
  bool seenIntro = prefs.getBool('seenIntro') ?? false;


  runApp(LawsApp(seenIntro: seenIntro));
}

class LawsApp extends StatelessWidget {
  final bool seenIntro;

  
   const LawsApp({super.key, required this.seenIntro});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "საქართველოს კანონმდებლობა",
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
    '/': (context) => const IntroScreen(),
    '/home': (context) => const HomeScreen(),
    '/chat': (context) => ChatScreen(),
},
    );
  }
}

// MODELS
class LawCategory {
  final String title;
  final List<LawChapter> chapters;

  LawCategory({required this.title, required this.chapters});
}

class LawChapter {
  final String title;
  final List<String> articles;

  LawChapter({required this.title, required this.articles});
}

// HOME
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<LawCategory> lawCategories = [];
  List<LawCategory> filteredCategories = [];

  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ALL LAWS
  final List<Map<String, String>> lawSources = [
    {
      "title": "სისხლის სამართლის საპროცესო კოდექსი",
      "url":
          "https://matsne.gov.ge/ka/document/view/90034?publication=175"
    },
    {
      "title": "საგადასახადო კოდექსი",
      "url":
          "https://matsne.gov.ge/ka/document/view/1043717?publication=242"
    },
    {
      "title": "საქართველოს ადმინისტრაციულ სამართალდარღვევათა კოდექსი",
      "url":
          "https://matsne.gov.ge/ka/document/view/28216?publication=615"
    },
    {
      "title": "საქართველოს სამოქალაქო კოდექსი",
      "url":
          "https://matsne.gov.ge/ka/document/view/31702?publication=138"
    },
    {
      "title": "საქართველოს სამოქალაქო საპროცესო კოდექსი",
      "url":
          "https://matsne.gov.ge/ka/document/view/29962?publication=177"
    },
    {
      "title": "საქართველოს შრომის კოდექსი",
      "url":
          "https://matsne.gov.ge/ka/document/view/1155567?publication=28"
    },
    {
      "title": "საქართველოს კონსტიტუცია",
      "url":
          "https://matsne.gov.ge/ka/document/view/30346?publication=36"
    },
    {
      "title": "ზოგადსაგანმანათლებლო დაწესებულებების საჯარო სამართლის იურიდიულ პირებად დაფუძნებისა და საჯარო სკოლის წესდების დამტკიცების შესახებ",
      "url":
          "https://matsne.gov.ge/ka/document/view/61480?publication=0"
    },
    {
      "title": "ზოგადი ადმინისტრაციული კოდექსი",
      "url":
          "https://matsne.gov.ge/ka/document/view/16270?publication=45"
    },
    {
      "title": "სისხლის სამართლის კოდექსი",
      "url":
          "https://matsne.gov.ge/ka/document/view/16426?publication=289"
    },
  ];

  // FETCH
  Future<String> fetchHtml(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load page');
    }
  }

  // PARSER
  LawCategory parseLaw(String rawText, String title) {
    List<LawChapter> chapters = [];
    List<String> currentArticles = [];
    String currentChapterTitle = "";

    List<String> lines = rawText.split('\n');

    for (var line in lines) {
      line = line.trim();

      if (line.isEmpty) continue;

      if (line.startsWith("თავი")) {
        if (currentChapterTitle.isNotEmpty) {
          chapters.add(
            LawChapter(
              title: currentChapterTitle,
              articles: List.from(currentArticles),
            ),
          );
          currentArticles.clear();
        }
        currentChapterTitle = line;
      } else if (line.startsWith("მუხლი")) {
        currentArticles.add(line);
      } else {
        if (currentArticles.isNotEmpty) {
          currentArticles[currentArticles.length - 1] += " $line";
        }
      }
    }

    if (currentChapterTitle.isNotEmpty) {
      chapters.add(
        LawChapter(
          title: currentChapterTitle,
          articles: currentArticles,
        ),
      );
    }

    return LawCategory(title: title, chapters: chapters);
  }

  // LOAD
  Future<void> loadData() async {
    try {
      List<LawCategory> allLaws = [];

      for (var source in lawSources) {
        final html = await fetchHtml(source["url"]!);

        dom.Document document = parser.parse(html);
        String text = document.body?.text ?? "";

        final law = parseLaw(text, source["title"]!);

        allLaws.add(law);
      }

      setState(() {
        lawCategories = allLaws;
        filteredCategories = allLaws;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  // SEARCH
  void _filterSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredCategories = lawCategories;
      });
      return;
    }

    List<LawCategory> tempList = [];

    for (var category in lawCategories) {
      List<LawChapter> tempChapters = [];

      for (var chapter in category.chapters) {
        var matchingArticles = chapter.articles
            .where((article) =>
                article.toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (matchingArticles.isNotEmpty) {
          tempChapters.add(
            LawChapter(
              title: chapter.title,
              articles: matchingArticles,
            ),
          );
        }
      }

      if (tempChapters.isNotEmpty) {
        tempList.add(
          LawCategory(
            title: category.title,
            chapters: tempChapters,
          ),
        );
      }
    }

    setState(() {
      filteredCategories = tempList;
    });
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _filterSearch,
                decoration: InputDecoration(
                  hintText: "მოძებნე მუხლი...",
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _filterSearch('');
                      setState(() {
                        _showSearch = false;
                      });
                    },
                  ),
                ),
              )
            : const Text("საქართველოს კანონმდებლობა"),
        backgroundColor: const Color(0xFF5B6F9F),
        actions: !_showSearch
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _showSearch = true;
                    });
                  },
                )
              ]
            : null,
      ),
      floatingActionButton: FloatingActionButton(
    backgroundColor: Color(0xFF5B6F9F),
    child: Icon(Icons.chat, color: Colors.white),
    onPressed: () {
      Navigator.pushNamed(context, '/chat');
    },
  ),
      body: lawCategories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final category = filteredCategories[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ExpansionTile(
                    title: Text(
                      category.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    children: category.chapters.map((chapter) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: ExpansionTile(
                          title: Text(
                            chapter.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          children: chapter.articles.map((article) {
                            return ListTile(
                              title: Text(article),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}