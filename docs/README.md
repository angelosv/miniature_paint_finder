# Documentación de Miniature Paint Finder

Este directorio contiene la documentación para ayudar a los desarrolladores a configurar, ejecutar y mantener la aplicación Miniature Paint Finder.

## Contenido

- [Guía de Configuración](SETUP_GUIDE.md) - Instrucciones detalladas para configurar el entorno de desarrollo y solucionar problemas comunes.

## Herramientas Adicionales

Además de esta documentación, el proyecto incluye herramientas útiles para ayudarte en el desarrollo:

- [`/ios/fix_ios_build.sh`](../ios/fix_ios_build.sh) - Script interactivo para solucionar problemas comunes de construcción en iOS, especialmente en equipos con chips Apple Silicon (M1/M2/M3).

## Flujo de Trabajo Recomendado

1. Configura tu entorno siguiendo las instrucciones en la [Guía de Configuración](SETUP_GUIDE.md).
2. Si encuentras problemas con la construcción en iOS, ejecuta el script de solución de problemas: 
   ```bash
   cd ios
   ./fix_ios_build.sh
   ```
3. Para el desarrollo normal, usa los comandos estándar de Flutter:
   ```bash
   flutter pub get    # Para actualizar dependencias
   flutter run        # Para ejecutar la aplicación
   ```

## Contribuciones

Si encuentras problemas o tienes mejoras para la documentación o las herramientas, considera contribuir al proyecto abriendo un issue o un pull request. 