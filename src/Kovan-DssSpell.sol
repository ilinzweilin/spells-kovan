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
import "lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/FlapAbstract.sol";
import "lib/dss-interfaces/src/dss/FlopAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol";
import "lib/dss-interfaces/src/dss/MedianAbstract.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipperMomAbstract.sol";
import "lib/dss-interfaces/src/dss/VowAbstract.sol";
import "lib/dss-interfaces/src/dss/MkrAuthorityAbstract.sol";

contract SpellAction {

    string constant public description = "Kovan Spell Deploy 2020-08-21";

    // KOVAN ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/kovan/1.0.9/contracts.json

    address constant MCD_VAT      = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant MCD_CAT      = 0x0511674A67192FE51e86fE55Ed660eB4f995BDd6;
    address constant MCD_JUG      = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    address constant ILK_REGISTRY = 0x6618BD7bBaBFacC518Fdec43542E4a73629B0819;

    // TODO(lucas-manuel); Update addresses
    address constant MCD_SPOT            = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant MCD_END             = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant FLIPPER_MOM         = 0x9BdDB99625A711bf9bda237044924E34E8570f75;
    address constant OSM_MOM             = 0x76416A4d5190d071bfed309861527431304aA14f;

    address constant MCD_FLIP_ETH_A      = 0x0F398a2DaAa134621e4b687FCcfeE4CE47599Cc1;
    address constant MCD_FLIP_ETH_A_OLD  = 0xd8a04F5412223F513DC55F839574430f5EC15531;

    address constant MCD_FLIP_BAT_A      = 0x5EdF770FC81E7b8C2c89f71F30f211226a4d7495;
    address constant MCD_FLIP_BAT_A_OLD  = 0xaA745404d55f88C108A28c86abE7b5A1E7817c07;

    address constant MCD_FLIP_USDC_A     = 0x545521e0105C5698f75D6b3C3050CfCC62FB0C12;
    address constant MCD_FLIP_USDC_A_OLD = 0xE6ed1d09a19Bd335f051d78D5d22dF3bfF2c28B1;

    address constant MCD_FLIP_USDC_B     = 0x6002d3B769D64A9909b0B26fC00361091786fe48;
    address constant MCD_FLIP_USDC_B_OLD = 0xec25Ca3fFa512afbb1784E17f1D414E16D01794F;

    address constant MCD_FLIP_WBTC_A     = 0xF70590Fa4AaBe12d3613f5069D02B8702e058569;
    address constant MCD_FLIP_WBTC_A_OLD = 0x3E115d85D4d7253b05fEc9C0bB5b08383C2b0603;

    address constant MCD_FLIP_ZRX_A      = 0x92645a34d07696395b6e5b8330b000D0436A9aAD;
    address constant MCD_FLIP_ZRX_A_OLD  = 0x08c89251FC058cC97d5bA5F06F95026C0A5CF9B0;

    address constant MCD_FLIP_KNC_A      = 0xAD4a0B5F3c6Deb13ADE106Ba6E80Ca6566538eE6;
    address constant MCD_FLIP_KNC_A_OLD  = 0xAbBCB9Ae89cDD3C27E02D279480C7fF33083249b;

    address constant MCD_FLIP_TUSD_A     = 0x04C42fAC3e29Fd27118609a5c36fD0b3Cb8090b3;
    address constant MCD_FLIP_TUSD_A_OLD = 0xba3f6a74BD12Cf1e48d4416c7b50963cA98AfD61;

    address constant MCD_FLIP_MANA_A     = 0x4bf9D2EBC4c57B9B783C12D30076507660B58b3a;
    address constant MCD_FLIP_MANA_A_OLD = 0x4bf9D2EBC4c57B9B783C12D30076507660B58b3a;

    // Decimals & precision
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    function execute() external {
        bytes32 ilk;
        FlipAbstract newFlip;
        FlipAbstract oldFlip;
        CatAbstract  cat = CatAbstract(MCD_CAT);
        uint256 box = 100 * MILLION * RAD; // TODO: Change this

        // TODO: Do we need oldFlip for anything anymore?
        
        /*** Update Cat ***/
        newCat.file("vow", oldCat.vow());
        vat.rely(address(newCat));
        vat.deny(address(oldCat));
        vow.rely(address(newCat));
        vow.deny(address(oldCat));
        end.file("cat", address(newCat));
        newCat.rely(address(end));
        newCat.file("box", box);


        /*** ETH-A Flip ***/
        ilk = "ETH-A";
        newFlip = FlipAbstract(MCD_FLIP_ETH_A);
        oldFlip = FlipAbstract(MCD_FLIP_ETH_A_OLD);

        newCat.file(ilk, "flip", address(newFlip));
        newCat.file(ilk, "chop", chop);
        newCat.file(ilk, "lump", lump);
        newCat.rely(address(newFlip));

        newFlip.rely(address(newCat));
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.cat() == address(newCat), "non-matching-cat");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");


        /*** BAT-A Flip ***/
        ilk = "BAT-A";
        newFlip = FlipAbstract(MCD_FLIP_BAT_A);
        oldFlip = FlipAbstract(MCD_FLIP_BAT_A_OLD);

        newCat.file(ilk, "flip", address(newFlip));
        newCat.file(ilk, "chop", chop);
        newCat.file(ilk, "lump", lump);
        newCat.rely(address(newFlip));

        newFlip.rely(address(newCat));
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.cat() == address(newCat), "non-matching-cat");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");


        /*** USDC-A Flip ***/
        ilk = "USDC-A";
        newFlip = FlipAbstract(MCD_FLIP_USDC_A);
        oldFlip = FlipAbstract(MCD_FLIP_USDC_A_OLD);

        newCat.file(ilk, "flip", address(newFlip));
        newCat.file(ilk, "chop", chop);
        newCat.file(ilk, "lump", lump);
        newCat.rely(address(newFlip));

        newFlip.rely(address(newCat)); // This will be denied after via FlipperMom, just doing this for explicitness
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.cat() == address(newCat), "non-matching-cat");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_USDC_A);


        /*** USDC-B Flip ***/
        ilk = "USDC-B";
        newFlip = FlipAbstract(MCD_FLIP_USDC_B);
        oldFlip = FlipAbstract(MCD_FLIP_USDC_B_OLD);

        newCat.file(ilk, "flip", address(newFlip));
        newCat.file(ilk, "chop", chop);
        newCat.file(ilk, "lump", lump);
        newCat.rely(address(newFlip));

        newFlip.rely(address(newCat)); // This will be denied after via FlipperMom, just doing this for explicitness
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.cat() == address(newCat), "non-matching-cat");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_USDC_B);


        /*** WBTC-A Flip ***/
        ilk = "WBTC-A";
        newFlip = FlipAbstract(MCD_FLIP_WBTC_A);
        oldFlip = FlipAbstract(MCD_FLIP_WBTC_A_OLD);

        newCat.file(ilk, "flip", address(newFlip));
        newCat.file(ilk, "chop", chop);
        newCat.file(ilk, "lump", lump);
        newCat.rely(address(newFlip));

        newFlip.rely(address(newCat));
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.cat() == address(newCat), "non-matching-cat");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");


        /*** TUSD-A Flip ***/
        ilk = "TUSD-A";
        newFlip = FlipAbstract(MCD_FLIP_TUSD_A);
        oldFlip = FlipAbstract(MCD_FLIP_TUSD_A_OLD);

        newCat.file(ilk, "flip", address(newFlip));
        newCat.file(ilk, "chop", chop);
        newCat.file(ilk, "lump", lump);
        newCat.rely(address(newFlip));

        newFlip.rely(address(newCat)); // This will be denied after via FlipperMom, just doing this for explicitness
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.cat() == address(newCat), "non-matching-cat");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_TUSD_A); 


        /*** ZRX-A Flip ***/
        ilk = "ZRX-A";
        newFlip = FlipAbstract(MCD_FLIP_ZRX_A);
        oldFlip = FlipAbstract(MCD_FLIP_ZRX_A_OLD);

        newCat.file(ilk, "flip", address(newFlip));
        newCat.file(ilk, "chop", chop);
        newCat.file(ilk, "lump", lump);
        newCat.rely(address(newFlip));

        newFlip.rely(address(newCat));
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.cat() == address(newCat), "non-matching-cat");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");


        /*** KNC-A Flip ***/
        ilk = "KNC-A";
        newFlip = FlipAbstract(MCD_FLIP_KNC_A);
        oldFlip = FlipAbstract(MCD_FLIP_KNC_A_OLD);

        newCat.file(ilk, "flip", address(newFlip));
        newCat.file(ilk, "chop", chop);
        newCat.file(ilk, "lump", lump);
        newCat.rely(address(newFlip));

        newFlip.rely(address(newCat));
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.cat() == address(newCat), "non-matching-cat");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");


        /*** MANA-A Flip ***/
        ilk = "MANA-A";
        newFlip = FlipAbstract(MCD_FLIP_MANA_A);
        oldFlip = FlipAbstract(MCD_FLIP_MANA_A_OLD);

        newCat.file(ilk, "flip", address(newFlip));
        newCat.file(ilk, "chop", chop);
        newCat.file(ilk, "lump", lump);
        newCat.rely(address(newFlip));

        newFlip.rely(address(newCat));
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.cat() == address(newCat), "non-matching-cat");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");
    }
}

contract DssSpell {
    DSPauseAbstract public pause =
        DSPauseAbstract(0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    function description() public view returns (string memory) {
        return SpellAction(action).description();
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