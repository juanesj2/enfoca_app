import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/desafio.dart';

class DesafioService with ChangeNotifier {
  final String _baseUrl = 'http://enfoca.alwaysdata.net/api';

  List<Desafio> _todosLosDesafios = [];
  List<Desafio> _misDesafios = [];

  List<Desafio> get todosLosDesafios => [..._todosLosDesafios];
  List<Desafio> get misDesafios => [..._misDesafios];

  Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return null;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    return extractedUserData['token'];
  }

  Future<void> cargarTodo() async {
    try {
      await obtenerTodos();
    } catch (e) {
      print('Error obteniendo todos los desafíos: $e');
      rethrow;
    }

    try {
      await obtenerMisDesafios();
    } catch (e) {
      print(
        'Aviso: Fallo al obtener mis desafíos (Ignorando para evitar Pantalla Vacía): $e',
      );
      // No lanzamos excepcion para no bloquear la UI si el backend remoto falla
    }
  }

  Future<void> obtenerTodos() async {
    final token = await _obtenerToken();
    if (token == null) return;

    final url = Uri.parse('$_baseUrl/desafios');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> desafiosJson = data is List
            ? data
            : (data['data'] ?? []);
        _todosLosDesafios = desafiosJson
            .map((json) => Desafio.fromJson(json))
            .toList();
        notifyListeners();
      } else {
        throw Exception('Error al cargar todos los desafíos');
      }
    } catch (e) {
      print('Excepción en obtenerTodos: $e');
      rethrow;
    }
  }

  Future<void> obtenerMisDesafios() async {
    final token = await _obtenerToken();
    if (token == null) return;

    final url = Uri.parse('$_baseUrl/desafios/mis-desafios');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> desafiosJson = data is List
            ? data
            : (data['data'] ?? []);
        _misDesafios = desafiosJson
            .map((json) => Desafio.fromJson(json))
            .toList();
        notifyListeners();
      } else {
        throw Exception('Error al cargar mis desafíos');
      }
    } catch (e) {
      print('Excepción en obtenerMisDesafios: $e');
      rethrow;
    }
  }
}
