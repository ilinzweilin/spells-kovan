// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.12;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol";
import "lib/dss-interfaces/src/dss/MedianAbstract.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipperMomAbstract.sol";

contract SpellAction {
    // KOVAN ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/kovan/1.0.8/contracts.json

    address constant public MCD_VAT             = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant public MCD_CAT             = 0x0511674A67192FE51e86fE55Ed660eB4f995BDd6;
    address constant public MCD_JUG             = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    address constant public MCD_POT             = 0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb;

    address constant public MCD_SPOT            = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant public MCD_END             = 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F;
    address constant public FLIPPER_MOM         = 0xf3828caDb05E5F22844f6f9314D99516D68a0C84;
    address constant public OSM_MOM             = 0x5dA9D1C3d4f1197E5c52Ff963916Fe84D2F5d8f3;

    // PAXUSD specific addresses
    address constant public MCD_JOIN_PAXUSD_A   = 0x96831F3eC88874cf6B2cCe604e7531bF1B55171f;
    address constant public PIP_PAXUSD          = 0xd2b75a3F7a9a627783d1c7934EC324c3d1B10749;
    address constant public MCD_FLIP_PAXUSD_A   = 0xa653B4C2F96f82811a117c0384675FDeb2d77B03;
    address constant public PAXUSD              = 0x4e4209e4981C54a6CB99aC20432E67C7cCC9794D;

    // decimals & precision
    uint256 constant public THOUSAND            = 10 ** 3;
    uint256 constant public MILLION             = 10 ** 6;
    uint256 constant public WAD                 = 10 ** 18;
    uint256 constant public RAY                 = 10 ** 27;
    uint256 constant public RAD                 = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public TWELVE_PCT_RATE     = 1000000003593629043335673582;

    function execute() external {
        // Set the global debt ceiling to
        VatAbstract(MCD_VAT).file("Line", VatAbstract(MCD_VAT).Line() + 1 * MILLION * RAD);

        // Set ilk bytes32 variable
        bytes32 PAXUSD_A_ILK = "PAXUSD-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).ilk() == PAXUSD_A_ILK, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).gem() == PAXUSD, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).dec() == 18, "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_PAXUSD_A).vat()    == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_PAXUSD_A).ilk()    == PAXUSD_A_ILK, "flip-ilk-not-match");

        // Set price feed for PAXUSD-A
        SpotAbstract(MCD_SPOT).file(PAXUSD_A_ILK, "pip", PIP_PAXUSD);

        // Set the PAXUSD-A flipper in the cat
        CatAbstract(MCD_CAT).file(PAXUSD_A_ILK, "flip", MCD_FLIP_PAXUSD_A);

        // Init PAXUSD-A in Vat & Jug
        VatAbstract(MCD_VAT).init(PAXUSD_A_ILK);
        JugAbstract(MCD_JUG).init(PAXUSD_A_ILK);

        // Allow PAXUSD-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_PAXUSD_A);

        // Allow cat to kick auctions in PAXUSD-A Flipper
        // NOTE: this will be reverse later in spell, and is done only for explicitness.
        FlipAbstract(MCD_FLIP_PAXUSD_A).rely(MCD_CAT);

        // Allow End to yank auctions in PAXUSD-A Flipper
        FlipAbstract(MCD_FLIP_PAXUSD_A).rely(MCD_END);

        // Allow FlipperMom to access the PAXUSD-A Flipper
        FlipAbstract(MCD_FLIP_PAXUSD_A).rely(FLIPPER_MOM);

        VatAbstract(MCD_VAT).file(PAXUSD_A_ILK,   "line"  , 1 * MILLION * RAD    ); // 1 MM debt ceiling
        VatAbstract(MCD_VAT).file(PAXUSD_A_ILK,   "dust"  , 20 * RAD             ); // 20 Dai dust
        CatAbstract(MCD_CAT).file(PAXUSD_A_ILK,   "lump"  , 500 * THOUSAND * WAD ); // 500,000 lot size
        CatAbstract(MCD_CAT).file(PAXUSD_A_ILK,   "chop"  , 113 * RAY / 100      ); // 13% liq. penalty
        JugAbstract(MCD_JUG).file(PAXUSD_A_ILK,   "duty"  , TWELVE_PCT_RATE      ); // 12% stability fee
        FlipAbstract(MCD_FLIP_PAXUSD_A).file(     "beg"   , 103 * WAD / 100      ); // 3% bid increase
        FlipAbstract(MCD_FLIP_PAXUSD_A).file(     "ttl"   , 6 hours              ); // 6 hours ttl
        FlipAbstract(MCD_FLIP_PAXUSD_A).file(     "tau"   , 6 hours              ); // 6 hours tau
        SpotAbstract(MCD_SPOT).file(PAXUSD_A_ILK, "mat"   , 175 * RAY / 100      ); // 175% coll. ratio
        SpotAbstract(MCD_SPOT).poke(PAXUSD_A_ILK);

        // consequently, deny PAXUSD-A Flipper
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_PAXUSD_A);
    }
}

contract DssSpell {
    DSPauseAbstract  public pause =
        DSPauseAbstract(0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189);
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    modifier officeHours {
        uint day = (now / 1 days + 3) % 7;
        require(day < 5, "Can only be cast on a weekday");
        uint hour = now / 1 hours % 24;
        require(hour >= 14 && hour < 21, "Outside office hours");
        _;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}