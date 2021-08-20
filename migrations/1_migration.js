const Contract = artifacts.require('imnotArtAllAccess')
const mockErc721 = artifacts.require('mockErc721')

module.exports = function (deployer, network, accounts) {
    deployer.deploy(Contract);

    if (network == 'development') {
        deployer.deploy(mockErc721);
    }
}