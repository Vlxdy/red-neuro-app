import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/features/notificaciones/stores/notificaciones_store.dart';
import 'package:red_neuro_app/src/models/notificacion.dart';
import 'package:red_neuro_app/src/ui/common/badges/counter_badge.dart';
import 'package:red_neuro_app/src/ui/common/snackbar/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldMessengerState> notificacionesMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  late final ThemeController _theme;
  bool _initializada = false;

  @override
  void initState() {
    super.initState();
    _theme = ThemeController.instance;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_initializada) {
        _cargarInicial(context);
      }
    });
  }

  Future<void> _cargarInicial(BuildContext context) async {
    _initializada = true;
    final store = context.read<NotificacionesStore>();
    try {
      await store.inicializar(context);
    } catch (error) {
      _mostrarError(error);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final posicion = _scrollController.position;
    if (posicion.pixels >= posicion.maxScrollExtent - 200) {
      final store = context.read<NotificacionesStore>();
      if (!store.cargandoMas && !store.isLastPage) {
        store.cargarMas(context).catchError(_mostrarError);
      }
    }
  }

  Future<void> _refrescar() async {
    final store = context.read<NotificacionesStore>();
    try {
      await store.refrescar(context);
    } catch (error) {
      _mostrarError(error);
    }
  }

  void _mostrarError(Object error) {
    final mensaje = _resolverMensajeError(error);
    showSnackBar(
      notificacionesMessengerKey,
      mensaje,
      state: StatusSnackBar.error,
      colorText: _theme.white,
    );
  }

  String _resolverMensajeError(Object error) {
    if (error is ErrorDescription) {
      final descripcion = error.toString();
      return descripcion
          .replaceFirst('Error Summary: ', '')
          .replaceFirst('Error Description: ', '')
          .trim();
    }
    final texto = error.toString();
    if (texto.isNotEmpty && texto != 'Instance of Exception') {
      return texto;
    }
    return 'Ocurrió un error al procesar la solicitud.';
  }

  Future<void> _marcarComoVista(Notificacion notificacion) async {
    if (!mounted || notificacion.visto) return;
    final store = context.read<NotificacionesStore>();
    try {
      await store.marcarComoVistas(context, [notificacion.id]);
    } catch (error) {
      _mostrarError(error);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<NotificacionesStore>(
      builder: (context, store, _) {
        return ScaffoldMessenger(
          key: notificacionesMessengerKey,
          child: Scaffold(
            backgroundColor: _theme.background,
            appBar: AppBar(
              title: const Text('Notificaciones'),
              backgroundColor: _theme.background,
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CounterBadge(
                    count: store.totalNoVistas,
                    backgroundColor: _theme.primary,
                    borderColor: _theme.background,
                    child: const Icon(Icons.notifications_rounded),
                    offset: const Offset(-8, -8),
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _refrescar,
              color: _theme.primary,
              child: _buildContenido(store),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContenido(NotificacionesStore store) {
    if (store.cargando && store.notificaciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store.notificaciones.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Icon(Icons.notifications_none_rounded,
              size: 72, color: _theme.neutral.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            'No tienes notificaciones pendientes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _theme.neutral,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    final itemCount =
        store.notificaciones.length + (store.cargandoMas ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= store.notificaciones.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final notificacion = store.notificaciones[index];
        return _buildTarjetaNotificacion(notificacion);
      },
    );
  }

  Widget _buildTarjetaNotificacion(Notificacion notificacion) {
    final esNueva = !notificacion.visto;
    final fecha = DateFormat('dd/MM/yyyy HH:mm')
        .format(notificacion.fechaCreacion.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: esNueva
            ? _theme.primary.withOpacity(0.08)
            : _theme.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _marcarComoVista(notificacion),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notificacion.mensaje,
                        style: TextStyle(
                          fontWeight:
                              esNueva ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                          color: _theme.fontColor,
                        ),
                      ),
                    ),
                    if (esNueva)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _theme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  fecha,
                  style: TextStyle(
                    color: _theme.neutral,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
