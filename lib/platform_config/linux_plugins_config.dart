// Este archivo se utiliza para manejar la configuración de plugins específicos de Linux
// Importado desde main.dart para desactivar plugins que no son compatibles con Linux.

import 'package:flutter/foundation.dart';

// Esta función se llama en main.dart para configurar los plugins en Linux
void configureLinuxPlugins() {
  if (defaultTargetPlatform == TargetPlatform.linux) {
    // Actualmente no se requiere ninguna configuración específica para Linux,
    // pero este archivo existe para manejar problemas de compatibilidad
    // con flutter_local_notifications que no tiene soporte para Linux.
  }
}
