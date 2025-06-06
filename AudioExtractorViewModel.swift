import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - App State
enum AppState: Equatable {
    case idle
    case validating
    case processing
    case done(URL)
    case error(String)
}

// MARK: - Audio Extractor ViewModel
@MainActor
class AudioExtractorViewModel: ObservableObject {
    @Published var appState: AppState = .idle
    @Published var isDragOver: Bool = false
    @Published var progress: Double = 0.0
    @Published var selectedFormat: AudioExportFormat = .m4a
    
    private let exporter = VideoAudioExporter()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to exporter progress
        exporter.$progress
            .assign(to: \.progress, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Drag & Drop Handling
    func handleDragTargeted(_ isTargeted: Bool) {
        print("🎯 [DEBUG] Drag targeted: \(isTargeted), current state: \(appState)")
        if case .idle = appState {
            isDragOver = isTargeted
            print("🎯 [DEBUG] Setting isDragOver to: \(isTargeted)")
        }
    }
    
    func handleDropItems(_ items: [URL]) -> Bool {
        print("📁 [DEBUG] Drop received with \(items.count) items")
        isDragOver = false
        
        guard let firstURL = items.first else {
            print("❌ [DEBUG] No items found in drop")
            appState = .error("No se encontró ningún archivo")
            return false
        }
        
        print("📁 [DEBUG] First URL: \(firstURL)")
        print("📁 [DEBUG] File exists: \(FileManager.default.fileExists(atPath: firstURL.path))")
        print("📁 [DEBUG] File extension: \(firstURL.pathExtension)")
        
        // Validate it's a video file
        guard exporter.validateVideoFile(at: firstURL) else {
            print("❌ [DEBUG] File validation failed for: \(firstURL)")
            appState = .error("El archivo seleccionado no es un video soportado")
            return false
        }
        
        print("✅ [DEBUG] File validation passed, starting processing...")
        Task {
            await processVideoFile(firstURL, needsSecurityAccess: false)
        }
        
        return true
    }
    
    // MARK: - File Selection
    func selectVideoFile() {
        print("🔍 [DEBUG] Opening file selection panel...")
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .quickTimeMovie, .mpeg4Movie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { 
                print("❌ [DEBUG] No URL selected from panel")
                return 
            }
            
            print("✅ [DEBUG] File selected from panel: \(url)")
            Task {
                await processVideoFile(url, needsSecurityAccess: true)
            }
        } else {
            print("🚫 [DEBUG] File selection cancelled")
        }
    }
    
    // MARK: - Video Processing
    private func processVideoFile(_ url: URL, needsSecurityAccess: Bool = true) async {
        print("🎬 [DEBUG] Starting to process video file: \(url)")
        print("🎬 [DEBUG] File path: \(url.path)")
        print("🎬 [DEBUG] Is file URL: \(url.isFileURL)")
        print("🎬 [DEBUG] Needs security access: \(needsSecurityAccess)")
        
        do {
            var hasSecurityAccess = false
            
            // Start security scoped access only if needed
            if needsSecurityAccess {
                print("🔐 [DEBUG] Attempting to start security scoped access...")
                hasSecurityAccess = url.startAccessingSecurityScopedResource()
                if hasSecurityAccess {
                    print("✅ [DEBUG] Security scoped access granted")
                } else {
                    print("⚠️ [DEBUG] Security scoped access failed, trying to continue anyway...")
                }
            } else {
                print("🔐 [DEBUG] Skipping security scoped access (drag & drop)")
            }
            
            defer { 
                if hasSecurityAccess {
                    print("🔐 [DEBUG] Stopping security scoped access")
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Validate file
            print("🔍 [DEBUG] Validating video file...")
            guard exporter.validateVideoFile(at: url) else {
                print("❌ [DEBUG] Video file validation failed")
                appState = .error("Formato de video no soportado")
                return
            }
            
            print("✅ [DEBUG] Video file validation passed")
            appState = .processing
            print("🎬 [DEBUG] State changed to processing")
            
            // Export audio
            print("🎵 [DEBUG] Starting audio export with format: \(selectedFormat)")
            let audioURL = try await exporter.exportAudio(from: url, format: selectedFormat)
            
            print("✅ [DEBUG] Audio export completed: \(audioURL)")
            appState = .done(audioURL)
            print("🎬 [DEBUG] State changed to done")
            
        } catch let error as ExportError {
            print("❌ [DEBUG] Export error: \(error)")
            appState = .error(error.localizedDescription ?? "Error desconocido")
        } catch {
            print("❌ [DEBUG] Unexpected error: \(error)")
            appState = .error("Error inesperado: \(error.localizedDescription)")
        }
    }
    
    // MARK: - State Management
    func resetToIdle() {
        appState = .idle
        progress = 0.0
        exporter.cancelExport()
    }
    
    func dismissError() {
        if case .error = appState {
            appState = .idle
        }
    }
    
    // MARK: - File Actions
    func saveAudioFile(_ sourceURL: URL) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: selectedFormat.rawValue)!]
        savePanel.nameFieldStringValue = sourceURL.lastPathComponent
        
        if savePanel.runModal() == .OK {
            guard let destinationURL = savePanel.url else { return }
            
            do {
                // Copy file to user selected location
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            } catch {
                appState = .error("Error al guardar archivo: \(error.localizedDescription)")
            }
        }
    }
    
    func shareAudioFile(_ url: URL) {
        let sharingService = NSSharingService(named: .sendViaAirDrop)
        sharingService?.perform(withItems: [url])
    }
    
    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
} 