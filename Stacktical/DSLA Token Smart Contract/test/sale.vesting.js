import assertRevert from './helpers/assertRevert';
import latestTime from './helpers/latestTime';
import { increaseTimeTo, duration } from './helpers/increaseTime';

const Token = artifacts.require('./DSLA.sol');
const Crowdsale = artifacts.require('./DSLACrowdsale.sol');
const BigNumber = web3.BigNumber;

contract('Vesting', function ([owner, project, anotherAccount, user1, user2, wallet]) {
    let token;
    let crowdsale;
    const tokensToSell = new BigNumber('5e27');
    const may31 = 1559289600;


    describe('Vesting process for sale period', function () {
        beforeEach('redeploy', async function () {
            var releaseDate = latestTime() + duration.days(30);
            token = await Token.new(releaseDate, {from : owner});
            crowdsale = await Crowdsale.new(wallet, token.address, {from : owner});

            await token.setCrowdsaleAddress(crowdsale.address, {from : owner});
            await token.transfer(crowdsale.address, tokensToSell, {from : owner});
        });
        it('rejects claiming tokens from a conntributor of the presale before may31', async function () {
            const paymentAmount = web3.toWei('3', 'ether');

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 3);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });

            // check DSLA balance
            let balance = new BigNumber(3 * 250000 * 0.75).mul(1e18);
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            await crowdsale.closeCrowdsale({from : owner});
            await assertRevert(crowdsale.claimTokens({from : owner}));
        });
        it('accepts claiming tokens from a conntributor of the privatesale after may31', async function () {
            const paymentAmount = web3.toWei('3', 'ether');

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 3);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });

            // check DSLA balance
            let balance = new BigNumber(3 * 250000 * 0.75).mul(1e18);
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            await crowdsale.closeCrowdsale({from : owner});
            await increaseTimeTo(may31 + duration.minutes(5));
            await crowdsale.claimTokens({from : user1});

            assert.equal(await token.balanceOf(user1), new BigNumber(3 * 250000).mul(1e18).valueOf());
        });
    });
});
