//
//  ViewModel.swift
//  mvvm-combine-tableview-binding
//
//  Created by Karlos Aguirre Zaragoza on 08/03/23.
//

import UIKit
import Combine

class ViewModel {
  
  enum Input {
    case viewDidLoad
    case onProductCellEvent(event: ProductCellEvent, product: Product)
    case onResetButtonTap
  }
  
  enum Output {
    case setProducts(products: [Product])
    case updateView(numberOfItemsInCart: Int, totalCost: Int, likedProductIds: Set<Int>, productQuantities: [Int: Int])
  }
  
  private let output = PassthroughSubject<ViewModel.Output, Never>()
  private var cancellables = Set<AnyCancellable>()
  
  @Published private var cart: [Product: Int] = [:]
  @Published private var likes: [Product: Bool] = [:]
  
  init() {
    observe()
  }
  
  func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
    input.sink { [unowned self] event in
      switch event {
      case .viewDidLoad:
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [unowned self] in
          output.send(.setProducts(products: Product.collection))
          output.send(.updateView(numberOfItemsInCart: numberOfItemsInCart, totalCost: totalCost, likedProductIds: likedProductIds, productQuantities: productQuantities))
        }
      case .onResetButtonTap:
        cart.removeAll()
        likes.removeAll()
        output.send(.updateView(numberOfItemsInCart: numberOfItemsInCart, totalCost: totalCost, likedProductIds: likedProductIds, productQuantities: productQuantities))
      case .onProductCellEvent(let event, let product):
        switch event {
        case .quantityDidChange(let value):
          cart[product] = value
          output.send(.updateView(numberOfItemsInCart: numberOfItemsInCart, totalCost: totalCost, likedProductIds: likedProductIds, productQuantities: productQuantities))
        case .heartDidTap:
          if let value = likes[product] {
            likes[product] = !value
          } else {
            likes[product] = true
          }
          output.send(.updateView(numberOfItemsInCart: numberOfItemsInCart, totalCost: totalCost, likedProductIds: likedProductIds, productQuantities: productQuantities))
        }
      }
    }.store(in: &cancellables)
    return output.eraseToAnyPublisher()
  }
  
  private func observe() {
    $cart.dropFirst().sink { dict in
      dict.forEach { k,v in
        print("\(k.name) - \(v)")
      }
      print("=======")
    }.store(in: &cancellables)
    
    $likes.dropFirst().sink { dict in
      let products = dict.filter({ $0.value == true }).map({ $0.key.name })
      print("❤️ \(products)")
    }.store(in: &cancellables)
  }
  
  private var numberOfItemsInCart: Int {
    cart.reduce(0, { $0 + $1.value })
  }
  
  private var totalCost: Int {
    cart.reduce(0, { $0 + ($1.value * $1.key.price )})
  }
  
  private var likedProductIds: Set<Int> {
    let array = likes.filter { $0.value == true }.map { $0.key.id }
    return Set(array)
  }
  
  private var productQuantities: [Int: Int] {
    var temp = [Int: Int]()
    cart.forEach { key, value in
      temp[key.id] = value
    }
    return temp
  }
}
