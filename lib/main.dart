import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Pokémon',
      theme: ThemeData(
        primarySwatch: Colors.red,
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
  List<String> pokemonList = [];
  int offset = 0;
  final int limit = 20;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchPokemonList();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        fetchPokemonList();
      }
    });
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
        final data = json.decode(response.body);
        final results = data['results'] as List;

        setState(() {
          pokemonList
              .addAll(results.map((pokemon) => pokemon['name'].toString()).toList());
          offset += limit;
          hasMore = data['next'] != null;
        });
      } else {
        // Manejo de error por código de estado no exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en la API: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Manejo de error de red
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshList() async {
    setState(() {
      pokemonList.clear();
      offset = 0;
      hasMore = true;
    });
    await fetchPokemonList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Pokémon'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        child: pokemonList.isEmpty
            ? isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Center(
                    child: Text('No se encontraron Pokémon.'),
                  )
            : ListView.builder(
                controller: _scrollController,
                itemCount: pokemonList.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == pokemonList.length) {

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                    title: Text(
                      pokemonList[index].toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
