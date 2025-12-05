import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:flutter/material.dart';

class CriterioOrdenType {
  final String nombre;
  final String? orden;
  final bool ordenar;

  CriterioOrdenType({
    required this.nombre,
    this.orden,
    this.ordenar = false,
  });
}

class CustomDesktopDataTable extends StatefulWidget {
  final String? titulo;
  final String? descripcion;
  final Widget? tituloPersonalizado;
  final Widget? cabeceraPersonalizada;
  final double? columnSpacing;
  final bool error;
  final bool cargando;
  final List<Widget> acciones;
  final List<CriterioOrdenType> columnas;
  final Function(List<CriterioOrdenType>)? cambioOrdenCriterios;
  final Widget? filtros;
  final List<List<Widget>> contenidoTabla;
  final Widget? paginacion;
  final bool? seleccionable;
  final Function(List<int>)? seleccionados;
  final List<dynamic>? datos;
  final bool condensed;

  const CustomDesktopDataTable({
    super.key,
    this.titulo,
    this.descripcion,
    this.tituloPersonalizado,
    this.cabeceraPersonalizada,
    this.error = false,
    this.cargando = false,
    this.acciones = const [],
    required this.columnas,
    this.cambioOrdenCriterios,
    this.filtros,
    required this.contenidoTabla,
    this.paginacion,
    this.seleccionable,
    this.seleccionados,
    this.datos,
    this.condensed = false,
    this.columnSpacing = 30.0,
  });

  @override
  CustomDesktopDataTableState createState() => CustomDesktopDataTableState();
}

class CustomDesktopDataTableState extends State<CustomDesktopDataTable> {
  bool todoSeleccionado = false;
  List<bool> indicesSeleccionados = [];

  @override
  void initState() {
    super.initState();
    _initializeSelections();
  }

  void _initializeSelections() {
    indicesSeleccionados = List.generate(
      widget.contenidoTabla.length,
      (index) => false,
    );
  }

  void _handleSelectAll(bool? value) {
    setState(() {
      todoSeleccionado = value ?? false;
      indicesSeleccionados = List.generate(
        widget.contenidoTabla.length,
        (index) => todoSeleccionado,
      );
      _notifySelectedIndices();
    });
  }

  void _handleSelectItem(bool? value, int index) {
    setState(() {
      indicesSeleccionados[index] = value ?? false;
      _checkIfAllSelected();
      _notifySelectedIndices();
    });
  }

  void _checkIfAllSelected() {
    todoSeleccionado = indicesSeleccionados.every((element) => element);
  }

  void _notifySelectedIndices() {
    if (widget.seleccionados != null) {
      final selectedIndices = indicesSeleccionados
          .asMap()
          .entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      widget.seleccionados!(selectedIndices);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.error) {
      return _buildErrorView();
    }

    if (widget.contenidoTabla.isEmpty && !widget.cargando) {
      return _buildEmptyView();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (widget.filtros != null) _buildFilters(),
          _buildTable(),
          if (widget.paginacion != null) widget.paginacion!,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (widget.cabeceraPersonalizada != null) {
      return widget.cabeceraPersonalizada!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.titulo != null) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.titulo!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (widget.descripcion != null)
                Text(
                  widget.descripcion!,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ] else if (widget.tituloPersonalizado != null)
          widget.tituloPersonalizado!,
        Row(
          children: [
            ...widget.acciones,
          ],
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: widget.filtros!,
    );
  }

  Widget _buildTable() {
    final theme = ThemeController.instance;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Theme(
        data: Theme.of(context).copyWith(
          dataTableTheme: DataTableThemeData(
            decoration: BoxDecoration(color: theme.background),
          ),
        ),
        child: DataTable(
          columns: _buildColumns(),
          rows: _buildRows(),
          columnSpacing: widget.columnSpacing,
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    final columns = <DataColumn>[];

    if (widget.seleccionable == true) {
      columns.add(
        DataColumn(
          label: Checkbox(
            value: todoSeleccionado,
            onChanged: _handleSelectAll,
          ),
        ),
      );
    }

    columns.addAll(
      widget.columnas.map(
        (columna) => DataColumn(
          label: Text(
            columna.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );

    return columns;
  }

  List<DataRow> _buildRows() {
    final theme = ThemeController.instance;

    return List.generate(
      widget.contenidoTabla.length,
      (rowIndex) {
        final cells = <DataCell>[];

        if (widget.seleccionable == true) {
          cells.add(
            DataCell(
              Checkbox(
                value: indicesSeleccionados[rowIndex],
                onChanged: (value) => _handleSelectItem(value, rowIndex),
              ),
            ),
          );
        }

        cells.addAll(
          widget.contenidoTabla[rowIndex].map(
            (cellContent) => DataCell(cellContent),
          ),
        );

        return DataRow(
          cells: cells,
          color: WidgetStateProperty.all(theme.primary20),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return const Center(
      child: Text('Error obteniendo información'),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Text('Sin registros'),
    );
  }
}
