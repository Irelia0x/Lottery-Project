# 🎲 Automated Raffle Contract

A sophisticated, decentralized raffle system built with **Solidity**, **Chainlink VRF v2.5**, and **Chainlink Keepers**. This project demonstrates advanced smart contract development with full automation and provable fairness.

## 📋 Contract Details

| Detail               | Value                                                                                        |
| :------------------- | :------------------------------------------------------------------------------------------- |
| **Contract Address** | `0x1C068897151D594C4b5e271b7FB87548a7a2473D`                                                 |
| **Network**          | Sepolia Testnet                                                                              |
| **Block Explorer**   | [View on Etherscan](https://sepolia.etherscan.io/address/0x1C068897151D594C4b5e271b7FB87548a7a2473D) |
| **Entrance Fee**     | 0.01 ETH                                                                                     |
| **Draw Interval**    | 30 seconds                                                                                   |

## 🚀 Features

*   ✅ **Chainlink VRF v2.5** - Verifiable random number generation for fair winner selection
*   ✅ **Chainlink Keepers** - Fully automated raffle execution
*   ✅ **Time-based Draws** - Automatic winner selection every 30 seconds
*   ✅ **Secure Prize Distribution** - Automatic ETH transfer to winners
*   ✅ **State Management** - Prevents entries during calculation phase
*   ✅ **Comprehensive Testing** - 100% test coverage with edge cases

## 🛠️ Tech Stack

*   **Solidity** `^0.8.19`
*   **Foundry** - Development framework with fuzzing & fork testing
*   **Chainlink VRF v2.5** - Verifiable randomness
*   **Chainlink Keepers** - Smart contract automation
*   **OpenZeppelin** - Security patterns and best practices

## 📁 Project Structure

```
Lottery-Project/
├── src/                    # Smart contract source
│   └── Raffle.sol         # Main raffle contract
├── test/                  # Comprehensive test suite
│   └── unit/RaffleTest.t.sol
├── script/                # Deployment & interaction scripts
│   ├── DeployRaffle.s.sol
│   ├── HelperConfig.s.sol
│   └── interactions.s.sol
├── lib/                   # Dependencies
└── foundry.toml          # Foundry configuration
```

## 🧪 Testing & Quality

### Running Tests

```bash
# Run all tests
forge test

# Run with gas reports
forge test --gas-report

# Run specific test suites
forge test --mt testCheckUpkeep
forge test --mt testFulfilRandomWords

# Run with verbose output
forge test -vvv
```

### Test Coverage Includes:

*   ✅ Contract initialization and state management
*   ✅ Player entry validation and event emission
*   ✅ Upkeep condition checking (time, balance, state, players)
*   ✅ VRF integration and winner selection
*   ✅ Prize distribution and state reset
*   ✅ Edge cases and security checks

## 🚀 Deployment

### Prerequisites

*   **Foundry** installed
*   Sepolia ETH for gas
*   Chainlink subscription for VRF

### Deployment Command

```bash
forge script script/DeployRaffle.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  -vvvv
```

### Network Configuration

The project supports multiple networks through `HelperConfig.s.sol`:

*   **Sepolia**: Live testnet with real VRF
*   **Anvil**: Local development with mocks

## 📖 How It Works

### 1. Enter Raffle

Players call `enterRaffle()` with the required entrance fee.

```solidity
function enterRaffle() public payable {
    require(msg.value == i_ENTRANCE_FEE, "Raffle__SendMoreETHtoEnterRaffle");
    require(s_raffleState == RaffleState.OPEN, "Raffle_raffleNotOpen");
    s_players.push(payable(msg.sender));
    emit RaffleEnter(msg.sender);
}
```

### 2. Automated Upkeep

**Chainlink Keepers** regularly call `checkUpkeep()` which verifies:

*   Enough time has passed (30 seconds)
*   Raffle is in `OPEN` state
*   Contract has ETH balance
*   There are players entered

### 3. Random Winner Selection

When upkeep conditions are met:

*   Contract requests random words from **Chainlink VRF**
*   VRF callback selects winner using provable randomness
*   Winner receives entire contract balance
*   Raffle state resets for next round

### 4. Key Contract Functions

*   `enterRaffle()` - Enter the raffle with 0.01 ETH
*   `checkUpkeep()` - View function for automation checks
*   `performUpkeep()` - Manual trigger for winner selection
*   `getRecentWinner()` - View last winner address

## 🔧 Development

### Setup

```bash
# Clone repository
git clone https://github.com/Irelia0x/Lottery-Project.git
cd Lottery-Project

# Install dependencies
forge install

# Build project
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run specific test
forge test --mt testRaffleInitializesInOpenState

# Run with trace
forge test -vvv

# Gas optimization report
forge test --gas-report
```

## 🔒 Security Features

*   **Reentrancy Protection** - Using Checks-Effects-Interactions pattern
*   **Input Validation** - Comprehensive `require` statements
*   **Access Control** - Critical functions protected
*   **State Management** - Prevents invalid state transitions
*   **VRF Integration** - Provably fair random number generation

## 🌟 Key Learnings

This project demonstrates:

*   Advanced smart contract development with **Foundry**
*   **Chainlink VRF v2.5** integration for randomness
*   **Chainlink Keepers** for contract automation
*   Comprehensive testing strategies (unit, integration, fuzzing)
*   Gas optimization and security best practices
*   Multi-network deployment strategies

## 🔗 Links & Resources

*   **Live Contract**: [Etherscan](https://sepolia.etherscan.io/address/0x1C068897151D594C4b5e271b7FB87548a7a2473D)
*   **Chainlink VRF Docs**: [VRF v2.5 Documentation](https://docs.chain.link/vrf/v2_5/introduction)
*   **Foundry Book**: [Foundry Documentation](https://book.getfoundry.sh/)

## 📄 License

This project is licensed under the **MIT License**.

---


