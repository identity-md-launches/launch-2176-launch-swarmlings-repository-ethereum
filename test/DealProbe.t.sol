// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SwarmlingsBase} from "./utils/SwarmlingsBase.sol";

/// @dev IMD's protected floor writes LING balances with forge-std `deal`, on accounts the launch already touched
/// (the factory holds the supply with skipNFT set, holders carry NFT counts). stdStorage only finds a slot whose
/// whole value is the balance, so the vendored DN404 keeps `balance` in a slot of its own. Launch 2167 parked
/// when `deal` failed on such an account; this covers every account shape the floor can hit.
contract DealProbeTest is SwarmlingsBase {
    function _dealAndCheck(address who, uint256 amt, bool adjust) internal {
        uint256 supply = ling.totalSupply();
        uint256 before = ling.balanceOf(who);
        deal(address(ling), who, amt, adjust);
        assertEq(ling.balanceOf(who), amt);
        assertEq(ling.totalSupply(), adjust ? supply + amt - before : supply);
    }

    function test_dealWorksOnEveryAccountShape() public {
        _dealAndCheck(makeAddr("fresh"), 1e18, false);
        _dealAndCheck(launcher, 1e24, false); // skipNFT flag set, large balance
        _dealAndCheck(launcher, 2e24, true);
        _give(alice, UNIT * 3); // alice holds three NFTs
        _dealAndCheck(alice, UNIT * 5, false);
        _dealAndCheck(alice, UNIT, false);
        _dealAndCheck(alice, UNIT * 4, true);
        _dealAndCheck(address(manager), 1e24, false);
        _dealAndCheck(address(hook), 1e24, false);
        _dealAndCheck(address(this), 1e24, true);
    }
}
