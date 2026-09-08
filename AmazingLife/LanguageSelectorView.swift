//
//  LanguageSelectorView.swift
//  selfManager
//
//  Created by Assistant on 2024
//

import SwiftUI

struct LanguageSelectorView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var isPresented: Bool
    @State private var selectedLanguage: AppLanguage
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self._selectedLanguage = State(initialValue: LocalizationManager.shared.currentLanguage)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(AppLanguage.allCases) { language in
                    Button(action: {
                        selectedLanguage = language
                    }) {
                        HStack {
                            Text(language.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("language_selection".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        // 应用语言设置
                        if selectedLanguage != localizationManager.currentLanguage {
                            localizationManager.switchLanguage(to: selectedLanguage)
                        }
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    LanguageSelectorView(isPresented: .constant(true))
        .environmentObject(LocalizationManager.shared)
}