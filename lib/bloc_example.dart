import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadPersonAction implements LoadAction {
  final PersonsUrl url;
  const LoadPersonAction({required this.url}) : super();
}

enum PersonsUrl { persons1, persons2 }

extension UrlString on PersonsUrl {
  String get urlString {
    switch (this) {
      case PersonsUrl.persons1:
        return "http//192.168.1.101:33315/api/persons1.json";

      case PersonsUrl.persons2:
        return "http//127.0.0.0.1:5500/api/persons2.json";
    }
  }
}

class BlocSample extends StatefulWidget {
  const BlocSample({Key? key}) : super(key: key);

  @override
  State<BlocSample> createState() => BlocSampleState();
}

@immutable
class Person {
  final String name;
  final int age;

  const Person({required this.name, required this.age}) : super();

  Person.fromJson(Map<String, dynamic> json)
      : name = json["name"] as String,
        age = json["age"] as int;
}

Future<Iterable<Person>> getPerson(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetrievedFromCache;

  const FetchResult(
      {required this.persons, required this.isRetrievedFromCache});

  @override
  String toString() =>
      'FetchResult (isRetrievedFromCache = $isRetrievedFromCache, persons = $persons';
}

class PersonsBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<PersonsUrl, Iterable<Person>> _cache = {};
  PersonsBloc() : super(null) {
    on<LoadPersonAction>((event, emit) async {
      final url = event.url;
      if (_cache.containsKey(url)) {
        // we have the value in cache
        final cachePersons = _cache[url]!;
        final result =
            FetchResult(persons: cachePersons, isRetrievedFromCache: true);
        emit(result);
      } else {
        final persons = await getPerson(url.urlString);
        _cache[url] = persons;
        final result =
            FetchResult(persons: persons, isRetrievedFromCache: false);

        emit(result);
      }
    });
  }
}

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

class BlocSampleState extends State<BlocSample> {
  late final Bloc myBloc;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bloc"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              TextButton(
                  onPressed: () {
                    context
                        .read<PersonsBloc>()
                        .add(const LoadPersonAction(url: PersonsUrl.persons1));
                  },
                  child: const Text("Load json 1")),
              TextButton(
                  onPressed: () {
                    context
                        .read<PersonsBloc>()
                        .add(const LoadPersonAction(url: PersonsUrl.persons2));
                  },
                  child: const Text("Load json 2")),
            ],
          ),
          BlocBuilder<PersonsBloc, FetchResult?>(
              buildWhen: (previousResult, currentResult) {
            return previousResult?.persons != currentResult?.persons;
          }, builder: (context, fetchResult) {
            final persons = fetchResult?.persons;
            if (persons == null) {
              return const SizedBox();
            }
            return Expanded(
                child: ListView.builder(
                    itemCount: persons.length,
                    itemBuilder: (context, index) {
                      final person = persons[index]!;
                      return ListTile(
                        title: Text(person.name),
                      );
                    }));
          })
        ],
      ),
    );
  }
}
