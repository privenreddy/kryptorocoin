pragma solidity ^0.4.18;

import './KryptoroToken.sol';
import './SafeMath.sol';
import './Ownable.sol';

/**
 * @title KTOCrowdsale
 * @dev KTOCrowdsale is a completed contract for managing a token crowdsale.
 * KTOCrowdsale have a start and end timestamps, where investors can make
 * token purchases and the KTOCrowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract KTOCrowdsale is Ownable{
    using SafeMath for uint256;

    // The token being sold
    KryptoroToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event TokenContractUpdated(bool state);

    event WalletAddressUpdated(bool state);

    function KTOCrowdsale() public {
        token = createTokenContract();
        startTime = 1532332800;
        endTime = 1539590400;
        rate = 612;
        wallet = 0x34367d515ff223a27985518f2780cccc4a7e0fc9;
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    function createTokenContract() internal returns (KryptoroToken) {
        return new KryptoroToken();
    }


    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        token.transfer(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool nonZeroPurchase = msg.value != 0;
        bool withinPeriod = now >= startTime && now <= endTime;

        return nonZeroPurchase && withinPeriod;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool timeEnded = now > endTime;

        return timeEnded;
    }

    // update token contract
    function updateKryptoroToken(address _tokenAddress) onlyOwner{
        require(_tokenAddress != address(0));
        token.transferOwnership(_tokenAddress);

        TokenContractUpdated(true);
    }

    // update wallet address
    function updateWalletAddress(address _newWallet) onlyOwner {
        require(_newWallet != address(0));
        wallet = _newWallet;

        WalletAddressUpdated(true);
    }

    // transfer tokens
    function transferTokens(address _to, uint256 _amount) onlyOwner {
        require(_to != address(0));

        token.transfer(_to, _amount);
    }
}
