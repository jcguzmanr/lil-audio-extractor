//
//  lil_audio_extractorApp.swift
//  lil-audio-extractor
//
//  Created by jcguzmanr on 6/6/25.
//

import SwiftUI

@main
struct lil_audio_extractorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Abrir Video...") {
                    // This will be handled by the ContentView's ViewModel
                    if let window = NSApp.keyWindow,
                       let contentView = window.contentView,
                       let hostingView = contentView.subviews.first(where: { $0 is NSHostingView<ContentView> }) as? NSHostingView<ContentView> {
                        // Trigger file selection through the view model
                        // Note: This is a simplified approach. In a real app, you might want to use a more robust method.
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            
            CommandGroup(after: .help) {
                Button("Acerca de Video → Audio Extractor") {
                    showAboutWindow()
                }
            }
        }
    }
    
    private func showAboutWindow() {
        let aboutPanel = NSAlert()
        aboutPanel.messageText = "Video → Audio Extractor"
        aboutPanel.informativeText = """
        Versión 1.0
        
        Convierte archivos de video a audio de forma sencilla.
        
        Desarrollado con SwiftUI y AVFoundation para macOS 14+
        """
        aboutPanel.alertStyle = .informational
        aboutPanel.addButton(withTitle: "OK")
        aboutPanel.runModal()
    }
}
