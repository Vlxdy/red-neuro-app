import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/pago_con_cita_resumen.dart';
import 'package:red_neuro_app/src/ui/pages/inicio/widgets/inicio_cita_compact_tile.dart';

class PagoConCitaModalSheet extends StatelessWidget {
  const PagoConCitaModalSheet({
    super.key,
    required this.pago,
    this.onTapVerCita,
  });

  final PagoConCitaResumen pago;
  final VoidCallback? onTapVerCita;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final money = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs ', decimalDigits: 2);
    final dateTime = DateFormat('dd/MM/yyyy HH:mm', 'es');
    final estadoColor = _estadoColor(theme, pago.estadoPago);

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.56,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, controller) {
          return Container(
            decoration: BoxDecoration(
              color: theme.bgCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    children: [
                      _SectionTitle(
                        title: 'Pago',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: estadoColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            pago.estadoPago.toUpperCase(),
                            style: TextStyle(color: estadoColor, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.bgCard2.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.payments_outlined,
                              label: 'Monto',
                              value: money.format(pago.monto),
                            ),
                            _InfoTile(
                              icon: Icons.wallet_outlined,
                              label: 'Método',
                              value: _textoDato(pago.metodoPago, pago),
                            ),
                            _InfoTile(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Tipo movimiento',
                              value: _textoDato(pago.tipoMovimiento, pago),
                            ),
                            _InfoTile(
                              icon: Icons.schedule_rounded,
                              label: 'Fecha pago',
                              value: _fechaPagoLabel(dateTime, pago),
                            ),
                            _InfoTile(
                              icon: Icons.qr_code_2_rounded,
                              label: 'Referencia',
                              value: pago.id.trim().isEmpty ? 'Sin registrar' : pago.id.trim(),
                            ),
                            _RegistroTile(
                              nombre: _registradoPorLabel(pago),
                              avatarUrl: pago.usuarioRegistroAvatarUrl,
                            ),
                          ],
                        ),
                      ),
                      if (pago.observacion.trim().isNotEmpty)
                        _InfoTile(
                          icon: Icons.notes_rounded,
                          label: 'Observación',
                          value: pago.observacion.trim(),
                        ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      const _SectionTitle(title: 'Cita resumida'),
                      const SizedBox(height: 8),
                      _CitaResumenCard(
                        pago: pago,
                        onTapVerCita: onTapVerCita,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatDate(DateFormat formatter, DateTime? value) {
    if (value == null) return '-';
    return formatter.format(value.toLocal());
  }

  static String _registradoPorLabel(PagoConCitaResumen pago) {
    if (pago.usuarioRegistroNombre.trim().isNotEmpty && pago.usuarioRegistroNombre.trim() != '-') {
      return pago.usuarioRegistroNombre.trim();
    }
    if (pago.estadoPago.toUpperCase() == 'PENDIENTE') return 'Pendiente de registro';
    return 'Sin dato de registro';
  }

  static String _fechaPagoLabel(DateFormat formatter, PagoConCitaResumen pago) {
    if (pago.fechaPago != null) return _formatDate(formatter, pago.fechaPago);
    if (pago.estadoPago.toUpperCase() == 'PENDIENTE') return 'Pendiente de registro';
    return 'Sin registrar';
  }

  static String _textoDato(String? value, PagoConCitaResumen pago) {
    final text = value?.trim() ?? '';
    if (text.isNotEmpty && text != '-') return text;
    if (pago.estadoPago.toUpperCase() == 'PENDIENTE') return 'Pendiente de registro';
    return 'Sin registrar';
  }

  static Color _estadoColor(ThemeController theme, String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return theme.success;
      case 'ANULADO':
      case 'REEMPLAZADO':
        return theme.error;
      case 'PENDIENTE':
      default:
        return theme.warning;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, this.icon});
  final String label;
  final String value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: theme.grey),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: theme.grey, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value.trim().isEmpty ? '-' : value.trim())),
        ],
      ),
    );
  }
}

class _RegistroTile extends StatelessWidget {
  const _RegistroTile({required this.nombre, required this.avatarUrl});
  final String nombre;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundImage: _hasUrl ? NetworkImage(avatarUrl!.trim()) : null,
        child: _hasUrl ? null : Text(_initials(nombre)),
      ),
      title: Text(nombre.trim().isEmpty ? '-' : nombre.trim()),
      subtitle: const Text('Registrado por'),
    );
  }

  bool get _hasUrl => avatarUrl != null && avatarUrl!.trim().isNotEmpty;
}

class _CitaResumenCard extends StatelessWidget {
  const _CitaResumenCard({
    required this.pago,
    required this.onTapVerCita,
  });

  final PagoConCitaResumen pago;
  final VoidCallback? onTapVerCita;

  @override
  Widget build(BuildContext context) {
    return InicioCitaCompactTile(
      cita: pago.cita,
      onTap: () {
        Navigator.of(context).pop();
        onTapVerCita?.call();
      },
    );
  }
}

String _initials(String name) {
  final initials = name
      .split(' ')
      .where((s) => s.trim().isNotEmpty)
      .take(2)
      .map((e) => e[0])
      .join()
      .toUpperCase();
  return initials.isEmpty ? '?' : initials;
}
