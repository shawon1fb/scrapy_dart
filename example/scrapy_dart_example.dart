import 'dart:convert';

import 'package:html/parser.dart' as html;
import 'package:http/http.dart';
import 'package:scrapy_dart/scrapy_dart.dart';

class Quote extends Item {
  String? quote;

  Quote({this.quote});

  @override
  String toString() {
    return "Quote : { quote : $quote }";
  }

  @override
  Map<String, dynamic> toJson() => {
        "quote": quote,
      };

  factory Quote.fromJson(String str) => Quote.fromMap(json.decode(str));

  factory Quote.fromMap(Map<String, dynamic> json) => Quote(
        quote: json["quote"],
      );
}

class Quotes extends Items<Quote> {
  final List<Quote> itemsList;

  Quotes({
    required this.itemsList,
  }) : super(items: itemsList);

  factory Quotes.fromJson(String str) => Quotes.fromMap(json.decode(str));

  factory Quotes.fromMap(Map<String, dynamic> json) => Quotes(
        itemsList: json["items"] == null
            ? <Quote>[]
            : List<Quote>.from(json["items"].map((x) => Quote.fromMap(x))),
      );
}

//
class BlogSpider extends Spider<Quote, Quotes> {
  BlogSpider({
    required String path,
    required List<String> startUrls,
    required Client client,
  }) : super(
          path: path,
          startUrls: startUrls,
          client: client,
        );

  @override
  Stream<String> parse(Response response) async* {
    final document = html.parse(response.body);
    final nodes = document.querySelectorAll("div.quote> span.text");

    for (var node in nodes) {
      yield node.innerHtml;
    }
  }

  @override
  Stream<String> transform(Stream<String> stream) async* {
    await for (String parsed in stream) {
      final transformed = parsed;
      yield transformed.substring(1, parsed.length - 1);
    }
  }

  @override
  Stream<Quote> save(Stream<String> stream) async* {
    await for (String transformed in stream) {
      final quote = Quote(quote: transformed);
      yield quote;
    }
  }
}

void main() async {
  var startUrls = [
    "http://quotes.toscrape.com/page/7/",
    "http://quotes.toscrape.com/page/8/",
    "http://quotes.toscrape.com/page/9/"
  ];
  Client client = Client();

  final spider = BlogSpider(
    startUrls: startUrls,
    client: client,
    path: 'example/myspider.json',
  );

  final stopw = Stopwatch()..start();

  await spider.startRequests();
  await spider.saveResult();
  final elapsed = stopw.elapsed;

  print("the program took $elapsed"); //the program took 0:00:00.279733
}
