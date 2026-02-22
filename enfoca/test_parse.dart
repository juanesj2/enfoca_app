import 'dart:convert';
import 'lib/models/grupo.dart';

void main() {
  String payload = '''
{
    "data": [
        {
            "id": 1,
            "nombre": "prueba",
            "descripcion": "Grupo de prueba",
            "usuarios": [
                {
                    "id": 1,
                    "name": "pepe",
                    "email": "pepe@gmail.com",
                    "created_at": "2026-01-12T12:29:01.000000Z",
                    "rol": "admin",
                    "updated_at": "2026-01-12T12:29:01.000000Z",
                    "esta_vetado": false,
                    "tiempo_restante_veto": null
                }
            ]
        }
    ]
}
''';

  final data = json.decode(payload);
  final List<dynamic> gruposJson = data['data'];

  try {
    final list = gruposJson.map((json) => Grupo.fromJson(json)).toList();
    print("SUCCESS Parsing. Count: \${list.length}");
    print("Group name: \${list[0].nombre}");
  } catch (e, stack) {
    print("ERROR Parsing: \$e");
    print(stack);
  }
}
