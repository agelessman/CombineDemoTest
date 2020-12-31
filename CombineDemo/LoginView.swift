//
//  LoginView.swift
//  CombineDemo
//
//  Created by MC on 2020/12/30.
//

import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var dataModel = LoginDataModel()
    @State private var showAlert = false
    
    var body: some View {
        VStack {
            TextField("请输入用户名", text: $dataModel.userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if dataModel.showUserNameError {
                Text("用户名不能少于3位！！！")
                    .foregroundColor(Color.red)
            }

            SecureField("请输入密码", text: $dataModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if dataModel.showPasswordError {
                Text("密码不能少于6位！！！")
                    .foregroundColor(Color.red)
            }

            GeometryReader { geometry in
                Button(action: {
                    self.showAlert.toggle()
                }) {
                    Text("登录")
                        .foregroundColor(dataModel.buttonEnable ? Color.white : Color.white.opacity(0.3))
                        .frame(width: geometry.size.width, height: 35)
                        .background(dataModel.buttonEnable ? Color.blue : Color.gray)
                        .clipShape(Capsule())
                }
                .disabled(!dataModel.buttonEnable)

            }
            .frame(height: 35)
        }
        .padding()
        .border(Color.green)
        .padding()
        .animation(.easeInOut)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("登录成功"),
                  message: Text("\(dataModel.userName) \n \(dataModel.password)"),
                  dismissButton: nil)
        }
        .onDisappear {
            dataModel.clear()
        }
    }
}

class LoginDataModel: ObservableObject {
    @Published var userName: String = ""
    @Published var password: String = ""
    @Published var buttonEnable = false
    
    @Published var showUserNameError = false
    @Published var showPasswordError = false
    
    var cancellables = Set<AnyCancellable>()
    
    var userNamePublisher: AnyPublisher<String, Never> {
        return $userName
            .receive(on: RunLoop.main)
            .map { value in
                guard value.count > 2 else {
                    self.showUserNameError = value.count > 0
                    return ""
                }
                self.showUserNameError = false
                return value
            }
            .eraseToAnyPublisher()
    }
    
    var passwordPublisher: AnyPublisher<String, Never> {
        return $password
            .receive(on: RunLoop.main)
            .map { value in
                guard value.count > 5 else {
                    self.showPasswordError = value.count > 0
                    return ""
                }
                self.showPasswordError = false
                return value
            }
            .eraseToAnyPublisher()
    }
    
    init() {
        Publishers
            .CombineLatest(userNamePublisher, passwordPublisher)
            .map { v1, v2 in
                !v1.isEmpty && !v2.isEmpty
            }
            .receive(on: RunLoop.main)
            .assign(to: \.buttonEnable, on: self)
            .store(in: &cancellables)
    }
    
    func clear() {
        cancellables.removeAll()
    }
    
    deinit {
        
    }
}
