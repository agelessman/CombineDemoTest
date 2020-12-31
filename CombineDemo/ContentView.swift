//
//  ContentView.swift
//  CombineDemo
//
//  Created by MC on 2020/12/29.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var dataModel = MyViewModel()
    @State private var showLogin = false;
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    HStack(spacing: 10) {
                        Group {
                            if dataModel.loading {
                                ActivityIndicator()
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                        .frame(width: 30, height: 30)
                        
                        TextField("请输入要搜索的repository", text: $dataModel.inputText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("登录") {
                            self.showLogin.toggle()
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    
                }
                .frame(width: geometry.size.width, height: 44)
                .background(Color.orange)
                
                List(dataModel.repositories) { res in
                    GithubListCell(repository: res)
                }
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
    }
}

struct GithubListCell: View {
    let repository: GithubRepository
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(repository.full_name)
                .font(.title3)
            
            Text(repository.description ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                
                HStack(spacing: 4) {
                    Image(systemName: "star")
                        .foregroundColor(.secondary)
                    
                    Text("\(repository.stargazers_count)")
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .foregroundColor(Color.orange)
                        .frame(width: 10, height: 10)
                    
                    Text("\(repository.language)")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
        }
    }
}

struct GithubRepository: Codable, Identifiable {
    let id: Int
    let full_name: String
    let description: String?
    let stargazers_count: Int
    let language: String
}

struct GithubRepositoryResponse: Codable {
    let items: [GithubRepository]
}

final class MyViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var repositories = [GithubRepository]()
    @Published var loading = false
    
    var cancellable: AnyCancellable?
    var cancellable1: AnyCancellable?
    
    let myBackgroundQueue = DispatchQueue(label: "myBackgroundQueue")
    
    init() {
        cancellable = $inputText
//            .debounce(for: 1.0, scheduler: myBackgroundQueue)
            .throttle(for: 1.0, scheduler: myBackgroundQueue, latest: true)
            .removeDuplicates()
            .print("Github input")
            .map { input -> AnyPublisher<[GithubRepository], Never> in
                let originalString = "https://api.github.com/search/repositories?q=\(input)"
                let escapedString = originalString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                let url = URL(string: escapedString)!
                return GithubAPI.fetch(url: url)
                    .decode(type: GithubRepositoryResponse.self, decoder: JSONDecoder())
                    .map {
                        $0.items
                    }
                    .replaceError(with: [])
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .assign(to: \.repositories, on: self)
        
        cancellable1 = GithubAPI.networkActivityPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.loading, on: self)
    }
}

struct ActivityIndicator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView()
        return view
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.startAnimating()
    }
}
