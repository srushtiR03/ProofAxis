// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ProofAxis Token (PAXIS)
 * @dev Basic ERC20 Token implementation with ownership controls
 */
contract ProofAxis {
    string public name = "ProofAxis";
    string public symbol = "PAXIS";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;

    // Balances mapping
    mapping(address => uint256) private balances;

    // Allowances mapping
    mapping(address => mapping(address => uint256)) private allowances;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Owner-only modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Constructor mints initial supply to deployer (owner)
    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply * 10 ** decimals;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    // Returns balance of an account
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // Transfer tokens to a recipient
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    // Approve spender to spend tokens
    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Approve to zero address");

        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    // Returns remaining allowance for spender
    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return allowances[tokenOwner][spender];
    }

    // Transfer tokens from sender to recipient using allowance
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);

        return true;
    }

    // Mint new tokens (owner only)
    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Mint to zero address");

        uint256 mintAmount = amount * 10 ** decimals;
        totalSupply += mintAmount;
        balances[account] += mintAmount;
        emit Transfer(address(0), account, mintAmount);
    }

    // Burn tokens (owner only)
    function burn(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Burn from zero address");
        uint256 burnAmount = amount * 10 ** decimals;
        require(balances[account] >= burnAmount, "Burn amount exceeds balance");

        balances[account] -= burnAmount;
        totalSupply -= burnAmount;
        emit Transfer(account, address(0), burnAmount);
    }

    // Transfer contract ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
