// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {IAdapter} from "../src/interfaces/IAdapter.sol";
import {ConsumerWrapper} from "Randcast-User-Contract/user/ConsumerWrapper.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";

contract GetRandomNumberScenarioTestMudScript is Script {
    function run() external {
        ConsumerWrapper _consumerImpl;
        //IAdapter adapter;

        //uint256 plentyOfEthBalance = vm.envUint("PLENTY_OF_ETH_BALANCE");
        address _adapterAddress = vm.envAddress("ADAPTER_ADDRESS");
        uint256 _adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        uint256 _userPrivateKey = vm.envUint("USER_PRIVATE_KEY");

        vm.startBroadcast(_userPrivateKey);
        bytes32 implSalt = keccak256(abi.encode("ComsumerWrapper"));
         // Deploy the ConsumerWrapper contract using Create2
        ConsumerWrapper comsumerImpl = new ConsumerWrapper{salt: implSalt}(_adapterAddress);
        console.log(address(comsumerImpl));

        bytes memory proxyBytecode = abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(comsumerImpl, abi.encodeWithSignature("initialize()")));

        // Compute a new unique salt for the ERC1967Proxy contract
        bytes32 proxySalt = keccak256(abi.encodePacked("ComsumerWrapperProxy"));

        // Deploy the ERC1967Proxy contract using Create2
        ERC1967Proxy porxy = new ERC1967Proxy{salt: proxySalt}(address(comsumerImpl),abi.encodeWithSignature("initialize()"));
        console.log(address(porxy));
        vm.stopBroadcast();
    }
}
