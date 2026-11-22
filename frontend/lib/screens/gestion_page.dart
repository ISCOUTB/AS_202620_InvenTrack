import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/api_exception.dart';

enum Seccion {
  proveedores('Proveedores'),
  historial('Historial por producto'),
  cierres('Cierre de turno'),
  usuarios('Usuarios');

  const Seccion(this.titulo);
  final String titulo;
}

class GestionPage extends StatefulWidget {
  const GestionPage({super.key});

  @override
  State<GestionPage> createState() => _GestionPageState();
}

class _GestionPageState extends State<GestionPage> {
  late final ApiService api;
  final sku = TextEditingController();
  final csv = TextEditingController(text: 'sku,cantidad\n');
  Seccion seccion = Seccion.proveedores;
  String? rol;
  String? error;
  bool ocupado = false;
  bool busquedaRealizada = false;
  List<Map<String, dynamic>> filas = [];
  String? cierre;
  Map<String, dynamic>? informe;

  bool get administra => rol == 'admin' || rol == 'demo';

  @override
  void initState() {
    super.initState();
    api = context.read<ApiService>();
    ejecutar(iniciar);
  }

  Future<void> iniciar() async {
    rol = await api.rolActual();
    await cargar();
  }

  @override
  void dispose() {
    sku.dispose();
    csv.dispose();
    super.dispose();
  }

  Future<void> ejecutar(Future<void> Function() tarea) async {
    if (ocupado) return;
    setState(() {
      ocupado = true;
      error = null;
    });
    try {
      await tarea();
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'No se pudo completar la operación. Comprueba la conexión.');
      }
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> cargar() async {
    switch (seccion) {
      case Seccion.proveedores:
        filas = await api.proveedores();
      case Seccion.usuarios:
        filas = await api.usuarios();
      case Seccion.cierres:
        filas = await api.cierres();
      case Seccion.historial:
        if (sku.text.trim().isEmpty) return;
        filas = await api.historial(sku.text.trim());
        busquedaRealizada = true;
    }
  }

  void cambiarSeccion(Seccion? destino) {
    if (destino == null || destino == seccion) return;
    setState(() {
      seccion = destino;
      filas = [];
      busquedaRealizada = false;
      informe = null;
    });
    ejecutar(cargar);
  }

  Future<bool> confirmar(String pregunta) async =>
      await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text(pregunta),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Confirmar')),
                ],
              )) ??
      false;

  Future<void> editarProveedor([Map<String, dynamic>? actual]) async {
    final datos = await showDialog<(String, String)>(
        context: context,
        builder: (_) => _Formulario(
            nombre: actual?['nombre'] as String? ?? '',
            contacto: actual?['contacto'] as String? ?? ''));
    if (datos == null || !mounted) return;
    await ejecutar(() async {
      await api.guardarProveedor(datos.$1, datos.$2,
          id: actual?['id'] as String?);
      await cargar();
    });
  }

  Future<void> mostrarCredencial(String token) async {
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Credencial individual'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'Copia la credencial ahora para entregarla al usuario.'),
                const SizedBox(height: 12),
                SelectableText(token),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cerrar'))
              ],
            ));
  }

  Future<void> editarUsuario([Map<String, dynamic>? actual]) async {
    final datos = await showDialog<(String, String)>(
        context: context,
        builder: (_) => _Formulario(
            nombre: actual?['id'] as String? ?? '',
            rol: actual?['rol'] as String? ?? 'lector',
            bloquearNombre: actual != null));
    if (datos == null || !mounted) return;
    if (actual == null) {
      await emitirCredencial(() => api.crearUsuario(datos.$1, datos.$2));
      return;
    }
    await ejecutar(() async {
      await api.cambiarRol(datos.$1, datos.$2);
      await cargar();
    });
  }

  Future<void> emitirCredencial(Future<String> Function() emitir) async {
    String? token;
    await ejecutar(() async {
      token = await emitir();
    });
    if (token == null || !mounted) return;
    await mostrarCredencial(token!);
    if (mounted) await ejecutar(cargar);
  }

  Widget proveedores() => Column(children: [
        if (administra)
          FilledButton.icon(
              onPressed: () => editarProveedor(),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo proveedor')),
        if (filas.isEmpty && !ocupado)
          const Text('Sin proveedores registrados.'),
        for (final p in filas)
          ListTile(
            title: Text(p['nombre']),
            subtitle: Text(p['contacto']),
            onTap: administra ? () => editarProveedor(p) : null,
            trailing: administra
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar proveedor',
                    onPressed: () async {
                      if (await confirmar('¿Eliminar a ${p['nombre']}?') &&
                          mounted) {
                        await ejecutar(() async {
                          await api.eliminarProveedor(p['id']);
                          await cargar();
                        });
                      }
                    })
                : null,
          ),
      ]);

  Widget historial() => Column(children: [
        TextField(
            controller: sku,
            decoration: const InputDecoration(labelText: 'SKU del producto'),
            onChanged: (_) => setState(() {
                  filas = [];
                  busquedaRealizada = false;
                }),
            onSubmitted: (_) => ejecutar(cargar)),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: sku.text.trim().isEmpty ? null : () => ejecutar(cargar),
            child: const Text('Consultar historial')),
        if (busquedaRealizada && filas.isEmpty)
          const Text('Sin movimientos para este SKU.'),
        for (final m in filas)
          ListTile(
            title: Text('${m['tipo']} · ${m['cantidad']} unidades'),
            subtitle: Text(
                '${m['registrado_en']} · ${m['actor_id'] ?? 'Demostración'}'),
          ),
      ]);

  Widget usuarios() => Column(children: [
        FilledButton.icon(
            onPressed: () => editarUsuario(),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Crear usuario')),
        for (final u in filas)
          ListTile(
            title: Text(u['id']),
            subtitle: Text(u['rol']),
            trailing: PopupMenuButton<String>(
              onSelected: (accion) async {
                if (accion == 'Cambiar rol') {
                  await editarUsuario(u);
                  return;
                }
                if (!await confirmar('¿$accion de ${u['id']}?') || !mounted) {
                  return;
                }
                if (accion == 'Rotar credencial') {
                  await emitirCredencial(() => api.rotarUsuario(u['id']));
                  return;
                }
                await ejecutar(() async {
                  await api.revocarUsuario(u['id']);
                  await cargar();
                });
              },
              itemBuilder: (_) => const [
                'Cambiar rol',
                'Rotar credencial',
                'Revocar acceso'
              ].map((a) => PopupMenuItem(value: a, child: Text(a))).toList(),
            ),
          ),
      ]);

  Widget cierres() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (rol != 'lector')
          FilledButton.icon(
              icon: const Icon(Icons.inventory_outlined),
              label: const Text('Tomar corte de existencias'),
              onPressed: () => ejecutar(() async {
                    final nuevo = await api.abrirCierre();
                    cierre = nuevo['id'];
                    informe = null;
                    csv.text = 'sku,cantidad\n';
                    await cargar();
                  })),
        if (filas.isEmpty && !ocupado) const Text('Sin cortes registrados.'),
        if (filas.isNotEmpty)
          DropdownButton<String>(
              isExpanded: true,
              value: cierre,
              hint: const Text('Seleccionar corte'),
              items: filas
                  .map((c) => DropdownMenuItem<String>(
                      value: c['id'], child: Text(c['fecha'])))
                  .toList(),
              onChanged: (id) => setState(() {
                    cierre = id;
                    informe = null;
                    csv.text = 'sku,cantidad\n';
                  })),
        if (cierre != null && rol != 'lector') ...[
          TextField(
              controller: csv,
              minLines: 3,
              maxLines: 8,
              onChanged: (_) {
                if (informe != null) setState(() => informe = null);
              },
              decoration: const InputDecoration(
                  labelText: 'Conteo físico (CSV)',
                  helperText: 'Una fila por SKU con su cantidad.')),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: () => ejecutar(() async {
                    informe = null;
                    informe = await api.conciliar(cierre!, csv.text);
                  }),
              child: const Text('Comparar conteo')),
        ],
        if (informe case final r?) ...[
          const Divider(),
          Text(
              'Esperado: ${r['total_esperado']} · Contado: ${r['total_contado']}'),
          if ((r['diferencias'] as List).isEmpty)
            const Text('El conteo coincide con el corte.'),
          for (final d in r['diferencias'])
            ListTile(
                title: Text(d['sku']),
                subtitle: Text(switch (d['motivo']) {
                  'sin_conteo' => 'Falta contar este SKU',
                  'fuera_del_corte' => 'SKU fuera del corte',
                  _ =>
                    'Esperado: ${d['esperado']} · Contado: ${d['contado']} · Diferencia: ${d['diferencia']}',
                })),
        ],
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Gestión')),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(20), children: [
          if (ocupado) const LinearProgressIndicator(),
          if (error != null)
            Text(error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (rol == null && !ocupado)
            TextButton(
                onPressed: () => ejecutar(iniciar),
                child: const Text('Reintentar')),
          if (rol != null)
            IgnorePointer(
                ignoring: ocupado,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButton<Seccion>(
                        isExpanded: true,
                        value: seccion,
                        items: Seccion.values
                            .where(
                                (s) => s != Seccion.usuarios || rol == 'admin')
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text(s.titulo)))
                            .toList(),
                        onChanged: cambiarSeccion),
                    const SizedBox(height: 16),
                    switch (seccion) {
                      Seccion.proveedores => proveedores(),
                      Seccion.usuarios => usuarios(),
                      Seccion.historial => historial(),
                      Seccion.cierres => cierres(),
                    },
                  ],
                )),
        ])),
      );
}

class _Formulario extends StatefulWidget {
  const _Formulario(
      {required this.nombre,
      this.contacto = '',
      this.rol,
      this.bloquearNombre = false});
  final String nombre;
  final String contacto;
  final String? rol;
  final bool bloquearNombre;
  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  late String nombre = widget.nombre;
  late String contacto = widget.contacto;
  late String? rol = widget.rol;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(rol == null ? 'Datos del proveedor' : 'Datos del usuario'),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
              initialValue: nombre,
              enabled: !widget.bloquearNombre,
              decoration: InputDecoration(
                  labelText: rol == null ? 'Nombre' : 'Identificador'),
              onChanged: (v) => setState(() => nombre = v)),
          if (rol == null)
            TextFormField(
                initialValue: contacto,
                decoration: const InputDecoration(labelText: 'Contacto'),
                onChanged: (v) => contacto = v)
          else
            DropdownButton<String>(
                value: rol,
                isExpanded: true,
                items: const ['lector', 'operador', 'admin']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => rol = v)),
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: nombre.trim().isEmpty
                  ? null
                  : () => Navigator.pop(
                      context, (nombre.trim(), rol ?? contacto.trim())),
              child: const Text('Guardar')),
        ],
      );
}
