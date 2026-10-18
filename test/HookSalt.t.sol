// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {SwarmlingsHook} from "../src/SwarmlingsHook.sol";

/// @dev IMD's protected floor deploys the hook by CREATE2 and mines the salt in Solidity (HookMiner style: one
/// keccak of the whole creation code per salt, memory growing every iteration), once from its factory probe and
/// once from the test contract itself. A long search runs that suite's setUp out of memory gas: launch 1954
/// needed 57,357 salts from the factory probe, launch 2167 45,113 from the test contract; launches that passed
/// needed 2,186 to 8,568. BUILD_TAG is chosen so every search here ends quickly. Any change to the hook's
/// bytecode moves these numbers: re-pick BUILD_TAG if this test fails.
contract HookSaltTest is Test {
    address constant FACTORY_PROBE = address(0xfac7);
    address constant POOL_MANAGER_PROBE = address(0x900c);
    address constant TOKEN_PROBE = address(0x70ce);
    /// @dev forge's default test contract address, `address(this)` in the floor's suites.
    address constant TEST_CONTRACT = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    address constant LAUNCH_FACTORY = 0x12C63b581d07093F6126bc02263c58f7EadaA96F;
    address constant POOL_MANAGER = 0x000000000004444c5dc75cB358380D2e3dE08A90;

    function _salts(address deployer, address manager, address token) internal pure returns (uint256 n) {
        bytes32 h = keccak256(abi.encodePacked(type(SwarmlingsHook).creationCode, abi.encode(manager, token)));
        for (;; ++n) {
            address a = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), deployer, n, h)))));
            if (uint160(a) & Hooks.ALL_HOOK_MASK == Hooks.ALL_HOOK_MASK) return n + 1;
        }
    }

    function test_floorFindsTheHookSaltQuickly() public pure {
        assertLe(_salts(FACTORY_PROBE, POOL_MANAGER_PROBE, TOKEN_PROBE), 1_000, "factory probe, manager probe");
        assertLe(_salts(TEST_CONTRACT, POOL_MANAGER_PROBE, TOKEN_PROBE), 1_000, "test contract, manager probe");
        assertLe(_salts(FACTORY_PROBE, POOL_MANAGER, TOKEN_PROBE), 8_000, "factory probe, live manager");
        assertLe(_salts(TEST_CONTRACT, POOL_MANAGER, TOKEN_PROBE), 8_000, "test contract, live manager");
        assertLe(_salts(LAUNCH_FACTORY, POOL_MANAGER_PROBE, TOKEN_PROBE), 8_000, "live factory, manager probe");
        assertLe(_salts(LAUNCH_FACTORY, POOL_MANAGER, TOKEN_PROBE), 8_000, "live factory, live manager");
    }
}
