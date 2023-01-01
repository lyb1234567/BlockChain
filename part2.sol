pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "Library.sol";
contract Part2_token
{
    using SafeMath for uint256;
    address payable private owner;
    string  name;
    string  symbol;
    uint256  price;
    uint256  totalsupply;
    mapping(address => uint256) private  balances;
    mapping(address => bool) private roles;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Sell(address indexed from, uint256 value);
    
    
    constructor() public {
        // Set token metadata
        name = "Custom Token";
        symbol = "CT";
        price = 600; // 600 wei per token
        // Set contract owner as the token creator
        owner =  payable(msg.sender);
        // initialize the role-based access control
        roles[owner]=true;
        // Mint initial supply of tokens for the contract owner
        totalsupply = 1000000;
        balances[owner] = totalsupply;
        emit Mint(owner, totalsupply);
    }

    function totalSupply() public view returns(uint256)
    {
          return totalsupply;
    }

    function getName()public view returns(string memory)
    {
        return name;
    }

    function getSymbol() public view returns ( string memory )
    {
        return symbol; 
    }

    function getPrice() public view returns ( uint256 )
    {
        return price; 
    }

    function transfer(address to, uint256 value) public returns (bool) {
        // Ensure caller has sufficient balance
        require(balances[msg.sender].sub(value) >= 0, "You do not have sufficient balance");

        // Transfer tokens and update balances
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        // Emit event and return success
        emit Transfer(msg.sender, to, value);
        return true; 
    }
    
    function  mint (address to, uint256 value) public returns (bool)
    {
        require(roles[msg.sender] == true, "Only the owner can mint new tokens");
        totalsupply = totalsupply + value;
        balances[to] =  balances[ to ] + value;
        emit Mint ( to , value); 
        return true;
    }

    // Check the current amount of tokens of owner.
    function balanceOf(address _account) public view returns (uint256)
    {
        return balances[_account];
    }
    function sell(uint256 value) public payable returns (bool)
    {
        require(balances[msg.sender].sub(value)>=0, "Insufficient balance");

        // Calculate the amount of wei to be received for the sale
        uint256 weiAmount = value * 600; // 600 wei per token

        // Transfer the wei to the seller and update their balance
        
        // Check that the contract has a sufficient balance before calling the transfer function to avoid the reentrancy attack.
        require(address(this).balance.sub(weiAmount)>=0, "Contract balance is insufficient");

        bool succ = customLib.customSend(weiAmount, msg.sender);
        require(succ,"Unsuccessful Send");
        balances[msg.sender] = balances[msg.sender].sub(value);

        // Update the total supply of tokens
        totalsupply = totalsupply.sub(value);

        // Emit the Sell event to log the sale of tokens
        emit Sell(msg.sender, value);

        // Return success
        return true;
    }

    function close() public {
        // Ensure caller is the contract owner
        require(roles[msg.sender] == true, "Only the owner can destroy the contract");

        // Transfer contract balance to owner and destroy contract
        
        bool success= customLib.customSend(address(this).balance,owner);
        require(success,"Unsuccessful close");
        selfdestruct(owner);
    }
    fallback() external payable {
        // Do nothing, just accept the Ethers
    }

}

