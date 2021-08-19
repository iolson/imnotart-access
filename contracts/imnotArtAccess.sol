// SPDX-License-Identifier: MIT

/*
<Insert ASCII Art Here>

imnotArt Access
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/BaseERC721Interface.sol";
import "./rarible/library/LibPart.sol";
import "./rarible/library/LibRoyaltiesV2.sol";
import "./rarible/RoyaltiesV2.sol";

contract imnotArtAccess is Ownable, ERC721Enumerable, RoyaltiesV2 {
    using SafeMath for uint256;

    // ---
    // Constants
    // ---
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
    uint16 constant public imnotArtSecondarySaleBps = 500; // 5% of Secondary Sale

    // ---
    // Properties
    // ---
    uint256 public nextTokenId = 1;
    address public imnotArtPayoutAddress;
    string private contractUri;

    // ---
    // Events
    // ---
    event PermanentURI(string _value, uint256 indexed _id); // OpenSea Freezing Metadata
    event Debug(
        string message,
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed claimedAddress
    );

    // ---
    // Security
    // ---
    mapping(address => bool) private _isAdmin;

    modifier onlyAdmin() {
        require(_isAdmin[msg.sender], "Only admins.");
        _;
    }

    modifier onlyValidContractAddress(address contractAddress) {
        require(validContractAddresses[contractAddress], "Only valid contract addresses.");
        _;
    }

    modifier onlyValidTokenId(uint256 tokenId) {
        require(_exists(tokenId), "Token ID does not exist.");
        _;
    }

    // ---
    // Mappings
    // ---
    mapping(address => bool) private validContractAddresses;
    mapping(address => mapping(uint256 => bool)) private validTokenIdsByContract;
    mapping(address => mapping(uint256 => address)) private contractToTokenToClaimedAddress;

    // ---
    // Constructor
    // ---
    constructor() ERC721("imnotArt Access", "") {
        _isAdmin[msg.sender] = true;

        // imnotArt Mainnet Gnosis Safe
        // _isAdmin[address(0x12b66baFc99D351f7e24874B3e52B1889641D3f3)] = true;
        // imnotArtPayoutAddress = address(0x12b66baFc99D351f7e24874B3e52B1889641D3f3);
        // contractUri = "";
    }

    // ---
    // Supported Interfaces
    // ---
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165
        || interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES
        || interfaceId == _INTERFACE_ID_ERC721
        || interfaceId == _INTERFACE_ID_ERC721_METADATA
        || interfaceId == _INTERFACE_ID_ERC721_ENUMERABLE
        || interfaceId == _INTERFACE_ID_EIP2981
        || super.supportsInterface(interfaceId);
    }

    // ---
    // Minting
    // ---
    function mint(address contractAddress, uint256 tokenId) public onlyValidContractAddress(contractAddress) returns (uint256 accessPassId) {
        require(contractToTokenToClaimedAddress[contractAddress][tokenId] == address(0), "Token ID claims are unique.");

        BaseERC721Interface erc721Contract = BaseERC721Interface(contractAddress);
        require(erc721Contract.ownerOf(tokenId) == msg.sender, "Only owners of the valid tokens can claim a vip pass.");
        
        accessPassId = nextTokenId;
        nextTokenId = nextTokenId.add(1);

        contractToTokenToClaimedAddress[contractAddress][tokenId] = msg.sender;
    }

    // ---
    // Contract Gets
    // ---
    function isTokenIdValidForContract(address contractAddress, uint256 tokenId) public view onlyValidContractAddress(contractAddress) returns (bool) {
        return validTokenIdsByContract[contractAddress][tokenId];
    }

    function hasTokenByClaimed(address contractAddress, uint256 tokenId) public view onlyValidContractAddress(contractAddress) returns (bool) {
        return (contractToTokenToClaimedAddress[contractAddress][tokenId] != address(0x0));
    }

    // ---
    // Contract Updates
    // ---
    function addValidContractAddress(address validContractAddress) public onlyAdmin {
        validContractAddresses[validContractAddress] = true;
    }

    function addValidTokenId(address contractAddress, uint256 tokenId) public onlyAdmin onlyValidContractAddress(contractAddress) {
        bool tokenIdAlreadyAdded = validTokenIdsByContract[contractAddress][tokenId];
        if (!tokenIdAlreadyAdded) {
            validTokenIdsByContract[contractAddress][tokenId] = true;
        }
    }

    function updateContractUri(string memory newContractUri) public onlyAdmin {
        contractUri = newContractUri;
    }

    // ---
    // Secondary Marketplace Functions
    // ---

    /* OpenSea */
    function contractURI() public view virtual returns (string memory) {
        return contractUri;
    }

    /* Rarible Royalties V2 */
    function getRaribleV2Royalties(uint256 tokenId) external view override onlyValidTokenId(tokenId) returns (LibPart.Part[] memory) {
        LibPart.Part[] memory royalties = new LibPart.Part[](1);

        royalties[1] = LibPart.Part({
            account: payable(imnotArtPayoutAddress),
            value: uint96(imnotArtSecondarySaleBps)
        });

        return royalties;
    }

    /* EIP-2981 - https://eips.ethereum.org/EIPS/eip-2981 */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view onlyValidTokenId(tokenId) returns (address receiver, uint256 amount) {
        uint256 royaltyAmount = SafeMath.div(SafeMath.mul(salePrice, imnotArtSecondarySaleBps), 10000);
        return (imnotArtPayoutAddress, royaltyAmount);
    }
}