//
//  ViewController.swift
//  mvvm-combine-tableview-binding
//
//  Created by Karlos Aguirre Zaragoza on 08/03/23.
//

import UIKit
import Combine

class TableViewController: UITableViewController {
    
    private var numberOfItemsInCart: Int = 0
    private var totalCost: Int = 0
    private var likedProductIds: Set<Int> = []
    private var productQuantities: [Int: Int] = [:]
    private var products: [Product] = []
    
    private let vm = ViewModel()
    
    private let output = PassthroughSubject<ViewModel.Input, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
      super.viewDidLoad()
      observe()
      output.send(.viewDidLoad)
    }
    
    private func observe() {

      vm.transform(input: output.eraseToAnyPublisher())
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] event in
            switch event {
            case .setProducts(let products):
                self.products = products
            case let .updateView(numberOfItemsInCart, totalCost, likedProductIds, productQuantities):
                self.numberOfItemsInCart = numberOfItemsInCart
                self.totalCost = totalCost
                self.likedProductIds = likedProductIds
                self.productQuantities = productQuantities
                self.tableView.reloadData()
            }
      }.store(in: &cancellables)
    }
    
    @IBAction func resetButtonTapped(_ sender: Any) {
      output.send(.onResetButtonTap)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return products.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "cellId") as! ProductTableViewCell
      let product = products[indexPath.item]
      cell.setProduct(
        product: product,
        quantity: productQuantities[product.id] ?? 0,
        isLiked: likedProductIds.contains(product.id))
      cell.eventPublisher.sink { [weak self] event in
        self?.output.send(.onProductCellEvent(event: event, product: product))
      }.store(in: &cell.cancellables)
      return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 88
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      return String(format: "Number of items: %d", numberOfItemsInCart)
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
      return String(format: "Total cost: $%d", totalCost)
    }
  }

