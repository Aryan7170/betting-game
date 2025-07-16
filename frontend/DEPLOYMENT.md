# Frontend Deployment Guide

This guide explains how to deploy the Betting Game frontend to various hosting platforms.

## Prerequisites

1. **Smart Contract Deployed**: Deploy your BettingGame contract first
2. **Contract Address**: Have the deployed contract address ready
3. **Frontend Files**: Complete frontend directory with all files

## Deployment Options

### Option 1: GitHub Pages (Free)

1. **Create a GitHub Repository**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/betting-game-frontend.git
   git push -u origin main
   ```

2. **Enable GitHub Pages**
   - Go to repository Settings
   - Scroll to "Pages" section
   - Select "Deploy from a branch"
   - Choose "main" branch and "/ (root)" folder
   - Save

3. **Access Your Site**
   - Your site will be available at `https://yourusername.github.io/betting-game-frontend`

### Option 2: Netlify (Free)

1. **Deploy via Drag & Drop**
   - Go to https://netlify.com
   - Drag your frontend folder to the deployment area
   - Wait for deployment to complete

2. **Deploy via Git**
   - Connect your GitHub repository
   - Set build command: (leave empty)
   - Set publish directory: (leave empty or "/")
   - Deploy site

### Option 3: Vercel (Free)

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Deploy**
   ```bash
   cd frontend
   vercel
   ```

3. **Follow the prompts**
   - Choose your project settings
   - Deploy

### Option 4: IPFS (Decentralized)

1. **Install IPFS**
   - Download from https://ipfs.io/
   - Install and start IPFS daemon

2. **Add to IPFS**
   ```bash
   ipfs add -r frontend/
   ```

3. **Pin to IPFS**
   - Use services like Pinata or Infura to pin your content

### Option 5: Local Server (Development)

1. **Using Python**
   ```bash
   cd frontend
   python3 -m http.server 8080
   ```

2. **Using Node.js**
   ```bash
   cd frontend
   npx http-server -p 8080
   ```

3. **Using the provided script**
   ```bash
   cd frontend
   ./start-server.sh
   ```

## Post-Deployment Configuration

### 1. Update Contract Address
- Open your deployed frontend
- Enter your contract address in the configuration section
- Click "Update Configuration"

### 2. Network Configuration
Make sure users are on the correct network:
- **Mainnet**: For production deployment
- **Testnet**: For testing (Goerli, Sepolia)
- **Local**: For development (Hardhat, Ganache)

### 3. MetaMask Setup
Users need to:
- Install MetaMask browser extension
- Connect to the correct network
- Have ETH for gas fees and betting

## Security Considerations

### 1. HTTPS Required
- Most hosting platforms provide HTTPS automatically
- MetaMask requires HTTPS for production use

### 2. Content Security Policy
Add to your HTML head if needed:
```html
<meta http-equiv="Content-Security-Policy" content="default-src 'self' https:; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net;">
```

### 3. Contract Address Validation
- The frontend validates contract addresses
- Users should always verify the contract address

## Custom Domain (Optional)

### GitHub Pages
1. Add a `CNAME` file to your repository root
2. Add your domain name to the file
3. Configure DNS settings with your domain provider

### Netlify/Vercel
1. Go to domain settings in your dashboard
2. Add your custom domain
3. Follow DNS configuration instructions

## Environment Variables

For different environments, you might want to set:

```javascript
// In app.js, you can add environment detection
const NETWORKS = {
  1: 'mainnet',
  5: 'goerli',
  11155111: 'sepolia',
  31337: 'localhost'
};

const DEFAULT_CONTRACTS = {
  1: '0x...', // mainnet contract
  5: '0x...', // goerli contract
  11155111: '0x...', // sepolia contract
  31337: '0x5FbDB2315678afecb367f032d93F642f64180aa3' // localhost
};
```

## Testing Your Deployment

1. **Load the frontend** in your browser
2. **Check console** for any errors
3. **Test wallet connection** with MetaMask
4. **Verify contract interaction** by checking stats
5. **Test betting functionality** with small amounts

## Troubleshooting

### Common Issues

1. **Mixed Content Errors**
   - Ensure all resources are loaded via HTTPS
   - Check for any HTTP links in your code

2. **CORS Issues**
   - Most static hosting platforms handle CORS automatically
   - For custom servers, configure CORS headers

3. **MetaMask Not Connecting**
   - Ensure site is served over HTTPS
   - Check browser console for errors
   - Verify MetaMask is unlocked

4. **Contract Not Loading**
   - Verify contract address is correct
   - Check network configuration
   - Ensure contract is deployed on the current network

## Monitoring

### Analytics
Add Google Analytics or similar:
```html
<!-- Add to index.html head -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

### Error Tracking
Consider adding error tracking services like Sentry for production deployments.

## Maintenance

### Regular Updates
- Monitor for ethers.js updates
- Update contract ABI if contract changes
- Check for security vulnerabilities

### Backup
- Keep backups of your frontend files
- Version control with Git
- Document any customizations

## Support

For issues with:
- **Smart Contract**: Check the main project repository
- **Frontend**: Check browser console for errors
- **MetaMask**: Visit MetaMask support documentation
- **Hosting**: Check your hosting platform's documentation
