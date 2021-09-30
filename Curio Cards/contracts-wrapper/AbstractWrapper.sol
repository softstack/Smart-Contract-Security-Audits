pragma solidity ^0.5.0;

import "./ERC1155.sol";
import "./ICurio.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract AbstractWrapper is ERC1155 {
    using SafeMath for uint256;
    using Address for address;

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // nft id => curio contract address
    mapping (uint256 => address) public contracts;
    // nft id => nft metadata IPFS URI
    mapping (uint256 => string) public metadatas;

    // OpenSea contract with an operator => proxy lister contract address
    address public proxyRegistryAddress;

    function initialize() internal;

    /**
        @notice Initialize an nft id's data.
    */
    function create(uint256 _id, address _contract, string memory _uri) internal {

        require(contracts[_id] == address(0), "id already exists");
        contracts[_id] = _contract;

        // mint 0 just to let explorers know it exists
        emit TransferSingle(msg.sender, address(0), msg.sender, _id, 0);

        metadatas[_id] = _uri;
        emit URI(_uri, _id);
    }

    constructor(address _proxyRegistryAddress) public {
        proxyRegistryAddress = _proxyRegistryAddress;
        _owner = msg.sender;
        initialize();
    }

    /**
       @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
        @dev override ERC1155 uri function to return IPFS ref.
        @param _id NFT ID
        @return IPFS URI pointing to NFT ID's metadata.
    */
    function uri(uint256 _id) public view returns (string memory) {
        return metadatas[_id];
    }

    /**
        @dev helper function to see if NFT ID exists, makes OpenSea happy.
        @param _id NFT ID
        @return if NFT ID exists.
    */
    function exists(uint256 _id) external view returns(bool) {
        return contracts[_id] != address(0);
    }

    /**
        @dev for an NFT ID, queries and transfers tokens from the appropriate
        curio contract to itself, and mints and transfers corresponding new
        ERC-1155 tokens to caller.
     */
    function wrap(uint256 _id, uint256 _quantity) external {
        address tokenContract = contracts[_id];
        require(tokenContract != address(0), "invalid id");
        ICurio curio = ICurio(tokenContract);

        // these are here for convenience because curio contract doesn't throw meaningful exceptions
        require(curio.balanceOf(msg.sender) >= _quantity, "insufficient curio balance");
        require(curio.allowance(msg.sender, address(this)) >= _quantity, "insufficient curio allowance");
        
        curio.transferFrom(msg.sender, address(this), _quantity);

        balances[_id][msg.sender] = balances[_id][msg.sender].add(_quantity);

        // mint
        emit TransferSingle(msg.sender, address(0), msg.sender, _id, _quantity);

        address _to = msg.sender;
        if (_to.isContract()) {
           _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, msg.sender, _id, _quantity, '');
        }
    }

    /**
        @dev batch version of wrap.
     */
    function wrapBatch(uint256[] calldata _ids, uint256[] calldata _quantities) external {
        require(_ids.length == _quantities.length, "ids and quantities must match");

        address _to = msg.sender;

        for (uint256 i=0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            uint256 _quantity = _quantities[i];

            address tokenContract = contracts[_id];
            require(tokenContract != address(0), "invalid id");
            ICurio curio = ICurio(tokenContract);

            require(curio.balanceOf(msg.sender) >= _quantity, "insufficient curio balance");
            require(curio.allowance(msg.sender, address(this)) >= _quantity, "insufficient curio allowance");

            curio.transferFrom(msg.sender, address(this), _quantity);

            balances[_id][msg.sender] = balances[_id][msg.sender].add(_quantity);

            // mint
            // we are not doing a batch event because testnet opensea didn't recognize it
            emit TransferSingle(msg.sender, address(0), msg.sender, _id, _quantity);

            if (_to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, msg.sender, _id, _quantity, '');
            }
        }
    }

    /**
        @dev for an NFT ID, burns ERC-1155 quantity and transfers curio ERC-20
        tokens to caller.
     */
    function unwrap(uint256 _id, uint256 _quantity) external {
        address tokenContract = contracts[_id];
        require(tokenContract != address(0), "invalid id");
        ICurio curio = ICurio(tokenContract);

        require(balances[_id][msg.sender] >= _quantity, "insufficient balance");
        balances[_id][msg.sender] = balances[_id][msg.sender].sub(_quantity);

        curio.transfer(msg.sender, _quantity);

        // burn
        emit TransferSingle(msg.sender, address(this), address(0), _id, _quantity);
    }

    /**
        @dev batch version of unwrap.
     */
    function unwrapBatch(uint256[] calldata _ids, uint256[] calldata _quantities) external {
        require(_ids.length == _quantities.length, "ids and quantities must match");

        for (uint256 i=0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            uint256 _quantity = _quantities[i];

            address tokenContract = contracts[_id];
            require(tokenContract != address(0), "invalid id");
            ICurio curio = ICurio(tokenContract);

            require(balances[_id][msg.sender] >= _quantity, "insufficient balance");
            balances[_id][msg.sender] = balances[_id][msg.sender].sub(_quantity);

            curio.transfer(msg.sender, _quantity);

            // burn
            emit TransferSingle(msg.sender, address(this), address(0), _id, _quantity);
        }

    }

}
