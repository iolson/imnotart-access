const { assert } = require('chai')
const truffleAssert = require('truffle-assertions')

const Contract = artifacts.require('./imnotArtAllAccess.sol')
const Mock721 = artifacts.require('./mockErc721.sol')

require('chai')
    .use(require('chai-as-promised'))
    .should()

contract('Contract', (accounts) => {
    const imnotArtAdminAddress = accounts[0];
    const invalidContractAddressMock = accounts[2];

    let contract;
    let mockErc721;

    before(async () => {
        contract = await Contract.deployed()
        mockErc721 = await Mock721.deployed()
    })

    describe('deployment', async () => {
        
        it('deploys successfully', async () => {
            const address = contract.address
            assert.notEqual(address, 0x0)
            assert.notEqual(address, '')
            assert.notEqual(address, null)
            assert.notEqual(address, undefined)
        })

        it('mint mock721 token', async () => {
            await truffleAssert.passes(
                mockErc721.mint()
            )
        })
    })

    describe('updates', async () => {

        it('can add a new valid contract address', async () => {
            await truffleAssert.passes(
                contract.addValidContractAddress(mockErc721.address)
            )
        })

        it('can add a new tokenId to valid contract address', async () => {
            await truffleAssert.passes(
                contract.addValidTokenId(mockErc721.address, 1)
            )
        })

        it('can NOT add a new tokenId to an invalid contract address', async () => {
            await truffleAssert.fails(
                contract.addValidTokenId(invalidContractAddressMock, 1),
                truffleAssert.ErrorType.REVERT,
                'Only valid contract addresses.'
            )
        })

        it('non-admin can NOT add a valid contract address', async () => {
            await truffleAssert.fails(
                contract.addValidContractAddress(invalidContractAddressMock, {from: accounts[9]}),
                truffleAssert.ErrorType.REVERT,
                'Only admins.'
            )
        })
    })

    describe('gets', async () => {

        it('can check if token id is valid for contract', async () => {
            const valid = await contract.isTokenIdValidForContract(mockErc721.address, 1)
            assert.equal(valid, true)
        })

        it('can get claim status of token id for valid contract address', async () => {
            const claimed = await contract.hasTokenByClaimed(mockErc721.address, 1)
            assert.equal(claimed, false)
        })
    })

    describe('mints', async () => {

        it('can NOT allow non-owners of token id to claim a all access token', async () => {
            await truffleAssert.fails(
                contract.mint(mockErc721.address, 1, {from: accounts[1]}),
                truffleAssert.ErrorType.REVERT,
                "You are not eligible to mint an ALL ACCESS token."
            )
        })

        it('can create a all access token for a valid contract and token id', async () => {
            await truffleAssert.passes(
                contract.mint(mockErc721.address, 1)
            )

            const claimed = await contract.hasTokenByClaimed(mockErc721.address, 1)
            assert.equal(claimed, true)
        })

        it('can NOT create a all access token for a token id that has already been claimed', async () => {
            await truffleAssert.fails(
                contract.mint(mockErc721.address, 1),
                truffleAssert.ErrorType.REVERT,
                "ALL ACCESS token has already been minted."
            )
        })
    })
})