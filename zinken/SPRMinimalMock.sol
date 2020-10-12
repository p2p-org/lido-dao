pragma solidity 0.4.24;

import "./SafeMath.sol";
import "./SafeMath64.sol";
import "./BytesLib.sol";

contract SPRMinimalMock {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    address owner;
    uint256 constant public PUBKEY_LENGTH = 48;
    uint256 constant public SIGNATURE_LENGTH = 96;
    uint256 internal activeSPCount;

    bytes32 internal constant SIGNING_KEYS_MAPPING_NAME = keccak256("depools.DePool.signingKeys");

    /// @dev Staking provider parameters and internal state
    struct StakingProvider {
        bool active;    // a flag indicating if the SP can participate in further staking and reward distribution
        address rewardAddress;  // Ethereum 1 address which receives steth rewards for this SP
        string name;    // human-readable name
        uint64 stakingLimit;    // the maximum number of validators to stake for this SP
        uint64 stoppedValidators;   // number of signing keys which stopped validation (e.g. were slashed)

        uint64 totalSigningKeys;    // total amount of signing keys of this SP
        uint64 usedSigningKeys;     // number of signing keys of this SP which were used in deposits to the Ethereum 2
    }

    uint256 internal totalSPCount;
    /// @dev Mapping of all staking providers. Mapping is used to be able to extend the struct.
    mapping(uint256 => StakingProvider) internal sps;

    event SigningKeyAdded(uint256 indexed SP_id, bytes pubkey);
    event SigningKeyRemoved(uint256 indexed SP_id, bytes pubkey);
    event StakingProviderAdded(uint256 id, string name, address rewardAddress, uint64 stakingLimit);

    function SPRMinimalMock() public {
        owner = msg.sender;
    }

    modifier onlyOwner () {
      require(msg.sender == owner, "NOT OWNER");
      _;
    }

    modifier SPExists(uint256 _id) {
        require(_id < totalSPCount, "STAKING_PROVIDER_NOT_FOUND");
        _;
    }

    /**
    * @notice Returns total number of staking providers
    */
    function getStakingProvidersCount() external view returns (uint256) {
        return totalSPCount;
    }

    /**
    * @notice Returns total number of signing keys of the staking provider #`_SP_id`
    */
    function getTotalSigningKeyCount(uint256 _SP_id) external view SPExists(_SP_id) returns (uint256) {
        return sps[_SP_id].totalSigningKeys;
    }

    /**
    * @notice Returns n-th signing key of the staking provider #`_SP_id`
    * @param _SP_id Staking provider id
    * @param _index Index of the key, starting with 0
    * @return key Key
    * @return depositSignature Signature needed for a validator_registration.deposit call
    * @return used Flag indication if the key was used in the staking
    */
    function getSigningKey(uint256 _SP_id, uint256 _index) external view
        SPExists(_SP_id)
        returns (bytes key, bytes depositSignature, bool used)
    {
        require(_index < sps[_SP_id].totalSigningKeys, "KEY_NOT_FOUND");

        (bytes memory key_, bytes memory signature) = _loadSigningKey(_SP_id, _index);

        return (key_, signature, _index < sps[_SP_id].usedSigningKeys);
    }

    function _loadSigningKey(uint256 _SP_id, uint256 _keyIndex) internal view returns (bytes memory key, bytes memory signature) {
        // algorithm applicability constraints
        assert(PUBKEY_LENGTH >= 32 && PUBKEY_LENGTH <= 64);
        assert(0 == SIGNATURE_LENGTH % 32);

        uint256 offset = _signingKeyOffset(_SP_id, _keyIndex);

        // key
        bytes memory tmpKey = new bytes(64);
        assembly {
            mstore(add(tmpKey, 0x20), sload(offset))
            mstore(add(tmpKey, 0x40), sload(add(offset, 1)))
        }
        offset += 2;
        key = BytesLib.slice(tmpKey, 0, PUBKEY_LENGTH);

        // signature
        signature = new bytes(SIGNATURE_LENGTH);
        for (uint256 i = 0; i < SIGNATURE_LENGTH; i += 32) {
            assembly {
                mstore(add(signature, add(0x20, i)), sload(offset))
            }
            offset++;
        }
    }

    /**
      * @notice Add `_quantity` validator signing keys to the set of usable keys. Concatenated keys are: `_pubkeys`. Can be done by the DAO in question by using the designated rewards address.
      * @dev Along with each key the DAO has to provide a signatures for the
      *      (pubkey, withdrawal_credentials, 32000000000) message.
      *      Given that information, the contract'll be able to call
      *      validator_registration.deposit on-chain.
      * @param _SP_id Staking provider id
      * @param _quantity Number of signing keys provided
      * @param _pubkeys Several concatenated validator signing keys
      * @param _signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
      */
    function addSigningKeys(uint256 _SP_id, uint256 _quantity, bytes _pubkeys, bytes _signatures) external onlyOwner {
        _addSigningKeys(_SP_id, _quantity, _pubkeys, _signatures);
    }

        function _addSigningKeys(uint256 _SP_id, uint256 _quantity, bytes _pubkeys, bytes _signatures) internal
        SPExists(_SP_id)
    {
        require(_quantity != 0, "NO_KEYS");
        require(_pubkeys.length == _quantity.mul(PUBKEY_LENGTH), "INVALID_LENGTH");
        require(_signatures.length == _quantity.mul(SIGNATURE_LENGTH), "INVALID_LENGTH");

        for (uint256 i = 0; i < _quantity; ++i) {
            bytes memory key = BytesLib.slice(_pubkeys, i * PUBKEY_LENGTH, PUBKEY_LENGTH);
            require(!_isEmptySigningKey(key), "EMPTY_KEY");
            bytes memory sig = BytesLib.slice(_signatures, i * SIGNATURE_LENGTH, SIGNATURE_LENGTH);

            _storeSigningKey(_SP_id, sps[_SP_id].totalSigningKeys + i, key, sig);
            emit SigningKeyAdded(_SP_id, key);
        }

        sps[_SP_id].totalSigningKeys = sps[_SP_id].totalSigningKeys.add(to64(_quantity));
    }

    function to64(uint256 v) internal pure returns (uint64) {
        assert(v <= uint256(uint64(-1)));
        return uint64(v);
    }

    function _isEmptySigningKey(bytes memory _key) internal pure returns (bool) {
        assert(_key.length == PUBKEY_LENGTH);
        // algorithm applicability constraint
        assert(PUBKEY_LENGTH >= 32 && PUBKEY_LENGTH <= 64);

        uint256 k1;
        uint256 k2;
        assembly {
            k1 := mload(add(_key, 0x20))
            k2 := mload(add(_key, 0x40))
        }

        return 0 == k1 && 0 == (k2 >> ((2 * 32 - PUBKEY_LENGTH) * 8));
    }


    function _signingKeyOffset(uint256 _SP_id, uint256 _keyIndex) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(SIGNING_KEYS_MAPPING_NAME, _SP_id, _keyIndex)));
    }

    function _storeSigningKey(uint256 _SP_id, uint256 _keyIndex, bytes memory _key, bytes memory _signature) internal {
        assert(_key.length == PUBKEY_LENGTH);
        assert(_signature.length == SIGNATURE_LENGTH);
        // algorithm applicability constraints
        assert(PUBKEY_LENGTH >= 32 && PUBKEY_LENGTH <= 64);
        assert(0 == SIGNATURE_LENGTH % 32);

        // key
        uint256 offset = _signingKeyOffset(_SP_id, _keyIndex);
        uint256 keyExcessBits = (2 * 32 - PUBKEY_LENGTH) * 8;
        assembly {
            sstore(offset, mload(add(_key, 0x20)))
            sstore(add(offset, 1), shl(keyExcessBits, shr(keyExcessBits, mload(add(_key, 0x40)))))
        }
        offset += 2;

        // signature
        for (uint256 i = 0; i < SIGNATURE_LENGTH; i += 32) {
            assembly {
                sstore(offset, mload(add(_signature, add(0x20, i))))
            }
            offset++;
        }
    }

        /**
      * @notice Add staking provider named `name` with reward address `rewardAddress` and staking limit `stakingLimit` validators
      * @param _name Human-readable name
      * @param _rewardAddress Ethereum 1 address which receives stETH rewards for this SP
      * @param _stakingLimit the maximum number of validators to stake for this SP
      * @return a unique key of the added SP
      */
    function addStakingProvider(string _name, address _rewardAddress, uint64 _stakingLimit) external onlyOwner
        returns (uint256 id)
    {
        id = totalSPCount++;
        StakingProvider storage sp = sps[id];

        activeSPCount++;
        sp.active = true;
        sp.name = _name;
        sp.rewardAddress = _rewardAddress;
        sp.stakingLimit = _stakingLimit;

        emit StakingProviderAdded(id, _name, _rewardAddress, _stakingLimit);
    }

}
