// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BandwidthContractTrading {

    struct Contract {
        uint contractID;
        address payable owner;
        uint price;               // Price in USDC or equivalent BTC
        uint capacity;            // Bandwidth capacity in Mbps
        uint usage;               // Current bandwidth usage in Mbps
        uint monthlyFee;          // Monthly Recurring Revenue (MRR)
        uint maintenanceCost;     // Minimum cost to keep the contract dormant (148,609.04 UGX or $40 USD)
        uint remainingPayments;   // Remaining payments on the contract
        bool isForSale;           // Is the contract listed for sale
        string status;            // "active', "dormant|, or "inactive"
        string contractOwnerBTCWallet; // BTC wallet address of the contract owner
        uint lastMaintenancePayment;   // Timestamp of last maintenance payment
    }

    mapping(uint => Contract) public contracts;
    uint public contractCount = 0;
    uint public maintenanceFeeUSD = 40;           // $40 USD
    uint public maintenanceFeeUGX = 14860904;     // 148,609.04 UGX
    uint public maintenanceInterval = 27;     // Maintenance payment is required every 27 days

    event ContractListed(uint contractID, address owner, uint price, uint capacity, string status);
    event ContractSold(uint contractID, address newOwner, uint price);
    event StatusUpdated(uint contractID, string newStatus);
    event PaymentReceived(uint contractID, uint amount, string paymentType);
    event MaintenanceFeePaid(uint contractID, uint amount, string currency);
    event ContractInactive(uint contractID, string message);

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
            _btcWalletAddress,     // Contract owner's BTC wallet address for receiving payments
            block.timestamp        // Set the initial last maintenance payment timestamp to now
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

    // Airtel Representative marks maintenance fee as paid
    function markMaintenanceFeeAsPaid(uint _contractID, uint amount, string memory transactionDetails) public {
        Contract storage bandwidthContract = contracts[_contractID];

        require(amount >= bandwidthContract.maintenanceCost, "Insufficient payment to cover maintenance fee");

        // Update the last maintenance payment timestamp
        bandwidthContract.lastMaintenancePayment = block.timestamp;

        // Set contract status to active after payment is logged by Airtel Rep
        bandwidthContract.status = "active";

        // Emit an event for the payment being made
        emit MaintenanceFeePaid(_contractID, amount, transactionDetails);
    }
    
    // Function to update the contract status manually by admin (if necessary)
    function updateContractStatus(uint _contractID, string memory newStatus) public {
        Contract storage bandwidthContract = contracts[_contractID];
        bandwidthContract.status = newStatus;

        emit StatusUpdated(_contractID, newStatus);
    }

    // Function to withdraw funds by contract owners if needed
    function withdrawFunds(address payable to, uint amount) public {
        require(msg.sender == to, "Unauthorized withdrawal");
        to.transfer(amount);
    }
}
