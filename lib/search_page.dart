import 'dart:convert';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  bool isSearch=false;
  final searchController=TextEditingController();
  String query='';
  List<String> gifUrl=[];
  List<String> trendGifs=[];
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();


  final String api_key ="Q8y9zQPgdhgfVnoVE8Bhb4n8LMAdPzfR";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchGiphy();
    fetchTrendGiphy();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!isLoading && hasMore) {
        var limit=25;
        fetchGiphy(limit:limit+25);
      }
    }
  }
  String extractGiphyId(String url) {
    final parts = url.split('/');
    return parts.isNotEmpty ? parts.last : '';
  }

  Future<void> fetchGiphy({limit=25})async{
    log('Query $query');
      final url = "https://api.giphy.com/v1/gifs/search?api_key=$api_key&q=$query&limit=$limit&offset=0&rating=g&lang=en&bundle=messaging_non_clips";
      final response = await http.get(Uri.parse(url));
      if(response.statusCode==200){
        log("response giphy ${response.body}");
        final result = jsonDecode(response.body);
        var gifs=result['data'] as List;
        setState(() {
          gifUrl = gifs.map((gif) => gif['images']?['fixed_height']?['url'] as String).toList();
          log("gif $gifUrl");
        });
      }
  }

  void onSearch(String value) {
    setState(() {
      query = value.trim();
      gifUrl.clear();
      hasMore = true;
    });
    fetchGiphy();
  }

  Future<void> fetchTrendGiphy()async{
    final url = "https://api.giphy.com/v1/gifs/trending?api_key=$api_key&limit=25&offset=0&rating=g&bundle=messaging_non_clips";
    final response = await http.get(Uri.parse(url));
    if(response.statusCode==200){
      log("response ${response.body}");
      final result = jsonDecode(response.body);
      final trendsGifs=result['data'] as List;
      setState(() {
        trendGifs = trendsGifs.map((gif) => gif['images']?['fixed_height']?['url'] as String).toList();
        log("trendGifs $trendsGifs");
      });
    }
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: isSearch?TextField(
        controller: searchController,
        onChanged: (value){
          setState(() {
            query=value;
            onSearch(query);
            log("message $query");
          });
          log("query $query");
        },
        decoration: InputDecoration(
          label: Text('Search...'),
          hintText: 'Search...',
          border: OutlineInputBorder(),
          prefix: Icon(Icons.search),
          suffixIcon: IconButton(onPressed: (){
            setState(() {
              isSearch=!isSearch;
            });
          }, icon: Icon(Icons.cancel))
        ),
      ):Text("Giphy"),
      actions: [
        if(!isSearch)IconButton(onPressed: (){
          setState(() {
            isSearch=!isSearch;
          });
        }, icon: Icon(Icons.search))
      ],),
      
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: gifUrl.isEmpty
           ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Padding(
                 padding: const EdgeInsets.all(8.0),
                 child: Text('Trends gif'),
               ),
               Expanded(
                 child: GridView.builder(
                           controller: _scrollController,
                           padding: EdgeInsets.all(8),
                           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                           ),
                           itemCount: trendGifs.length + (isLoading ? 1 : 0),
                           itemBuilder: (context, index) {
                  if (index < trendGifs.length) {
                    return Image.network(trendGifs[index]);
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                           },
                         ),
               ),
             ],
           )
          : GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: gifUrl.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < gifUrl.length) {
              return Image.network(gifUrl[index]);
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        )
      )),
    );
  }
}
