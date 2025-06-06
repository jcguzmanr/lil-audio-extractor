# 🎵 Video → Audio Extractor

Una aplicación para macOS 14+ que permite arrastrar un archivo de video, extraer su pista de audio y entregar al usuario el archivo resultante listo para ser reutilizado.

## ✨ Características

- **Drag & Drop** simple desde Finder o cualquier aplicación
- **Formatos soportados**: MP4, MOV, M4V, AVI y más (cualquier formato compatible con AVFoundation)
- **Múltiples formatos de salida**: M4A (por defecto), WAV, MP3
- **Interfaz nativa de macOS** con SwiftUI
- **Progreso en tiempo real** durante la exportación
- **Compartir y guardar** con integración nativa del sistema
- **Accesibilidad completa** con soporte VoiceOver

## 🖥️ Capturas de Pantalla

### Estado Inicial
Zona de drag & drop con instrucciones claras y botón de selección de archivo.

### Procesando
Animación de progreso con indicador porcentual y opción de cancelar.

### Resultado
Archivo de audio listo para arrastrar al Finder o compartir directamente.

## 🎯 Casos de Uso

- **Creadores de contenido**: Extraer audio de videos para podcasts o música
- **Editores**: Separar pistas de audio para edición
- **Estudiantes**: Convertir conferencias en video a audio para escuchar offline
- **Músicos**: Extraer audio de videos musicales para análisis

## 🛠️ Arquitectura Técnica

### Capas de la Aplicación
- **UI (SwiftUI)**: Vista única con 4 estados distintos
- **ViewModel (Combine/async-await)**: Gestión de estado y progreso
- **Service Layer**: `VideoAudioExporter` con AVFoundation
- **Persistence**: Archivos temporales con opción de guardado

### Estados de la Aplicación
1. **Idle**: Pantalla de inicio con zona de drop
2. **Validating**: Verificación del archivo arrastrado
3. **Processing**: Extracción con progreso visual
4. **Done/Error**: Resultado final o manejo de errores

## ⚙️ Requisitos

- **macOS 14.0+** (Sonoma)
- **Xcode 15.0+** para desarrollo
- **Permisos de sandbox** configurados para acceso a archivos

## 🚀 Instalación

### Para Usuarios
1. Descargar la última release desde [Releases](../../releases)
2. Arrastrar la app a la carpeta Aplicaciones
3. Hacer clic derecho y "Abrir" la primera vez (notarización requerida)

### Para Desarrolladores
1. Clonar el repositorio:
```bash
git clone https://github.com/jcguzmanr/lil-audio-extractor.git
cd lil-audio-extractor
```

2. Abrir `lil-audio-extractor.xcodeproj` en Xcode

3. Configurar tu Developer Team en Project Settings

4. Compilar y ejecutar (⌘R)

## 📖 Uso

### Método 1: Drag & Drop
1. Arrastra un archivo de video desde Finder
2. Espera a que se complete la extracción
3. Arrastra el archivo de audio resultante donde lo necesites

### Método 2: Selección Manual
1. Haz clic en "Seleccionar archivo"
2. Elige tu video en el explorador
3. El proceso continúa automáticamente

### Opciones Avanzadas
- **Formato de salida**: Cambia entre M4A, WAV, MP3 en la parte inferior
- **Cancelación**: Presiona "Cancelar" durante el procesamiento
- **Compartir**: Usa AirDrop o Mail directamente desde la app

## 🔧 Desarrollo

### Estructura del Proyecto
```
lil-audio-extractor/
├── ContentView.swift              # UI principal con estados
├── AudioExtractorViewModel.swift  # Lógica de negocio
├── VideoAudioExporter.swift       # Servicio de exportación
├── Assets.xcassets/              # Recursos visuales
├── Localizable.strings           # Textos localizados
└── lil_audio_extractor.entitlements # Permisos de sandbox
```

### Puntos Clave de Implementación
- **AVFoundation**: `AVAssetExportSession` para extracción de audio
- **Security**: Manejo diferenciado de security-scoped resources
- **UI States**: Máquina de estados limpia con `AppState` enum
- **Progress**: Monitoreo en tiempo real con Timer y Combine

### Testing
- Unit tests para `VideoAudioExporter`
- UI tests para drag & drop
- Videos de prueba en TestAssets/ (< 1MB)

## 🚀 Roadmap Futuro

### **Fase 1: Mejora de Calidad de Audio** 🎧
- **Procesamiento de audio inteligente**: Algoritmos para mejorar la claridad de la voz
- **Reducción de ruido**: Eliminar ruido de fondo automáticamente
- **Normalización de volumen**: Niveles de audio consistentes
- **Filtros de frecuencia**: Optimización para diferentes tipos de contenido (voz, música, etc.)

### **Fase 2: Optimización de Contenido** ✂️
- **Eliminación de filler words**: Detección y remoción automática de "um", "ah", "este", etc.
- **Detección de silencios**: Recorte inteligente de pausas largas y espacios sin sonido
- **Segmentación automática**: División en capítulos o secciones basada en el contenido
- **Compresión inteligente**: Reducir duración manteniendo información relevante

### **Fase 3: MVP 2.0 - Transcripción con AI** 🤖
- **Integración con AI**: Implementación de modelos de speech-to-text de última generación
- **Transcripción automática**: Conversión completa de audio a texto
- **Detección de idiomas**: Soporte multiidioma automático
- **Formateo inteligente**: Párrafos, puntuación y estructura automática
- **Exportación de transcripciones**: Múltiples formatos (TXT, MD, DOCX, SRT)
- **Sincronización temporal**: Timestamps para cada segmento de texto

### **Futuro Lejano: Características Avanzadas** 🔮
- **Análisis de sentimientos**: Detección del tono emocional del contenido
- **Resúmenes automáticos**: Generación de abstracts del contenido
- **Traducciones**: Transcripción multiidioma
- **Exportación podcast-ready**: Optimización automática para distribución

## 📄 Licencia

[MIT License](LICENSE) - Siéntete libre de usar y modificar.

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-caracteristica`)
3. Commit tus cambios (`git commit -m 'Agrega nueva característica'`)
4. Push a la rama (`git push origin feature/nueva-caracteristica`)
5. Abre un Pull Request

## ⚠️ Limitaciones Conocidas

- Requiere archivos con pistas de audio (no funciona con videos sin audio)
- Formatos de entrada limitados a los soportados por AVFoundation
- Archivos muy grandes pueden requerir tiempo considerable de procesamiento

## 📞 Soporte

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Email**: Para consultas privadas

---

**Desarrollado con ❤️ usando SwiftUI y AVFoundation**

*Última actualización: Junio 2025* 