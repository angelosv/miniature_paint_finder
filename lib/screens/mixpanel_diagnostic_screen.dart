import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';

/// Pantalla para verificar la conexión con Mixpanel
class MixpanelDiagnosticScreen extends StatefulWidget {
  const MixpanelDiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<MixpanelDiagnosticScreen> createState() =>
      _MixpanelDiagnosticScreenState();
}

class _MixpanelDiagnosticScreenState extends State<MixpanelDiagnosticScreen> {
  final _logs = <String>[];
  bool _isRunning = false;
  bool? _diagnosticResult;
  final MixpanelService _mixpanel = MixpanelService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Diagnóstico de Mixpanel')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnóstico de Mixpanel',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text(
                  'Esta pantalla permite verificar la conexión con Mixpanel',
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _isRunning ? null : _runDiagnostics,
                      child: Text('Ejecutar Diagnóstico'),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isRunning ? null : _sendTestEvent,
                      child: Text('Enviar Evento de Prueba'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (_diagnosticResult != null)
                  Container(
                    padding: EdgeInsets.all(8),
                    color:
                        _diagnosticResult == true
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                    child: Row(
                      children: [
                        Icon(
                          _diagnosticResult == true
                              ? Icons.check_circle
                              : Icons.error,
                          color:
                              _diagnosticResult == true
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _diagnosticResult == true
                              ? 'Diagnóstico exitoso'
                              : 'Diagnóstico fallido',
                          style: TextStyle(
                            color:
                                _diagnosticResult == true
                                    ? Colors.green
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: Container(
              color: Colors.black,
              padding: EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color color = Colors.white;

                  if (log.contains('✅')) {
                    color = Colors.green;
                  } else if (log.contains('❌')) {
                    color = Colors.red;
                  } else if (log.contains('⚠️')) {
                    color = Colors.orange;
                  } else if (log.contains('🔍')) {
                    color = Colors.blue;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: color,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
      _diagnosticResult = null;
    });

    _addLog('🔍 Iniciando diagnóstico...');

    try {
      // Redefinir la función de log para capturar la salida
      final originalPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null && message.contains('Mixpanel')) {
          _addLog(message);
        }
        originalPrint(message, wrapWidth: wrapWidth);
      };

      // Ejecutar diagnóstico
      final result = await _mixpanel.runDiagnostics();

      // Restaurar la función de log original
      debugPrint = originalPrint;

      setState(() {
        _diagnosticResult = result;
        _isRunning = false;
      });

      _addLog(
        result
            ? '✅ Diagnóstico completado con éxito'
            : '❌ El diagnóstico ha fallado',
      );
    } catch (e) {
      _addLog('❌ Error durante el diagnóstico: $e');
      setState(() {
        _diagnosticResult = false;
        _isRunning = false;
      });
    }
  }

  Future<void> _sendTestEvent() async {
    setState(() {
      _isRunning = true;
      _logs.add('🔍 Enviando evento de prueba manual...');
    });

    try {
      await _mixpanel.trackEvent('Test_Manual_Event', {
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'diagnostic_screen',
        'manual_test': true,
      });

      _addLog('✅ Evento de prueba enviado correctamente');
    } catch (e) {
      _addLog('❌ Error al enviar evento de prueba: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
    });
  }
}
