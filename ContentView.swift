//
//  ContentView.swift
//  lil-audio-extractor
//
//  Created by jcguzmanr on 6/6/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = AudioExtractorViewModel()
    @State private var showingFormatPicker = false
    
    var body: some View {
        ZStack {
            // Background
            Color(.controlBackgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Main Content Area
                mainContentArea
                    .frame(maxWidth: 600, maxHeight: 400)
                
                // Footer Controls
                footerControls
            }
            .padding(30)
            
            // Error Banner
            if case .error(let message) = viewModel.appState {
                errorBanner(message: message)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .dropDestination(for: URL.self) { items, location in
            viewModel.handleDropItems(items)
        } isTargeted: { isTargeted in
            viewModel.handleDragTargeted(isTargeted)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
            
            Text("Video → Audio Extractor")
                .font(.largeTitle)
                .fontWeight(.semibold)
        }
    }
    
    // MARK: - Main Content Area
    private var mainContentArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: borderWidth)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isDragOver)
                )
            
            switch viewModel.appState {
            case .idle:
                idleStateView
            case .validating:
                validatingStateView
            case .processing:
                processingStateView
            case .done(let audioURL):
                doneStateView(audioURL: audioURL)
            case .error:
                idleStateView // Show idle state, error is handled by banner
            }
        }
    }
    
    // MARK: - State Views
    private var idleStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "video.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("Arrastra un video aquí")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("o")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button("Seleccionar archivo") {
                    viewModel.selectVideoFile()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Text("Formatos soportados: MP4, MOV, M4V, AVI")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibility(label: Text("Zona de arrastre para archivos de video"))
    }
    
    private var validatingStateView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accent))
                .scaleEffect(1.5)
            
            Text("Validando archivo...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .accessibility(label: Text("Validando archivo de video"))
    }
    
    private var processingStateView: some View {
        VStack(spacing: 24) {
            // Animated waveform icon
            Image(systemName: "waveform.circle")
                .font(.system(size: 60))
                .foregroundStyle(.accent)
                .rotationEffect(.degrees(viewModel.progress * 360))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: viewModel.progress)
            
            VStack(spacing: 12) {
                Text("Extrayendo audio...")
                    .font(.headline)
                
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accent))
                    .frame(maxWidth: 300)
                
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            Button("Cancelar") {
                viewModel.resetToIdle()
            }
            .buttonStyle(.bordered)
        }
        .accessibility(label: Text("Procesando audio, \(Int(viewModel.progress * 100)) por ciento completado"))
    }
    
    private func doneStateView(audioURL: URL) -> some View {
        VStack(spacing: 24) {
            // Audio file icon
            VStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
                
                VStack(spacing: 4) {
                    Text(audioURL.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("Archivo de audio extraído")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("Arrastra el archivo al Finder para guardarlo")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Action buttons
            HStack(spacing: 16) {
                Button("Guardar Como...") {
                    viewModel.saveAudioFile(audioURL)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Mostrar en Finder") {
                    viewModel.revealInFinder(audioURL)
                }
                .buttonStyle(.bordered)
                
                Button("Compartir") {
                    viewModel.shareAudioFile(audioURL)
                }
                .buttonStyle(.bordered)
            }
            
            Button("Empezar de Nuevo") {
                viewModel.resetToIdle()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .onDrag {
            NSItemProvider(object: audioURL as NSURL)
        }
        .accessibility(label: Text("Audio extraído exitosamente: \(audioURL.lastPathComponent)"))
    }
    
    // MARK: - Footer Controls
    private var footerControls: some View {
        HStack {
            // Format selector
            HStack(spacing: 8) {
                Text("Formato:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Formato de audio", selection: $viewModel.selectedFormat) {
                    ForEach(AudioExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue.uppercased())
                            .tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            Toggle("Normalizar Volumen", isOn: $viewModel.normalizeVolume)
                .toggleStyle(.switch)
                .font(.subheadline)
                .padding(.leading, 20)

            Spacer()
            
            // Version info
            Text("v1.0")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    // MARK: - Error Banner
    private func errorBanner(message: String) -> some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button("Cerrar") {
                    viewModel.dismissError()
                }
                .foregroundStyle(.white)
                .buttonStyle(.plain)
            }
            .padding()
            .background(.red)
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: viewModel.appState)
    }
    
    // MARK: - Computed Properties
    private var borderColor: Color {
        switch viewModel.appState {
        case .idle:
            return viewModel.isDragOver ? .green : Color(.separatorColor)
        case .validating:
            return .green
        default:
            return Color(.separatorColor)
        }
    }
    
    private var borderWidth: CGFloat {
        switch viewModel.appState {
        case .idle:
            return viewModel.isDragOver ? 3 : 1
        case .validating:
            return 3
        default:
            return 1
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 700, height: 500)
}
