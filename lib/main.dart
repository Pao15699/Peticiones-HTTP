import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Pokémon',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PokemonListPage(),
    );
  }
}

class PokemonListPage extends StatefulWidget {
  @override
  _PokemonListPageState createState() => _PokemonListPageState();
}

class _PokemonListPageState extends State<PokemonListPage> {
  int offset = 0;
  int limit = 20;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPokemonList();
  }

  Future<void> fetchPokemonList() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://pokeapi.co/api/v2/pokemon?offset=$offset&limit=$limit'));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> results = decoded['results'];

        for (var pokemonData in results) {
          final pokemonName = pokemonData['name'];
          await FirebaseFirestore.instance.collection('pokemons').add({
            'name': pokemonName,
          });
        }

        final nextUrl = decoded['next'];
        if (nextUrl != null) {
          offset += limit;
        }
      } else {
        throw Exception(
            'Error al cargar la lista de Pokémon. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Pokémon'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('pokemons').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final pokemons = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pokemons.length,
            itemBuilder: (context, index) {
              final pokemon = pokemons[index];
              return ListTile(
                title: Text(pokemon['name']),
              );
            },
          );
        },
      ),
    );
  }
}