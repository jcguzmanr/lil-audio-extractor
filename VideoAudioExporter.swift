import Foundation
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Export Errors
enum ExportError: LocalizedError {
    case noAudioTrack
    case unsupportedFormat
    case exportFailed(String)
    case insufficientSpace
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .noAudioTrack:
            return "El video no contiene pista de audio"
        case .unsupportedFormat:
            return "Formato de video no soportado"
        case .exportFailed(let message):
            return "Error al exportar: \(message)"
        case .insufficientSpace:
            return "Espacio insuficiente en disco"
        case .permissionDenied:
            return "Permisos insuficientes para acceder al archivo"
        }
    }
}

// MARK: - Export Format
enum AudioExportFormat: String, CaseIterable {
    case m4a = "m4a"
    case wav = "wav"
    case mp3 = "mp3"
    
    var fileType: AVFileType {
        switch self {
        case .m4a:
            return .m4a
        case .wav:
            return .wav
        case .mp3:
            return .mp3
        }
    }
    
    var preset: String {
        switch self {
        case .m4a:
            return AVAssetExportPresetAppleM4A
        case .wav:
            return AVAssetExportPresetPassthrough
        case .mp3:
            return AVAssetExportPresetAppleM4A // Will be converted to MP3 format
        }
    }
}

// MARK: - Video Audio Exporter
@MainActor
class VideoAudioExporter: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var isExporting: Bool = false
    
    private var currentExportSession: AVAssetExportSession?
    private var progressTimer: Timer?
    
    // MARK: - File Validation
    func validateVideoFile(at url: URL) -> Bool {
        print("🔍 [DEBUG] Validating file: \(url.lastPathComponent)")
        print("🔍 [DEBUG] File extension: \(url.pathExtension)")
        
        let supportedTypes: [UTType] = [
            .quickTimeMovie,
            .mpeg4Movie,
            .avi,
            .movie
        ]
        
        guard let contentType = UTType(filenameExtension: url.pathExtension) else {
            print("❌ [DEBUG] Could not determine content type for extension: \(url.pathExtension)")
            return false
        }
        
        print("🔍 [DEBUG] Content type: \(contentType)")
        
        let isSupported = supportedTypes.contains { supportedType in
            let conforms = contentType.conforms(to: supportedType)
            print("🔍 [DEBUG] Checking if \(contentType) conforms to \(supportedType): \(conforms)")
            return conforms
        }
        
        print("🔍 [DEBUG] File validation result: \(isSupported)")
        return isSupported
    }
    
    // MARK: - Audio Export
    func exportAudio(from videoURL: URL, format: AudioExportFormat = .m4a) async throws -> URL {
        print("🎵 [DEBUG] Starting audio export from: \(videoURL)")
        print("🎵 [DEBUG] Target format: \(format)")
        
        guard validateVideoFile(at: videoURL) else {
            print("❌ [DEBUG] Video file validation failed in export")
            throw ExportError.unsupportedFormat
        }
        
        print("🎵 [DEBUG] Creating AVURLAsset...")
        let asset = AVURLAsset(url: videoURL)
        
        // Check for audio track
        print("🎵 [DEBUG] Loading audio tracks...")
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        print("🎵 [DEBUG] Found \(audioTracks.count) audio tracks")
        
        guard !audioTracks.isEmpty else {
            print("❌ [DEBUG] No audio tracks found")
            throw ExportError.noAudioTrack
        }
        
        // Generate output URL
        print("🎵 [DEBUG] Generating output URL...")
        let outputURL = generateOutputURL(for: videoURL, format: format)
        print("🎵 [DEBUG] Output URL: \(outputURL)")
        
        // Remove existing file if it exists
        print("🎵 [DEBUG] Removing existing file if it exists...")
        try? FileManager.default.removeItem(at: outputURL)
        
        // Create export session
        print("🎵 [DEBUG] Creating export session with preset: \(format.preset)")
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: format.preset) else {
            print("❌ [DEBUG] Failed to create export session")
            throw ExportError.exportFailed("No se pudo crear la sesión de exportación")
        }
        
        print("🎵 [DEBUG] Configuring export session...")
        exportSession.outputFileType = format.fileType
        exportSession.outputURL = outputURL
        
        // Configure for audio only
        exportSession.audioMix = nil
        exportSession.videoComposition = nil
        
        print("🎵 [DEBUG] Setting up progress monitoring...")
        self.currentExportSession = exportSession
        self.isExporting = true
        self.progress = 0.0
        
        // Start progress monitoring
        startProgressMonitoring()
        
        do {
            print("🎵 [DEBUG] Starting export...")
            try await exportSession.export()
            
            print("🎵 [DEBUG] Export completed, stopping progress monitoring...")
            stopProgressMonitoring()
            self.isExporting = false
            self.progress = 1.0
            
            print("🎵 [DEBUG] Export session status: \(exportSession.status.rawValue)")
            switch exportSession.status {
            case .completed:
                print("✅ [DEBUG] Export completed successfully")
                return outputURL
            case .failed:
                print("❌ [DEBUG] Export failed")
                if let error = exportSession.error {
                    print("❌ [DEBUG] Export error: \(error)")
                    throw ExportError.exportFailed(error.localizedDescription)
                } else {
                    print("❌ [DEBUG] Export failed with unknown error")
                    throw ExportError.exportFailed("Error desconocido")
                }
            case .cancelled:
                print("🚫 [DEBUG] Export was cancelled")
                throw ExportError.exportFailed("Exportación cancelada")
            default:
                print("❌ [DEBUG] Unexpected export status: \(exportSession.status)")
                throw ExportError.exportFailed("Estado de exportación inesperado")
            }
        } catch {
            print("❌ [DEBUG] Exception during export: \(error)")
            stopProgressMonitoring()
            self.isExporting = false
            self.progress = 0.0
            throw error
        }
    }
    
    // MARK: - Progress Monitoring
    private func startProgressMonitoring() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }
    
    private func stopProgressMonitoring() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        guard let exportSession = currentExportSession else { return }
        progress = Double(exportSession.progress)
    }
    
    // MARK: - Utility Methods
    private func generateOutputURL(for inputURL: URL, format: AudioExportFormat) -> URL {
        let fileName = inputURL.deletingPathExtension().lastPathComponent
        let outputFileName = "\(fileName)_audio.\(format.rawValue)"
        
        let tempDirectory = FileManager.default.temporaryDirectory
        return tempDirectory.appendingPathComponent(outputFileName)
    }
    
    func cancelExport() {
        currentExportSession?.cancelExport()
        stopProgressMonitoring()
        isExporting = false
        progress = 0.0
    }
} 