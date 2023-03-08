//
//  mvvm_combine_tableview_bindingTests.swift
//  mvvm-combine-tableview-bindingTests
//
//  Created by Karlos Aguirre Zaragoza on 08/03/23.
//

import XCTest
import Combine
@testable import mvvm_combine_tableview_binding

final class mvvm_combine_tableview_bindingTests: XCTestCase {
    
    private var sut: ViewModel!
    private var productService: MockProductService!
    
    private let vcOutput = PassthroughSubject<ViewModel.Input, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        productService = MockProductService()
        sut = .init(productService: productService)
    }
    
//    override func tearDown() {
//        super.tearDown()
//        productService = nil
//        sut = nil
//    }
    
    func test_fetch_products_when_viewdidload_is_called() {
        //given
        let vmOutput = sut.transform(input: vcOutput.eraseToAnyPublisher())
        let expectation = XCTestExpectation(description: "fetch products called")
        //when
        vmOutput.sink { event in }.store(in: &cancellables)
        productService.expectation = expectation
        vcOutput.send(.viewDidLoad)
        //then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(productService.fetchProductsCallCounter, 1)
    }
    
    func test_set_products_and_update_view_successfully_when_fetch_products_is_called() {
        //given
        let vmOutput = sut.transform(input: vcOutput.eraseToAnyPublisher())
        productService.mockedValues = [
            .init(name: "Apple", imageName: "apple.fill", price: 10, id: 1),
            .init(name: "Orange", imageName: "orange.fill", price: 20, id: 2)
        ]
        let expectation = XCTestExpectation(description: "set products called")
        let expectation2 = XCTestExpectation(description: "update view called")
        //then
        vmOutput.sink { event in
            switch event {
            case let .setProducts(products):
                expectation.fulfill()
                XCTAssertEqual(products.count, 2)
                XCTAssertEqual(products[0].name, "Apple")
                XCTAssertEqual(products[0].imageName, "apple.fill")
                XCTAssertEqual(products[0].price, 10)
            case let .updateView(numberOfItemsInCart, totalCost, likedProductIds, productQuantities):
                expectation2.fulfill()
                XCTAssertEqual(numberOfItemsInCart, 0)
                XCTAssertEqual(totalCost, 0)
                XCTAssertEqual(likedProductIds, Set([]))
                XCTAssertEqual(productQuantities, [:])
            }
        }.store(in: &cancellables)
        //when
        vcOutput.send(.viewDidLoad)
        wait(for: [expectation, expectation2], timeout: 0.5)
    }
    
    func test_update_view_when_product_added_to_card_is_called() {
        //given
        let vmOutput = sut.transform(input: vcOutput.eraseToAnyPublisher())
        let selectedProduct = Product(name: "Apple", imageName: "apple.fill", price: 10, id: 1)
        productService.mockedValues = [
            .init(name: "Orange", imageName: "orange.fill", price: 2, id: 2)
        ]
        //then
        vmOutput.sink { event in
            if case let .updateView(numberOfItemsInCart, totalCost, likedProductIds, productQuantities) = event {
                XCTAssertEqual(numberOfItemsInCart, 5)
                XCTAssertEqual(totalCost, 50)
                XCTAssertTrue(likedProductIds.isEmpty)
                XCTAssertEqual(productQuantities[selectedProduct.id], 5)
            } else {
                XCTFail("expecting the updateView event")
            }
        }.store(in: &cancellables)
        //when
        vcOutput.send(.onProductCellEvent(event: .quantityDidChange(value: 5), product: selectedProduct))
    }
}

class MockProductService: ProductService {
    
    var mockedValues: [Product] = []
    var fetchProductsCallCounter = 0
    var expectation: XCTestExpectation?
    
    func fetchProducts() async -> [mvvm_combine_tableview_binding.Product] {
        expectation?.fulfill()
        fetchProductsCallCounter += 1
        return mockedValues
    }

}
