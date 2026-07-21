/*@vulnerable_(SWC: 110)_at_lines: 42*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProductVerifier {
    function verifyProductProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}

contract ZKPWithSupplyChain{
    IProductVerifier public verifier;
    mapping(uint256 => bool) public registeredProducts;
    uint256 public totalProducts;
    uint256 public constant MAX_PRODUCTS = 1000;

    event ProductRegistered(uint256 indexed productId);
    event VerificationFailed(uint256 indexed productId);

    constructor(address verifierAddress) {
        verifier = IProductVerifier(verifierAddress);
        totalProducts = 0;
    }

    // Function to verify ZKP proof of product and register the product in the supply chain
    function verifyAndRegisterProduct(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        uint256 productId = input[0];

        // Ensure the product is not already registered
        require(!registeredProducts[productId], "Product is already registered.");

        // Verify the product using the ZKP verifier
        bool proofValid = verifier.verifyProductProof(a, b, c, input);

        // Ensure the number of registered products doesn't exceed the maximum limit
        assert(totalProducts < MAX_PRODUCTS);  

        if (proofValid) {
            registeredProducts[productId] = true;
            totalProducts += 1;
            emit ProductRegistered(productId);
        } else {
            emit VerificationFailed(productId);
        }
    }

    // Function to check if a product is registered
    function isProductRegistered(uint256 productId) public view returns (bool) {
        return registeredProducts[productId];
    }

    // Function to get the total number of registered products
    function getTotalProducts() public view returns (uint256) {
        return totalProducts;
    }
}
