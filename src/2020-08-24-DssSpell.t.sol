pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell, SpellAction} from "./2020-08-24-DssSpell.sol";

contract Hevm {
    function warp(uint256) public;
    function store(address,bytes32,bytes32) public;
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = address(0);
    // this needs to be updated
    uint256 constant SPELL_CREATED = 1595258877;

    struct CollateralValues {
        uint256 line;
        uint256 dust;
        uint256 duty;
        uint256 chop;
        uint256 lump;
        uint256 pct;
        uint256 mat;
        uint256 beg;
        uint48 ttl;
        uint48 tau;
    }

    struct SystemValues {
        uint256 dsr;
        uint256 dsrPct;
        uint256 Line;
        uint256 pauseDelay;
        mapping (bytes32 => CollateralValues) collaterals;
    }

    SystemValues beforeSpell;
    SystemValues afterSpell;

    Hevm hevm;

    // MAINNET ADDRESSES
    // DSPauseAbstract pause       = DSPauseAbstract(  0xbE286431454714F511008713973d3B053A2d38f3);
    // address pauseProxy          =                   0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    // DSChiefAbstract chief       = DSChiefAbstract(  0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    // VatAbstract     vat         = VatAbstract(      0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    // CatAbstract     cat         = CatAbstract(      0x78F2c2AF65126834c51822F56Be0d7469D7A523E);
    // PotAbstract     pot         = PotAbstract(      0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    // JugAbstract     jug         = JugAbstract(      0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    // SpotAbstract    spot        = SpotAbstract(     0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
    // MKRAbstract     gov         = MKRAbstract(      0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    // EndAbstract     end         = EndAbstract(      0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5);

    // KOVAN ADDRESSES
    DSPauseAbstract  pause      = DSPauseAbstract(  0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189);
    address pauseProxy          =                   0x0e4725db88Bb038bBa4C4723e91Ba183BE11eDf3;
    DSChiefAbstract  chief      = DSChiefAbstract(  0xbBFFC76e94B34F72D96D054b31f6424249c1337d);
    VatAbstract      vat        = VatAbstract(      0xbA987bDB501d131f766fEe8180Da5d81b34b69d9);
    CatAbstract      cat        = CatAbstract(      0x0511674A67192FE51e86fE55Ed660eB4f995BDd6);
    PotAbstract      pot        = PotAbstract(      0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb);
    JugAbstract      jug        = JugAbstract(      0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD);
    SpotAbstract     spot       = SpotAbstract(     0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D);
    DSTokenAbstract  gov        = DSTokenAbstract(  0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD);
    EndAbstract      end        = EndAbstract(      0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F);
    FlipAbstract     flip       = FlipAbstract(     0xa653B4C2F96f82811a117c0384675FDeb2d77B03);
    address  flipperMom         =                   0xf3828caDb05E5F22844f6f9314D99516D68a0C84;

    GemAbstract      paxusd     = GemAbstract(      0x4e4209e4981C54a6CB99aC20432E67C7cCC9794D);
    GemJoinAbstract  paxusdjoin = GemJoinAbstract(  0x96831F3eC88874cf6B2cCe604e7531bF1B55171f);
    OsmAbstract      pip        = OsmAbstract(      0xd2b75a3F7a9a627783d1c7934EC324c3d1B10749);
    OsmMomAbstract   osmMom     = OsmMomAbstract(   0x5dA9D1C3d4f1197E5c52Ff963916Fe84D2F5d8f3);
    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    uint256 constant THOUSAND   = 10 ** 3;
    uint256 constant MILLION    = 10 ** 6;
    uint256 constant WAD        = 10 ** 18;
    uint256 constant RAY        = 10 ** 27;
    uint256 constant RAD        = 10 ** 45;

    // not provided in DSMath
    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
    // 10^-5 (tenth of a basis point) as a RAY
    uint256 TOLERANCE = 10 ** 22;

    function yearlyYield(uint256 duty) public pure returns (uint256) {
        return rpow(duty, (365 * 24 * 60 *60), RAY);
    }

    function expectedRate(uint256 percentValue) public pure returns (uint256) {
        return (100000 + percentValue) * (10 ** 22);
    }

    function diffCalc(uint256 expectedRate_, uint256 yearlyYield_) public pure returns (uint256) {
        return (expectedRate_ > yearlyYield_) ? expectedRate_ - yearlyYield_ : yearlyYield_ - expectedRate_;
    }

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));

        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        hevm.store(
            address(gov),
            keccak256(abi.encode(address(this), uint256(1))),
            bytes32(uint256(999999999999 ether))
        );

        beforeSpell = SystemValues({
            dsr: 1000000000000000000000000000,
            dsrPct: 0 * 1000,
            Line: 173050 * THOUSAND * RAD,
            pauseDelay: 60
        });

        afterSpell = SystemValues({
            dsr: 1000000000000000000000000000,
            dsrPct: 0 * 1000,
            Line: beforeSpell.Line + 1 * MILLION * RAD,
            pauseDelay: 60
        });

        // We do not have real values yet. Just picked MANA values
        afterSpell.collaterals["PAXUSD-A"] = CollateralValues({
            line: 1 * MILLION * RAD,            // 1m debt ceiling
            dust: 20 * RAD,
            duty: 1000000003593629043335673582, // 12% stability fee
            pct: 12 * 1000,
            chop: 113 * RAY / 100,
            lump: 500 * THOUSAND * WAD,
            mat: 175 * RAY / 100,               // 175% collateralization ratio
            beg: 103 * WAD / 100,
            ttl: 6 hours,
            tau: 6 hours 
        });
    }

    function vote() private {
        if (chief.hat() != address(spell)) {
            gov.approve(address(chief), uint256(-1));
            chief.lock(sub(gov.balanceOf(address(this)), 1 ether));

            assertTrue(!spell.done());

            address[] memory yays = new address[](1);
            yays[0] = address(spell);

            chief.vote(yays);
            chief.lift(address(spell));
        }
        assertEq(chief.hat(), address(spell));
    }

    function scheduleWaitAndCast() public {
        spell.schedule();
        hevm.warp(now + pause.delay());
        spell.cast();
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function checkSystemValues(SystemValues storage values) internal {
        // dsr
        assertEq(pot.dsr(), values.dsr);
        assertTrue(diffCalc(expectedRate(values.dsrPct), yearlyYield(values.dsr)) <= TOLERANCE);

        // Line
        assertEq(vat.Line(), values.Line);

        // Pause delay
        assertEq(pause.delay(), values.pauseDelay);

    }

    function checkCollateralValues(bytes32 ilk, SystemValues storage values) internal {
        (uint duty,)  = jug.ilks(ilk);
        assertEq(duty,   values.collaterals[ilk].duty);
        assertTrue(diffCalc(expectedRate(values.collaterals[ilk].pct), yearlyYield(values.collaterals[ilk].duty)) <= TOLERANCE);

        (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
        assertEq(line, values.collaterals[ilk].line);
        assertEq(dust, values.collaterals[ilk].dust);

        (, uint256 chop, uint256 lump) = cat.ilks(ilk);
        assertEq(chop, values.collaterals[ilk].chop);
        assertEq(lump, values.collaterals[ilk].lump);

        (,uint256 mat) = spot.ilks(ilk);
        assertEq(mat, values.collaterals[ilk].mat);

        assertEq(uint256(flip.beg()), values.collaterals[ilk].beg);
        assertEq(uint256(flip.ttl()), values.collaterals[ilk].ttl);
        assertEq(uint256(flip.tau()), values.collaterals[ilk].tau);
    }

    // this spell is intended to run as the MkrAuthority
    function canCall(address, address, bytes4) public pure returns (bool) {
        return true;
    }

    // function testSpellIsCast() public {
    //     if(address(spell) != address(MAINNET_SPELL)) {
    //         assertEq(spell.expiration(), (now + 30 days));
    //     } else {
    //         assertEq(spell.expiration(), (SPELL_CREATED + 30 days));
    //     }

    //     checkSystemValues(beforeSpell);

    //     vote();
    //     scheduleWaitAndCast();
    //     assertTrue(spell.done());

    //     checkSystemValues(afterSpell);

    //     checkCollateralValues("PAXUSD-A", afterSpell);
    // }

    function testSpellIsCast_INTEGRATION() public {
        vote();
        scheduleWaitAndCast();

        // spell done
        assertTrue(spell.done());

        // check afterSpell parameters
        checkSystemValues(afterSpell);
        checkCollateralValues("PAXUSD-A", afterSpell);

        // Authorization
        assertEq(paxusdjoin.wards(pauseProxy), 1);
        assertEq(vat.wards(address(paxusdjoin)), 1);
        assertEq(flip.wards(address(end)), 1);
        assertEq(flip.wards(flipperMom), 1);
        assertEq(pip.bud(address(spot)), 1);

        // Start testing Vault
        uint256 current_dai = vat.dai(address(this));

        // Join to adapter
        hevm.store(
            address(paxusd),
            keccak256(abi.encode(address(this), uint256(1))),
            bytes32(uint256(600 * WAD))
        );
        assertEq(paxusd.balanceOf(address(this)), 600 * WAD);
        assertEq(vat.gem("PAXUSD-A", address(this)), 0);
        paxusd.approve(address(paxusdjoin), 600 * WAD);
        paxusdjoin.join(address(this), 600 * WAD);
        assertEq(paxusd.balanceOf(address(this)), 0);
        assertEq(vat.gem("PAXUSD-A", address(this)), 600 * WAD);

        // Deposit collateral, generate DAI
        assertEq(vat.dai(address(this)), current_dai);
        vat.frob("PAXUSD-A", address(this), address(this), address(this), int(600 * WAD), int(25 * WAD));
        assertEq(vat.gem("PAXUSD-A", address(this)), 0);
        assertEq(vat.dai(address(this)), add(current_dai, 25 * RAD));

        // Payback DAI, withdraw collateral
        vat.frob("PAXUSD-A", address(this), address(this), address(this), -int(600 * WAD), -int(25 * WAD));
        assertEq(vat.gem("PAXUSD-A", address(this)), 600 * WAD);
        assertEq(vat.dai(address(this)), current_dai);

        // Withdraw from adapter
        paxusdjoin.exit(address(this), 600 * 10 ** 18);
        assertEq(paxusd.balanceOf(address(this)), 600 * 10 ** 18);
        assertEq(vat.gem("PAXUSD-A", address(this)), 0);
    }
}
