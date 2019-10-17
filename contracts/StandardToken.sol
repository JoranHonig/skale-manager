/**
 * You should inherit from StandardToken or, for a token like you would want to
 * deploy in something like Mist, see HumanStandardToken.sol.
 * (This implements ONLY the standard functions and NOTHING else.
 * If you deploy this, you won't have anything useful.)
 *
 * Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
 */
pragma solidity ^0.5.0;

import "./Token.sol";
import "./ContractReceiver.sol";


/**
 * @title Standard token contract - Standard token implementation.
 */
contract StandardToken is Token {

    /**
     * Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /**
     * @dev Transfers sender's tokens to a given address, added due to backwards compatibility reasons with ERC20
     * @param _to Address of token receiver.
     * @param _value Number of tokens to transfer.
     * @return Returns success of function call.
     */
    function transfer(address _to, uint256 _value)
        external
        returns (bool)
    {
        bytes memory empty = "";
        return transfer(_to, _value, empty);
    }

    /**
     * @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
     * @param _from Address from where tokens are withdrawn.
     * @param _to Address to where tokens are sent.
     * @param _value Number of tokens to transfer.
     * @return Returns success of function call.
     */
    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool)
    {
        require(_from != address(0), "Destination is not set");
        require(_to != address(0), "Receiver is not set");
        require(_value > 0, "Value is too low");
        require(balances[_from] >= _value, "Not enough money");
        require(allowed[_from][_to] >= _value, "Value is too big");
        require(balances[_to] + _value > balances[_to], "Balance was not increased");

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][_to] -= _value;
        bytes memory empty = "";
        emit Transfer(
            _from,
            _to,
            _value,
            empty,
            uint32(block.timestamp),
            gasleft());
        return true;
    }

    /**
     * @dev Returns number of tokens owned by given address.
     * @param _owner Address of token owner.
     * @return Returns balance of owner.
     */
    function balanceOf(address _owner)
        external
        view
        returns (uint256)
    {
        return balances[_owner];
    }

    /**
     * @dev Sets approved amount of tokens for spender. Returns success.
     * @param _spender Address of allowed account.
     * @param _value Number of approved tokens.
     * @return Returns success of function call.
     */
    function approve(address _spender, uint256 _value)
        external
        returns (bool)
    {
        require(_spender != address(0), "Spender is not set");
        require(_value > 0, "Value is too low");

        allowed[msg.sender][_spender] = _value;
        emit Approval(
            msg.sender,
            _spender,
            _value,
            uint32(block.timestamp),
            gasleft());
        return true;
    }

    /**
     * @dev Returns number of allowed tokens for given address.
     * @param _owner Address of token owner.
     * @param _spender Address of token spender.
     * @return Returns remaining allowance for spender.
     */
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Function that is called when a user or another contract wants to transfer funds.
     * @param _to Address of token receiver.
     * @param _value Number of tokens to transfer.
     * @param _data Data to be sent to tokenFallback
     * @return Returns success of function call.
     */
    function transfer(
        address _to,
        uint256 _value,
        bytes memory _data
	)
        public
        returns (bool)
    {
        require(_to != address(0), "Receiver is not set");
        require(_value > 0, "Value is too low");
        require(balances[msg.sender] >= _value, "Not enough money");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        if (isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(
            msg.sender,
            _to,
            _value,
            _data,
            uint32(block.timestamp),
            gasleft());
        return true;
    }

    /**
     * @dev Check bytecode at given address
     * assemble the given address bytecode. If bytecode exists then the _addr is a contract.
     * @param _addr - address of possible contract
     */
    function isContract(address _addr)
        private
		view
        returns (bool)
    {
        uint length;
        assembly {
            // retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
}
