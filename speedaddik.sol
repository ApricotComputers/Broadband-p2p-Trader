// SPDX-License-Identifier: MIT
// Thanks for helping, Meshly Team. For bandwidth enthusiasts, and those wanting to trade Internets : ) this is for you! If you want to link up with us. Do so on our Telegram 
// channel @ https://t.me/+SXiyL8ar_wM4NTJh
pragma solidity ^0.8.0;

contract BandwidthContractTrading {

    struct Contract {
        uint contractID;
        address payable owner;
        uint price;               // Price in USDC or equivalent BTC
        uint capacity;            // Bandwidth capacity in Mbps
        uint usage;               // Current bandwidth usage in Mbps
        uint monthlyFee;          // Monthly recurring fee (MRF)
        uint maintenanceCost;     // Minimum cost to keep the contract dormant
        uint remainingPayments;   // Remaining payments on the contract
        bool isForSale;           // Is the contract listed for sale
        string status;            // active, dormant, or inactive
        string contractOwnerBTCWallet; // BTC wallet address of the contract owner
    }

    mapping(uint => Contract) public contracts;
    uint public contractCount = 0;

    event ContractListed(uint contractID, address owner, uint price, uint capacity, string status);
    event ContractSold(uint contractID, address newOwner, uint price);
    event StatusUpdated(uint contractID, string newStatus);
    event PaymentReceived(uint contractID, uint amount, string paymentType);

    // List a contract for sale
    function listContract(uint _price, uint _capacity, uint _monthlyFee, uint _maintenanceCost, uint _remainingPayments, string memory _btcWalletAddress) public {
        contractCount++;
        contracts[contractCount] = Contract(
            contractCount,
            payable(msg.sender),
            _price,
            _capacity,
            0,                    // initial usage is 0
            _monthlyFee,
            _maintenanceCost,
            _remainingPayments,
            true,
            "active",              // Initially set the contract as active
            _btcWalletAddress      // Contract owner's BTC wallet address for receiving payments
        );
        emit ContractListed(contractCount, msg.sender, _price, _capacity, "active");
    }

    // Buy a contract
    function buyContract(uint _contractID) public payable {
        Contract storage bandwidthContract = contracts[_contractID];
        require(bandwidthContract.isForSale, "Contract is not for sale");
        require(msg.value == bandwidthContract.price, "Please send the exact price");

        // Transfer ownership
        address payable previousOwner = bandwidthContract.owner;
        bandwidthContract.owner = payable(msg.sender);
        bandwidthContract.isForSale = false;

        // Transfer funds to the previous owner
        previousOwner.transfer(msg.value);

        emit ContractSold(_contractID, msg.sender, bandwidthContract.price);
    }

    // Update the contract status based on payments received
    function updateContractStatus(uint _contractID, uint amount) public {
        Contract storage bandwidthContract = contracts[_contractID];

        // If the contract owner received the full monthly fee, the contract remains active
        if (amount >= bandwidthContract.monthlyFee) {
            bandwidthContract.status = "active";
        } 
        // If the contract owner received the maintenance cost, the contract goes dormant
        else if (amount >= bandwidthContract.maintenanceCost) {
            bandwidthContract.status = "dormant";
        } 
        // If neither is paid, the contract becomes inactive
        else {
            bandwidthContract.status = "inactive";
        }

        emit StatusUpdated(_contractID, bandwidthContract.status);
    }

    // Function to withdraw funds by contract owners if needed
    function withdrawFunds(address payable to, uint amount) public {
        require(msg.sender == to, "Unauthorized withdrawal");
        to.transfer(amount);
    }
}
