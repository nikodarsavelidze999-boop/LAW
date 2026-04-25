import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;

void main() {
  runApp(const LawsApp());
}

//APP 

class LawsApp extends StatefulWidget {
  const LawsApp({super.key});

  @override
  State<LawsApp> createState() => _LawsAppState();
}

class _LawsAppState extends State<LawsApp> {
  bool isDark = false;

  void toggleTheme() {
    setState(() {
      isDark = !isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "საქართველოს კანონმდებლობა",
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5B6F9F),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        toggleTheme: toggleTheme,
        isDark: isDark,
      ),
    );
  }
}

//MODELS

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

class SearchItem {
  final String categoryTitle;
  final String chapterTitle;
  final String article;

  SearchItem({
    required this.categoryTitle,
    required this.chapterTitle,
    required this.article,
  });
}

//HOME

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDark;

  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDark,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<LawCategory> lawCategories = [];
  List<SearchItem> searchIndex = [];
  List<SearchItem> searchResults = [];

  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  //DATA

  final List<Map<String, String>> lawSources = [
   {
      "title": "სისხლის სამართლის კოდექსი",
      "url": "https://matsne.gov.ge/ka/document/view/16426?publication=289"
    },
    {
      "title": "საქართველოს კონსტიტუცია",
      "url": "https://matsne.gov.ge/ka/document/view/30346?publication=36"
    },
     {
      "title": "სისხლის სამართლის საპროცესო კოდექსი",
      "url": "https://matsne.gov.ge/ka/document/view/90034?publication=175"
    },
     {
      "title": "საგადასახადო კოდექსი",
      "url": "https://matsne.gov.ge/ka/document/view/1043717?publication=242"
    },
     {
      "title": "საქართველოს ადმინისტრაციულ სამართალდარღვევათა კოდექსი",
      "url": "https://matsne.gov.ge/ka/document/view/28216?publication=615"
    },
      {
      "title": "საქართველოს სამოქალაქო კოდექსი",
      "url": "https://matsne.gov.ge/ka/document/view/31702?publication=138"
    },
     {
      "title": "საქართველოს სამოქალაქო საპროცესო კოდექსი",
      "url": "https://matsne.gov.ge/ka/document/view/29962?publication=177"
    },
      {
      "title": "საქართველოს შრომის კოდექსი",
      "url": "https://matsne.gov.ge/ka/document/view/1155567?publication=28"
    },
    {
      "title": "ზოგადი ადმინისტრაციული კოდექსი",
      "url": "https://matsne.gov.ge/ka/document/view/16270?publication=45"
    },
  ];

  Future<String> fetchHtml(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) return res.body;
    throw Exception("Failed");
  }

  LawCategory parseLaw(String raw, String title) {
    List<LawChapter> chapters = [];
    List<String> articles = [];
    String current = "";

    for (var line in raw.split('\n')) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith("თავი")) {
        if (current.isNotEmpty) {
          chapters.add(LawChapter(title: current, articles: List.from(articles)));
          articles.clear();
        }
        current = line;
      } else if (line.startsWith("მუხლი")) {
        articles.add(line);
      } else {
        if (articles.isNotEmpty) {
          articles.last += " $line";
        }
      }
    }

    if (current.isNotEmpty) {
      chapters.add(LawChapter(title: current, articles: articles));
    }

    return LawCategory(title: title, chapters: chapters);
  }

  Future<void> loadData() async {
    List<LawCategory> all = [];

    for (var src in lawSources) {
      final html = await fetchHtml(src["url"]!);
      final doc = parser.parse(html);
      final text = doc.body?.text ?? "";

      final law = parseLaw(text, src["title"]!);
      all.add(law);
    }

    searchIndex.clear();
    for (var c in all) {
      for (var ch in c.chapters) {
        for (var a in ch.articles) {
          searchIndex.add(
            SearchItem(
              categoryTitle: c.title,
              chapterTitle: ch.title,
              article: a,
            ),
          );
        }
      }
    }

    setState(() {
      lawCategories = all;
    });
  }

  //SEARCH (OPTIMIZED)

  void _search(String q) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (q.isEmpty) {
        setState(() => searchResults.clear());
        return;
      }

      q = q.toLowerCase();

      final results = searchIndex
          .where((item) => item.article.toLowerCase().contains(q))
          .take(100)
          .toList();

      setState(() => searchResults = results);
    });
  }

  //  UI 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: lawCategories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 110,
                  pinned: true,
                  floating: true,
                  flexibleSpace: const FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(left: 16, bottom: 12),
                    title: Text(
                      "საქართველოს კონსტიტუცია",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(widget.isDark
                          ? Icons.light_mode
                          : Icons.dark_mode),
                      onPressed: widget.toggleTheme,
                    ),
                  ],
                ),

                // Search logic
                if (_showSearch)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _search,
                        decoration: InputDecoration(
                          hintText: "მოძებნე მუხლი...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              _search("");
                              setState(() {
                                _showSearch = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                // Search REsult
                if (_searchController.text.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = searchResults[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.chapterTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.article,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: searchResults.length,
                    ),
                  )

                // Normal List
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = lawCategories[index];

                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: ExpansionTile(
                            title: Text(
                              category.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            children: category.chapters.map((chapter) {
                              return ExpansionTile(
                                title: Text(chapter.title),
                                children: chapter.articles
                                    .map((a) =>
                                        ListTile(title: Text(a)))
                                    .toList(),
                              );
                            }).toList(),
                          ),
                        );
                      },
                      childCount: lawCategories.length,
                    ),
                  ),
              ],
            ),
    );
  }
}