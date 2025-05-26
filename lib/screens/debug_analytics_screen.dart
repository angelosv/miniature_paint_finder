import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/services/auth_analytics_service.dart';

class DebugAnalyticsScreen extends StatefulWidget {
  const DebugAnalyticsScreen({Key? key}) : super(key: key);

  @override
  _DebugAnalyticsScreenState createState() => _DebugAnalyticsScreenState();
}

class _DebugAnalyticsScreenState extends State<DebugAnalyticsScreen> {
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _debugInfo;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mixpanelService = Provider.of<MixpanelService>(
        context,
        listen: false,
      );
      final stats = await mixpanelService.getUserIdentificationStats();
      final debug = await mixpanelService.debugUserIdentification();

      setState(() {
        _userStats = stats;
        _debugInfo = debug;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading stats: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _forceReidentification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Forzando re-identificación...';
    });

    try {
      final authService = Provider.of<IAuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        final mixpanelService = Provider.of<MixpanelService>(
          context,
          listen: false,
        );
        await mixpanelService.forceUserReidentification(
          currentUser.id,
          name: currentUser.name,
          email: currentUser.email,
          phoneNumber: currentUser.phoneNumber,
          authProvider: currentUser.authProvider,
          additionalProperties: {'debug_screen_reidentification': true},
        );

        setState(() {
          _statusMessage = 'Re-identificación completada exitosamente';
        });

        // Recargar estadísticas
        await _loadUserStats();
      } else {
        setState(() {
          _statusMessage = 'No hay usuario autenticado';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error en re-identificación: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestEvent() async {
    setState(() {
      _statusMessage = 'Enviando evento de prueba...';
    });

    try {
      final mixpanelService = Provider.of<MixpanelService>(
        context,
        listen: false,
      );
      await mixpanelService.trackEvent('Debug_Test_Event', {
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'debug_screen',
        'test_id': DateTime.now().millisecondsSinceEpoch,
      });

      setState(() {
        _statusMessage = 'Evento de prueba enviado exitosamente';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error enviando evento: $e';
      });
    }
  }

  Future<void> _verifyTracking() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Verificando tracking...';
    });

    try {
      final mixpanelService = Provider.of<MixpanelService>(
        context,
        listen: false,
      );
      final isWorking = await mixpanelService.verifyUserTracking();

      setState(() {
        _statusMessage =
            isWorking
                ? 'Tracking funcionando correctamente ✅'
                : 'Problemas detectados en tracking ❌';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error verificando tracking: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copiado al portapapeles')));
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<IAuthService>(context);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Mixpanel Analytics'),
        backgroundColor: Colors.deepPurple,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estado del usuario actual
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Usuario Actual',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            SizedBox(height: 8),
                            if (currentUser != null) ...[
                              Text('ID: ${currentUser.id}'),
                              Text('Nombre: ${currentUser.name}'),
                              Text('Email: ${currentUser.email}'),
                              Text(
                                'Teléfono: ${currentUser.phoneNumber ?? 'N/A'}',
                              ),
                              Text('Proveedor: ${currentUser.authProvider}'),
                              Text('Creado: ${currentUser.createdAt}'),
                              Text(
                                'Último login: ${currentUser.lastLoginAt ?? 'N/A'}',
                              ),
                            ] else ...[
                              Text('No hay usuario autenticado'),
                            ],
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Información de debug de Mixpanel
                    if (_debugInfo != null)
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Estado de Mixpanel',
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                  ),
                                  Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.copy),
                                    onPressed:
                                        () => _copyToClipboard(
                                          _debugInfo.toString(),
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              ..._debugInfo!.entries.map(
                                (entry) => Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  child: Text('${entry.key}: ${entry.value}'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 16),

                    // Estadísticas de identificación
                    if (_userStats != null)
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estadísticas de Identificación',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              SizedBox(height: 8),
                              ..._userStats!.entries.map(
                                (entry) => Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  child: Text('${entry.key}: ${entry.value}'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 16),

                    // Mensaje de estado
                    if (_statusMessage.isNotEmpty)
                      Card(
                        color:
                            _statusMessage.contains('Error') ||
                                    _statusMessage.contains('❌')
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color:
                                  _statusMessage.contains('Error') ||
                                          _statusMessage.contains('❌')
                                      ? Colors.red.shade800
                                      : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: 16),

                    // Botones de acción
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _loadUserStats,
                          child: Text('Recargar Stats'),
                        ),
                        ElevatedButton(
                          onPressed:
                              currentUser != null
                                  ? _forceReidentification
                                  : null,
                          child: Text('Forzar Re-identificación'),
                        ),
                        ElevatedButton(
                          onPressed: _sendTestEvent,
                          child: Text('Enviar Evento Test'),
                        ),
                        ElevatedButton(
                          onPressed: _verifyTracking,
                          child: Text('Verificar Tracking'),
                        ),
                      ],
                    ),

                    SizedBox(height: 32),

                    // Instrucciones
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instrucciones de Debug',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '1. Verificar que el usuario esté autenticado',
                            ),
                            Text(
                              '2. Revisar el estado de Mixpanel (debe estar "initialized")',
                            ),
                            Text('3. Verificar que distinct_id no sea null'),
                            Text(
                              '4. Usar "Forzar Re-identificación" si hay problemas',
                            ),
                            Text(
                              '5. Enviar eventos de prueba para verificar funcionamiento',
                            ),
                            Text(
                              '6. Revisar logs de la consola para más detalles',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
