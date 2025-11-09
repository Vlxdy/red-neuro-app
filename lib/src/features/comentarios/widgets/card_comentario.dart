import 'package:flutter/material.dart';
import '../../../models/comentario.dart';

class CardComentario extends StatelessWidget {
  final Comentario comentario;

  const CardComentario({super.key, required this.comentario});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(comentario.autor[0].toUpperCase())),
        title: Text(comentario.autor,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(comentario.texto),
        trailing: Text(
          '${comentario.fecha.hour.toString().padLeft(2, '0')}:${comentario.fecha.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}
