//
//  ProductService.swift
//  mvvm-combine-tableview-binding
//
//  Created by Karlos Aguirre Zaragoza on 08/03/23.
//

import Foundation

protocol ProductService {
    func fetchProducts() async -> [Product]
}

class ProductServiceImp: ProductService {
    func fetchProducts() async -> [Product] {
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000) //1 second
        return Product.collection
    }
}
