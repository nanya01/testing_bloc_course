import 'dart:math' as math show Random;

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testing_bloc_course/bloc_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: BlocProvider(
            create: (_) => PersonsBloc(), child: const BlocSample()));
  }
}

const names = ["Foo", "Bar", "Baz"];

extension RandomElement<T> on Iterable<T> {
  T getRandomElement() => elementAt(math.Random().nextInt(length));
}

// cubit
class NamesCubit extends Cubit<String?> {
  NamesCubit() : super(null);

  void pickRandomName() => emit(names.getRandomElement());
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final NamesCubit cubit;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    cubit = NamesCubit();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: StreamBuilder<String?>(
            stream: cubit.stream,
            builder: (context, snapshot) {
              final button = TextButton(
                  onPressed: () {
                    cubit.pickRandomName();
                  },
                  child: const Text("Pick a random name"));

              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return button;

                case ConnectionState.waiting:
                  return button;

                case ConnectionState.active:
                  return Column(
                    children: [Text(snapshot.data ?? ''), button],
                  );

                case ConnectionState.done:
                  return const SizedBox();
              }
            }),
      ),
    );
  }
}
