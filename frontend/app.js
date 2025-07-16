// Contract configuration
let CONTRACT_ADDRESS = null; // Will be set by user
const CONTRACT_ABI = [
    "function placeCoinBet(uint256 prediction) external payable",
    "function placeDiceBet(uint256 prediction) external payable",
    "function getBet(uint256 betId) external view returns (tuple(address player, uint256 amount, uint8 gameType, uint256 prediction, uint256 result, bool won, uint8 status, uint256 payout, uint256 timestamp))",
    "function getPlayerBets(address player) external view returns (uint256[])",
    "function getContractBalance() external view returns (uint256)",
    "function getGameStats() external view returns (uint256, uint256, uint256, uint256)",
    "function nextBetId() external view returns (uint256)",
    "uint256 public totalBets",
    "uint256 public totalPayout",
    "event BetPlaced(uint256 indexed betId, address indexed player, uint256 amount, uint8 gameType, uint256 prediction)",
    "event BetResolved(uint256 indexed betId, address indexed player, uint256 result, bool won, uint256 payout)"
];

class BettingGameApp {
    constructor() {
        this.provider = null;
        this.signer = null;
        this.contract = null;
        this.userAddress = null;
        this.coinPrediction = null;
        this.dicePrediction = null;
        this.userBets = [];
        
        this.initializeEventListeners();
    }

    async init() {
        // Check if MetaMask is installed
        if (typeof window.ethereum !== 'undefined') {
            this.provider = new ethers.BrowserProvider(window.ethereum);
        } else {
            this.showNotification('Please install MetaMask to use this DApp!', 'error');
            return;
        }
        
        // Load saved contract address
        const savedAddress = localStorage.getItem('contractAddress');
        if (savedAddress && ethers.isAddress(savedAddress)) {
            CONTRACT_ADDRESS = savedAddress;
            document.getElementById('contract-address').value = savedAddress;
            await this.checkConnection();
        } else {
            // Show message about setting contract address
            this.showNotification('Please enter your deployed contract address in the configuration section first.', 'warning');
            document.getElementById('contract-address').focus();
        }
    }

    initializeEventListeners() {
        // Connect wallet button
        document.getElementById('connect-wallet').addEventListener('click', () => this.connectWallet());
        
        // Update config button
        document.getElementById('update-config').addEventListener('click', () => this.updateConfig());

        // Refresh stats button
        document.getElementById('refresh-stats').addEventListener('click', () => this.loadGameStats());

        // Coin prediction buttons
        document.querySelectorAll('.prediction-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                document.querySelectorAll('.prediction-btn').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');
                this.coinPrediction = parseInt(btn.dataset.value);
            });
        });

        // Dice prediction buttons
        document.querySelectorAll('.dice-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                document.querySelectorAll('.dice-btn').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');
                this.dicePrediction = parseInt(btn.dataset.value);
            });
        });

        // Place bet buttons
        document.getElementById('place-coin-bet').addEventListener('click', () => this.placeCoinBet());
        document.getElementById('place-dice-bet').addEventListener('click', () => this.placeDiceBet());

        // Account changed event
        if (window.ethereum) {
            window.ethereum.on('accountsChanged', (accounts) => {
                if (accounts.length === 0) {
                    this.disconnect();
                } else {
                    this.userAddress = accounts[0];
                    this.updateWalletInfo();
                    this.loadUserBets();
                }
            });

            window.ethereum.on('chainChanged', () => {
                window.location.reload();
            });
        }
    }

    updateConfig() {
        const address = document.getElementById('contract-address').value.trim();
        if (!address) {
            this.showNotification('Please enter a contract address!', 'error');
            return;
        }
        
        if (!ethers.isAddress(address)) {
            this.showNotification('Please enter a valid contract address!', 'error');
            return;
        }
        
        CONTRACT_ADDRESS = address;
        localStorage.setItem('contractAddress', address);
        this.showNotification('Contract address updated! Now connect your wallet.', 'success');
        
        // Reset connection state
        this.disconnect();
        
        // Check connection with new address
        this.checkConnection();
    }

    async checkConnection() {
        if (!CONTRACT_ADDRESS) {
            return;
        }
        
        try {
            const accounts = await this.provider.listAccounts();
            if (accounts.length > 0) {
                this.userAddress = accounts[0].address;
                this.signer = await this.provider.getSigner();
                this.contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, this.signer);
                this.updateWalletInfo();
                this.loadGameStats();
                this.loadUserBets();
                this.setupEventListeners();
            }
        } catch (error) {
            console.error('Error checking connection:', error);
        }
    }

    async connectWallet() {
        if (!CONTRACT_ADDRESS) {
            this.showNotification('Please set contract address first!', 'error');
            document.getElementById('contract-address').focus();
            return;
        }
        
        try {
            const accounts = await this.provider.send('eth_requestAccounts', []);
            this.userAddress = accounts[0];
            this.signer = await this.provider.getSigner();
            this.contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, this.signer);
            
            this.updateWalletInfo();
            this.loadGameStats();
            this.loadUserBets();
            this.setupEventListeners();
            
            this.showNotification('Wallet connected successfully!', 'success');
        } catch (error) {
            console.error('Error connecting wallet:', error);
            this.showNotification('Error connecting wallet. Please try again.', 'error');
        }
    }

    async updateWalletInfo() {
        if (!this.userAddress) return;

        // Update address display
        const addressElement = document.getElementById('wallet-address');
        addressElement.textContent = `${this.userAddress.slice(0, 6)}...${this.userAddress.slice(-4)}`;

        // Update balance
        try {
            const balance = await this.provider.getBalance(this.userAddress);
            const balanceElement = document.getElementById('wallet-balance');
            balanceElement.textContent = parseFloat(ethers.formatEther(balance)).toFixed(4);
        } catch (error) {
            console.error('Error getting balance:', error);
        }

        // Update connect button
        const connectBtn = document.getElementById('connect-wallet');
        connectBtn.innerHTML = '<i class="fas fa-check"></i> Connected';
        connectBtn.classList.add('disabled');
    }

    async loadGameStats() {
        if (!this.contract || !CONTRACT_ADDRESS) {
            console.log('No contract instance or address available');
            document.getElementById('total-bets').textContent = 'Not Connected';
            document.getElementById('total-payout').textContent = 'Not Connected';
            document.getElementById('contract-balance').textContent = 'Not Connected';
            return;
        }

        console.log('=== Starting loadGameStats ===');
        console.log('Contract address:', CONTRACT_ADDRESS);

        try {
            // Test basic contract connectivity first
            console.log('Testing basic contract call...');
            const nextBetId = await this.contract.nextBetId();
            console.log('nextBetId works:', nextBetId.toString());
            
            // Try to get contract balance using provider (always works)
            console.log('Getting contract balance via provider...');
            const contractBalance = await this.provider.getBalance(CONTRACT_ADDRESS);
            console.log('contractBalance works:', ethers.formatEther(contractBalance));
            
            // Update UI with what we can get
            document.getElementById('contract-balance').textContent = parseFloat(ethers.formatEther(contractBalance)).toFixed(4);
            
            // For total bets, use nextBetId as approximation (starts at 1)
            const totalBetsApprox = Math.max(0, Number(nextBetId));
            document.getElementById('total-bets').textContent = totalBetsApprox.toString();
            
            // For total payout, we'll show N/A since we can't calculate it without the function
            document.getElementById('total-payout').textContent = 'N/A';
            
            console.log('=== Stats loaded successfully (basic version)! ===');
            this.showNotification('Stats loaded! Note: Some stats may be approximated.', 'success');
            
        } catch (error) {
            console.error('=== Error in loadGameStats ===');
            console.error('Error:', error.message);
            
            // Set error display
            document.getElementById('total-bets').textContent = 'Error';
            document.getElementById('total-payout').textContent = 'Error';
            document.getElementById('contract-balance').textContent = 'Error';
            
            this.showNotification('Failed to load stats: ' + error.message, 'error');
        }
    }

    async loadUserBets() {
        if (!this.contract || !this.userAddress) return;

        try {
            const betIds = await this.contract.getPlayerBets(this.userAddress);
            this.userBets = [];
            
            for (const betId of betIds) {
                const bet = await this.contract.getBet(betId);
                this.userBets.push({
                    id: betId.toString(),
                    ...bet
                });
            }

            this.updateBetHistory();
            this.updateUserStats();
        } catch (error) {
            console.error('Error loading user bets:', error);
        }
    }

    updateBetHistory() {
        const historyElement = document.getElementById('bet-history');
        
        if (this.userBets.length === 0) {
            historyElement.innerHTML = '<div class="bet-item"><div><strong>No bets found</strong></div></div>';
            return;
        }

        const sortedBets = this.userBets.sort((a, b) => parseInt(b.id) - parseInt(a.id));
        
        historyElement.innerHTML = sortedBets.map(bet => {
            const gameType = bet.gameType === 0 ? 'Coin' : 'Dice';
            const prediction = bet.gameType === 0 ? (bet.prediction === 0 ? 'Heads' : 'Tails') : bet.prediction.toString();
            const result = bet.status === 1 ? (bet.gameType === 0 ? (bet.result === 0 ? 'Heads' : 'Tails') : bet.result.toString()) : 'Pending';
            const statusClass = bet.status === 1 ? (bet.won ? 'won' : 'lost') : 'pending';
            const statusText = bet.status === 1 ? (bet.won ? 'Won' : 'Lost') : 'Pending';
            
            return `
                <div class="bet-item ${statusClass}">
                    <div>
                        <strong>${gameType} Bet #${bet.id}</strong><br>
                        <small>Predicted: ${prediction} | Result: ${result}</small>
                    </div>
                    <div style="text-align: right;">
                        <strong>${ethers.formatEther(bet.amount)} ETH</strong><br>
                        <small>${statusText}</small>
                        ${bet.won ? `<br><small style="color: green;">+${ethers.formatEther(bet.payout)} ETH</small>` : ''}
                    </div>
                </div>
            `;
        }).join('');
    }

    updateUserStats() {
        const wins = this.userBets.filter(bet => bet.won).length;
        document.getElementById('your-wins').textContent = wins;
    }

    async placeCoinBet() {
        if (!CONTRACT_ADDRESS) {
            this.showNotification('Please set contract address first!', 'error');
            return;
        }
        
        if (!this.contract || !this.userAddress) {
            this.showNotification('Please connect your wallet first!', 'error');
            return;
        }

        if (this.coinPrediction === null) {
            this.showNotification('Please select heads or tails!', 'error');
            return;
        }

        const amountInput = document.getElementById('coin-bet-amount');
        const amount = amountInput.value;

        if (!amount || parseFloat(amount) <= 0) {
            this.showNotification('Please enter a valid bet amount!', 'error');
            return;
        }

        try {
            const betBtn = document.getElementById('place-coin-bet');
            betBtn.innerHTML = '<div class="loading"></div> Placing Bet...';
            betBtn.classList.add('disabled');

            const tx = await this.contract.placeCoinBet(this.coinPrediction, {
                value: ethers.parseEther(amount)
            });

            this.showNotification('Bet placed! Waiting for confirmation...', 'warning');
            await tx.wait();

            this.showNotification('Coin bet placed successfully!', 'success');
            amountInput.value = '';
            this.coinPrediction = null;
            document.querySelectorAll('.prediction-btn').forEach(btn => btn.classList.remove('selected'));
            
            // Refresh data
            this.loadGameStats();
            this.loadUserBets();
            this.updateWalletInfo();
        } catch (error) {
            console.error('Error placing coin bet:', error);
            this.showNotification('Error placing bet. Please try again.', 'error');
        } finally {
            const betBtn = document.getElementById('place-coin-bet');
            betBtn.innerHTML = '<i class="fas fa-play"></i> Place Coin Bet';
            betBtn.classList.remove('disabled');
        }
    }

    async placeDiceBet() {
        if (!CONTRACT_ADDRESS) {
            this.showNotification('Please set contract address first!', 'error');
            return;
        }
        
        if (!this.contract || !this.userAddress) {
            this.showNotification('Please connect your wallet first!', 'error');
            return;
        }

        if (this.dicePrediction === null) {
            this.showNotification('Please select a number (1-6)!', 'error');
            return;
        }

        const amountInput = document.getElementById('dice-bet-amount');
        const amount = amountInput.value;

        if (!amount || parseFloat(amount) <= 0) {
            this.showNotification('Please enter a valid bet amount!', 'error');
            return;
        }

        try {
            const betBtn = document.getElementById('place-dice-bet');
            betBtn.innerHTML = '<div class="loading"></div> Placing Bet...';
            betBtn.classList.add('disabled');

            const tx = await this.contract.placeDiceBet(this.dicePrediction, {
                value: ethers.parseEther(amount)
            });

            this.showNotification('Bet placed! Waiting for confirmation...', 'warning');
            await tx.wait();

            this.showNotification('Dice bet placed successfully!', 'success');
            amountInput.value = '';
            this.dicePrediction = null;
            document.querySelectorAll('.dice-btn').forEach(btn => btn.classList.remove('selected'));
            
            // Refresh data
            this.loadGameStats();
            this.loadUserBets();
            this.updateWalletInfo();
        } catch (error) {
            console.error('Error placing dice bet:', error);
            this.showNotification('Error placing bet. Please try again.', 'error');
        } finally {
            const betBtn = document.getElementById('place-dice-bet');
            betBtn.innerHTML = '<i class="fas fa-play"></i> Place Dice Bet';
            betBtn.classList.remove('disabled');
        }
    }

    setupEventListeners() {
        if (!this.contract) return;

        // Listen for bet placed events
        this.contract.on('BetPlaced', (betId, player, amount, gameType, prediction) => {
            if (player.toLowerCase() === this.userAddress.toLowerCase()) {
                this.showNotification('Bet placed! Waiting for result...', 'warning');
            }
        });

        // Listen for bet resolved events
        this.contract.on('BetResolved', (betId, player, result, won, payout) => {
            if (player.toLowerCase() === this.userAddress.toLowerCase()) {
                if (won) {
                    this.showNotification(`Congratulations! You won ${ethers.formatEther(payout)} ETH!`, 'success');
                } else {
                    this.showNotification('Sorry, you lost this bet. Better luck next time!', 'error');
                }
                
                // Refresh data
                setTimeout(() => {
                    this.loadGameStats();
                    this.loadUserBets();
                    this.updateWalletInfo();
                }, 2000);
            }
        });
    }

    disconnect() {
        this.userAddress = null;
        this.signer = null;
        this.contract = null;
        this.userBets = [];
        
        document.getElementById('wallet-address').textContent = 'Not Connected';
        document.getElementById('wallet-balance').textContent = '0';
        document.getElementById('your-wins').textContent = '0';
        
        const connectBtn = document.getElementById('connect-wallet');
        connectBtn.innerHTML = '<i class="fas fa-wallet"></i> Connect Wallet';
        connectBtn.classList.remove('disabled');
        
        document.getElementById('bet-history').innerHTML = '<div class="bet-item"><div><strong>Connect wallet to view bet history</strong></div></div>';
    }

    showNotification(message, type = 'success') {
        const notification = document.getElementById('notification');
        notification.textContent = message;
        notification.className = `notification ${type}`;
        notification.classList.add('show');
        
        setTimeout(() => {
            notification.classList.remove('show');
        }, 4000);
    }
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const app = new BettingGameApp();
    app.init();

    // Auto-refresh stats every 30 seconds
    setInterval(() => {
        if (app.contract) {
            app.loadGameStats();
        }
    }, 30000);
});
