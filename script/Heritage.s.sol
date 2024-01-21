// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {HeritageContract} from "../src/Heritage.sol";

contract CounterScript is Script {
    HeritageContract public heritage;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        heritage = new HeritageContract();
        vm.stopBroadcast();
    }
}
