import 'package:dailyhunt/api/news_api.dart';
import 'package:dailyhunt/model/news_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  String lang;
  Home({super.key,required this.lang});

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

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    getTopNews();
  }

  String formatDate(DateTime date) {
    String day = DateFormat('d').format(date);
    String suffix =
        getDaySuffix(int.parse(day)); // Get ordinal suffix (st, nd, rd, th)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.green[200],
        title: Text("The Daily Globe"),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.menu, color: Colors.white),
        //   onPressed: () {},
        // ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back, Tyler!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Discover a world of news that matters to you',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Trending news'),
            SizedBox(
              height: MediaQuery.of(context).size.height *
                  0.35, // Set dynamic height for the NewsCard
              child: newsList.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator()) // Show loader while fetching
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
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Recommendation'),
            const RecommendationCard(),
          ],
        ),
      ),
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
            currentIndex: _selectedIndex, // Track active tab
            onTap: _onItemTapped, // Handle tab selection
            selectedItemColor: Colors.green[200], // Highlight selected tab
            unselectedItemColor:
                Colors.white70, // Less bright for inactive tabs
            showUnselectedLabels: false, // Hide unselected labels
            type: BottomNavigationBarType.fixed, // Keeps icons in place
            // elevation: 10,
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

class SectionHeader extends StatefulWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  State<SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<SectionHeader> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
  final String category, title, source, date, image;
  const NewsCard(
      {super.key,
      required this.category,
      required this.title,
      required this.source,
      required this.image,
      required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Color(0xFF009990),
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
                      color: Colors.white,
                    ),
                  ),
                ),
                // Chip(label: Text(widget.category, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.blue),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('$source • $date', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
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
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
