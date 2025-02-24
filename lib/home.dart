import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailyhunt/NewsPageDetail.dart';
import 'package:dailyhunt/api/news_api.dart';
import 'package:dailyhunt/model/news_model.dart';
import 'package:dailyhunt/profile_page.dart';
import 'package:dailyhunt/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  final String lang;
  Home({super.key, required this.lang});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<NewsModel> newsList = [];

  NewsApi newsApi = NewsApi();

  Future<void> getTopNews() async {
    List<NewsModel> fetchedNews = await newsApi.getTopHeadlines(widget.lang);
    setState(() {
      newsList = fetchedNews;
    });
  }

  @override
  void initState() {
    super.initState();
    getTopNews();
  }

  int _selectedIndex = 0;

  // List of screens for each tab
  late final List<Widget> _screens = [
    HomeScreen(lang: widget.lang), // Home Page
    SearchScreen(),
    ProfileScreen(), // Profile Page
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.green[200],
        title: const Text("The Daily Globe"),
        titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: "CustomPoppins"),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body:_screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.indigo[900],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.indigo[900],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.green[200],
            unselectedItemColor: Colors.white70,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home, size: 28),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search, size: 28),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person, size: 28),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: "CustomPoppins"),
        ),
        TextButton(
          onPressed: () {},
          child: Text('See all', style: TextStyle(color: Colors.indigo[900])),
        ),
      ],
    );
  }
}

class NewsCard extends StatelessWidget {
  final String category, title, source, date, image, content;
  const NewsCard(
      {super.key,
      required this.category,
      required this.title,
      required this.source,
      required this.image,
      required this.date,
      required this.content});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewsDetailPage(
                    title: title,
                    source: source,
                    publishedAt: date,
                    image: image,
                    content: content)));
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF009990),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                image: DecorationImage(
                  image: NetworkImage(image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.indigo[900],
                    ),
                    height: 20,
                    width: 100,
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: const TextStyle(
                          color: Colors.white, fontFamily: "CustomPoppins"),
                    ),
                  ),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: "CustomPoppins")),
                  const SizedBox(height: 5),
                  Text('$source • $date',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecommendationCard extends StatefulWidget {
  const RecommendationCard({super.key});

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF009990),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.business, color: Colors.black),
                  SizedBox(width: 5),
                  Text('Forbes', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              TextButton(onPressed: () {}, child: const Text('Follow')),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Tech Startup Secures \$50 Million Funding for Expansion',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.indigo[900],
            ),
            height: 20,
            width: 100,
            alignment: Alignment.center,
            child: Text(
              "Business",
              style: const TextStyle(
                  color: Colors.white, fontFamily: "CustomPoppins"),
            ),
          ),
        ],
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  final String lang;
  HomeScreen({super.key,required this.lang});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String formatDate(DateTime date) {
    String day = DateFormat('d').format(date);
    String suffix = getDaySuffix(int.parse(day));
    String formattedDate = "$day$suffix ${DateFormat('MMM yyyy').format(date)}";
    return formattedDate;
  }

  String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return "th";
    }
    switch (day % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }

  final User? userCredential = FirebaseAuth.instance.currentUser;

  List<NewsModel> newsList = [];

  NewsApi newsApi = NewsApi();

  Future<void> getTopNews() async {
    List<NewsModel> fetchedNews = await newsApi.getTopHeadlines(widget.lang);
    setState(() {
      newsList = fetchedNews;
    });
  }

  @override
  void initState() {
    super.initState();
    getTopNews();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   'Welcome back, ${FirebaseFirestore.instance.collection("users").doc(userCredential!.uid).get() ?? 'Guest'} !',
                      //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,fontFamily: "CustomPoppins"),
                      // ),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userCredential!.uid)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Text(
                              'Welcome back, Guest!',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "CustomPoppins"),
                            );
                          }
                          final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                          final userName = data?['name'] ?? 'Guest';
                          return Text(
                            'Welcome back, $userName !',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: "CustomPoppins"),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Discover a world of news that matters to you',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontFamily: "CustomPoppins"),
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(title: 'Trending news'),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: newsList.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      return NewsCard(
                          category: 'Business',
                          title: newsList[index].title,
                          source: newsList[index].source,
                          image: newsList[index].image,
                          date: DateFormat('d MMM yyyy')
                              .format(newsList[index].publishedAt),
                          content: newsList[index].content);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Recommendation'),
                const RecommendationCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
