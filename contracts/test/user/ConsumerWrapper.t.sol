// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ConsumerWrapper} from "Randcast-User-Contract/user/ConsumerWrapper.sol";
import {IConsumerWrapper} from "Randcast-User-Contract/interfaces/IConsumerWrapper.sol";
import {IRequestTypeBase} from "Randcast-User-Contract/interfaces/IRequestTypeBase.sol";
import {
    Adapter,
    RandcastTestHelper,
    ERC20,
    ControllerForTest,
    AdapterForTest,
    ERC1967Proxy
} from "../RandcastTestHelper.sol";
import {IAdapterOwner} from "../../src/interfaces/IAdapterOwner.sol";

//solhint-disable-next-line max-states-count
contract ConsumerWrapperTest is RandcastTestHelper {
    ERC1967Proxy internal _consumerWrapper;

    uint256 internal _disqualifiedNodePenaltyAmount = 1000;
    uint256 internal _defaultNumberOfCommitters = 3;
    uint256 internal _defaultDkgPhaseDuration = 10;
    uint256 internal _groupMaxCapacity = 10;
    uint256 internal _idealNumberOfGroups = 3;
    uint256 internal _pendingBlockAfterQuit = 100;
    uint256 internal _dkgPostProcessReward = 100;
    uint256 internal _lastOutput = 2222222222222222;

    uint16 internal _minimumRequestConfirmations = 3;
    uint32 internal _maxGasLimit = 2000000;
    uint32 internal _gasAfterPaymentCalculation = 50000;
    uint32 internal _gasExceptCallback = 550000;
    uint256 internal _signatureTaskExclusiveWindow = 10;
    uint256 internal _rewardPerSignature = 50;
    uint256 internal _committerRewardPerSignature = 100;

    uint16 internal _flatFeePromotionGlobalPercentage = 100;
    bool internal _isFlatFeePromotionEnabledPermanently = false;
    uint256 internal _flatFeePromotionStartTimestamp = 0;
    uint256 internal _flatFeePromotionEndTimestamp = 0;

    error CallbackFailed();

    function setUp() public {
        skip(1000);
        vm.prank(_admin);
        _arpa = new ERC20("arpa token", "ARPA");

        address[] memory operators = new address[](5);
        operators[0] = _node1;
        operators[1] = _node2;
        operators[2] = _node3;
        operators[3] = _node4;
        operators[4] = _node5;
        _prepareStakingContract(_stakingDeployer, address(_arpa), operators);

        vm.prank(_admin);
        _controller = new ControllerForTest(address(_arpa), _lastOutput);

        vm.prank(_admin);
        _adapterImpl = new AdapterForTest();

        vm.prank(_admin);
        _adapter = new ERC1967Proxy(
            address(_adapterImpl), abi.encodeWithSignature("initialize(address)", address(_controller))
        );

        vm.prank(_user);
        ConsumerWrapper _consumerWrapperImpl = new ConsumerWrapper(address(_adapter));

        vm.prank(_user);
        _consumerWrapper = new ERC1967Proxy(address(_consumerWrapperImpl), abi.encodeWithSignature("initialize()"));

        vm.prank(_admin);
        _controller.setControllerConfig(
            address(_staking),
            address(_adapter),
            _operatorStakeAmount,
            _disqualifiedNodePenaltyAmount,
            _defaultNumberOfCommitters,
            _defaultDkgPhaseDuration,
            _groupMaxCapacity,
            _idealNumberOfGroups,
            _pendingBlockAfterQuit,
            _dkgPostProcessReward
        );

        vm.prank(_admin);
        IAdapterOwner(address(_adapter)).setAdapterConfig(
            _minimumRequestConfirmations,
            _maxGasLimit,
            _gasAfterPaymentCalculation,
            _gasExceptCallback,
            _signatureTaskExclusiveWindow,
            _rewardPerSignature,
            _committerRewardPerSignature
        );

        vm.broadcast(_admin);
        IAdapterOwner(address(_adapter)).setFlatFeeConfig(
            IAdapterOwner.FeeConfig(250000, 250000, 250000, 250000, 250000, 0, 0, 0, 0),
            _flatFeePromotionGlobalPercentage,
            _isFlatFeePromotionEnabledPermanently,
            _flatFeePromotionStartTimestamp,
            _flatFeePromotionEndTimestamp
        );

        vm.prank(_stakingDeployer);
        _staking.setController(address(_controller));

        uint256 plentyOfEthBalance = 1e6 * 1e18;
        _prepareSubscription(_admin, address(_consumerWrapper), plentyOfEthBalance);

        prepareAnAvailableGroup();
    }

    function fulfillRandomness(bytes32 entityId, bytes32 requestId, uint256 randomness) external {
        emit log_uint(randomness);
    }

    function testWrapperGetRandomness() public {
        deal(_user, 1e6 * 1e18);
        vm.prank(_user);
        bytes memory params;
        uint256 gasFee = IConsumerWrapper(address(_consumerWrapper)).estimateFee(IRequestTypeBase.RequestType.Randomness, 0, params, 10000);
        emit log_uint(gasFee);
        bytes32 entityId = keccak256(abi.encodePacked("testWrapperGetRandomness"));
        vm.prank(_user);
        bytes32 requestId = IConsumerWrapper(address(_consumerWrapper)).getRandomness{value: gasFee }(
            0, entityId, 10000, address(this)
        );

        Adapter.RequestDetail memory rd = AdapterForTest(address(_adapter)).getPendingRequest(requestId);
        bytes memory rawSeed = abi.encodePacked(rd.seed);
        emit log_named_bytes("rawSeed", rawSeed);

        deal(_node1, 1 * 1e18);
        _fulfillRequest(_node1, requestId, 17);
    }

    function fulfillRandomWords(bytes32 entityId, bytes32 requestId, uint256[] memory randomWords) public {
        emit log_uint(randomWords[0]);
    }

    function testWrapperGetRandomWords() public {
        deal(_user, 1e6 * 1e18);
        vm.prank(_user);
        bytes memory params = abi.encode(4);
        uint256 gasFee = IConsumerWrapper(address(_consumerWrapper)).estimateFee(IRequestTypeBase.RequestType.RandomWords, 0, params, 60000);
        bytes32 entityId = keccak256(abi.encodePacked("testWrapperGetRandomWords"));
        vm.prank(_user);
        bytes32 requestId = IConsumerWrapper(address(_consumerWrapper)).getRandomWords{value: gasFee * 6}(
            0, entityId, 4, 60000, address(this)
        );

        Adapter.RequestDetail memory rd = AdapterForTest(address(_adapter)).getPendingRequest(requestId);
        bytes memory rawSeed = abi.encodePacked(rd.seed);
        emit log_named_bytes("rawSeed", rawSeed);

        deal(_node1, 1 * 1e18);
        _fulfillRequest(_node1, requestId, 17);
    }

    function fulfillShuffledArray(bytes32 entityId, bytes32 requestId, uint256[] memory shuffledArray) public {
        emit log_uint(shuffledArray[0]);
    }

    function testWrapperGetShuffleArray() public {
        deal(_user, 1e6 * 1e18);
        vm.prank(_user);
        bytes memory params = abi.encode(100);
        uint256 gasFee = IConsumerWrapper(address(_consumerWrapper)).estimateFee(IRequestTypeBase.RequestType.Shuffling, 0, params, 80000);
        bytes32 entityId = keccak256(abi.encodePacked("testWrapperGetShuffleArray"));
        vm.prank(_user);
        bytes32 requestId = IConsumerWrapper(address(_consumerWrapper)).getShuffleArray{value: gasFee }(
            0, entityId, 100, 80000, address(this)
        );
        Adapter.RequestDetail memory rd = AdapterForTest(address(_adapter)).getPendingRequest(requestId);
        bytes memory rawSeed = abi.encodePacked(rd.seed);
        emit log_named_bytes("rawSeed", rawSeed);

        deal(_node1, 1 * 1e18);
        _fulfillRequest(_node1, requestId, 17);
    }
}
