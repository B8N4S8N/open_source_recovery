// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LicenseVerification is ERC721, ERC721URIStorage, ERC721Burnable, AccessControl, EIP712, ERC721Votes {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    struct LicenseInfo {
        string holderName;
        string licenseType;
        string stateIssued;
        uint256 mintingDate;
        uint256 expirationDate;
    }

    mapping (uint256 => LicenseInfo) private _licenseInfo;

    constructor()
        ERC721("License Verification", "LVC")
        EIP712("License Verification", "1")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

function safeMint(string memory uri, string memory holderName, string memory licenseType, string memory stateIssued) public onlyRole(MINTER_ROLE) {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, uri);

    uint256 mintingDate = block.timestamp;
    uint256 expirationDate = mintingDate + 365 days;
    _licenseInfo[tokenId] = LicenseInfo({
        holderName: holderName,
        licenseType: licenseType,
        stateIssued: stateIssued,
        mintingDate: mintingDate,
        expirationDate: expirationDate
    });
}


    function getLicenseInfo(uint256 tokenId) public view returns (string memory, string memory, string memory, uint256, uint256) {
        LicenseInfo memory licenseInfo = _licenseInfo[tokenId];
        return (licenseInfo.holderName, licenseInfo.licenseType, licenseInfo.stateIssued, licenseInfo.mintingDate, licenseInfo.expirationDate);
    }

    function isExpired(uint256 tokenId) public view returns (bool) {
        LicenseInfo memory licenseInfo = _licenseInfo[tokenId];
        return block.timestamp >= licenseInfo.expirationDate;
    }

    function burnExpiredToken(uint256 tokenId) public {
        require(isExpired(tokenId), "LicenseVerification: Token is not expired yet");
        _burn(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Votes)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        delete _licenseInfo[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
