import 'package:flutter/material.dart'; 
import 'package:intl/intl.dart'; 
import '../db/database_helper.dart'; 
import '../models/pago.dart'; 
 
class NuevoPagoDialog extends StatefulWidget { 
  final int alumnoId; 
  final int cursoId; 
 
  const NuevoPagoDialog({ 
    super.key, 
    required this.alumnoId, 
    required this.cursoId, 
  }); 
 
  @override 
  State<NuevoPagoDialog> createState() => _NuevoPagoDialogState(); 
} 
 
class _NuevoPagoDialogState extends State<NuevoPagoDialog> { 
  final _formKey = GlobalKey<FormState>(); 
  late TextEditingController _dateCtrl; 
  late TextEditingController _amountCtrl; 
  String _metodo = 'EFECTIVO'; 
  bool _pagado = true; 
 
  @override 
  void initState() { 
    super.initState(); 
    _dateCtrl = TextEditingController( 
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()), 
    ); 
    _amountCtrl = TextEditingController(); 
  } 
 
  @override 
  void dispose() { 
    _dateCtrl.dispose(); 
    _amountCtrl.dispose(); 
    super.dispose(); 
  } 
 
  Future<void> _selectDate() async { 
    final picked = await showDatePicker( 
      context: context, 
      initialDate: DateTime.now(), 
      firstDate: DateTime(2000), 
      lastDate: DateTime(2100), 
    ); 
    if (picked != null) { 
      setState(() { 
        _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked); 
      }); 
    } 
  } 
 
  Future<void> _savePago() async { 
    if (!_formKey.currentState!.validate()) return; 
 
    try { 
      final cantidad = double.parse(_amountCtrl.text.replaceAll(',', '.')); 
 
      await DatabaseHelper.instance.insertPago( 
        Pago( 
          idAlumno: widget.alumnoId, 
          idCurso: widget.cursoId, 
          fecha: _dateCtrl.text, 
          cantidad: cantidad, 
          metodo: _metodo, 
          pagado: _pagado ? 1 : 0, 
        ), 
      ); 
 
      if (mounted) { 
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar( 
          const SnackBar(content: Text('Pago registrado')), 
        ); 
      } 
    } catch (e) { 
      if (mounted) { 
        Navigator.pop(context, false); 
        ScaffoldMessenger.of(context).showSnackBar( 
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red), 
        ); 
      } 
    } 
  } 
 
  @override 
  Widget build(BuildContext context) { 
    return AlertDialog( 
      title: const Text('Nuevo Pago'), 
      content: SingleChildScrollView( 
        child: Form( 
          key: _formKey, 
          child: Column( 
            mainAxisSize: MainAxisSize.min, 
            children: [ 
              TextFormField( 
                controller: _dateCtrl, 
                decoration: const InputDecoration( 
                  labelText: 'Fecha (YYYY-MM-DD)', 
                  suffixIcon: Icon(Icons.calendar_today), 
                ), 
                readOnly: true, 
                onTap: _selectDate, 
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null, 
              ), 
              TextFormField( 
                controller: _amountCtrl, 
                decoration: const InputDecoration(labelText: 'Cantidad (€)'), 
                keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                validator: (v) { 
                  if (v == null || v.isEmpty) return 'Requerido'; 
                  final d = double.tryParse(v.replaceAll(',', '.')); 
                  if (d == null || d <= 0) return 'Cantidad mayor a 0'; 
                  return null; 
                }, 
              ), 
              DropdownButtonFormField<String>( 
                value: _metodo, 
                decoration: const InputDecoration(labelText: 'Método'), 
                items: const ['EFECTIVO', 'TARJETA', 'BIZUM'] 
                    .map((m) => DropdownMenuItem(value: m, child: Text(m))) 
                    .toList(), 
                onChanged: (v) { 
                  if (v == null) return; 
                  setState(() => _metodo = v); 
                }, 
              ), 
              SwitchListTile( 
                title: const Text('¿Pagado?'), 
                value: _pagado, 
                onChanged: (v) => setState(() => _pagado = v), 
              ), 
            ], 
          ), 
        ), 
      ), 
      actions: [ 
        TextButton( 
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancelar'), 
        ), 
        ElevatedButton( 
          onPressed: _savePago, 
          child: const Text('Guardar'), 
        ), 
      ], 
    ); 
  } 
} 
