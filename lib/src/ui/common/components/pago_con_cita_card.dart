import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/models/pago_con_cita_resumen.dart';
import 'package:red_neuro_app/src/ui/common/components/pago_con_cita_modal_sheet.dart';

class PagoConCitaCard extends StatelessWidget {
  const PagoConCitaCard({
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
    final cita = pago.cita;
    final estadoColor = _estadoColor(theme, pago.estadoPago);
    final registradoPor = _registradoPorLabel(pago);
    final fechaRegistro = _fechaRegistroLabel(dateTime, pago);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openBottomSheet(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                margin: const EdgeInsets.only(top: 2, bottom: 2),
                decoration: BoxDecoration(
                  color: estadoColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            money.format(pago.monto),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: estadoColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            pago.estadoPago.toUpperCase(),
                            style: TextStyle(
                              color: estadoColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _CampoConIcono(
                      icon: Icons.person_outline_rounded,
                      text: 'Registrado por: $registradoPor',
                    ),
                    const SizedBox(height: 3),
                    _CampoConIcono(
                      icon: Icons.schedule_rounded,
                      text: 'Fecha registro: $fechaRegistro',
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.bgCard2.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CampoConIcono(
                            icon: Icons.medical_services_outlined,
                            text: '${_tipoServicioLabel(cita.tipoCita)}: ${_safe(cita.servicioNombre)}',
                          ),
                          const SizedBox(height: 4),
                          _CampoConIcono(
                            icon: Icons.badge_outlined,
                            text: 'Personal asignado: ${_safe(pago.personalNombre)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _tipoServicioLabel(String? tipoCita) {
    if ((tipoCita ?? '').toUpperCase() == 'ESTUDIO') return 'Estudio';
    return 'Consulta';
  }

  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PagoConCitaModalSheet(
        pago: pago,
        onTapVerCita: onTapVerCita,
      ),
    );
  }

  static String _safe(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    return value.trim();
  }

  static String _registradoPorLabel(PagoConCitaResumen pago) {
    if (pago.usuarioRegistroNombre.trim().isNotEmpty && pago.usuarioRegistroNombre.trim() != '-') {
      return pago.usuarioRegistroNombre.trim();
    }
    if (pago.estadoPago.toUpperCase() == 'PENDIENTE') return 'Pendiente de registro';
    return 'Sin dato de registro';
  }

  static String _fechaRegistroLabel(DateFormat formatter, PagoConCitaResumen pago) {
    if (pago.fechaPago != null) return formatter.format(pago.fechaPago!.toLocal());
    if (pago.estadoPago.toUpperCase() == 'PENDIENTE') return 'Pendiente de registro';
    return 'Sin fecha registrada';
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

class _CampoConIcono extends StatelessWidget {
  const _CampoConIcono({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: ThemeController.instance.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
