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
    const april30 = 1556611200;
    const july31 =  1564560000;


    describe('Vesting process for presale period', function () {
        beforeEach('redeploy', async function () {
            var releaseDate = latestTime() + duration.days(30);
            token = await Token.new(releaseDate, {from : owner});
            crowdsale = await Crowdsale.new(wallet, token.address, {from : owner});

            await token.setCrowdsaleAddress(crowdsale.address, {from : owner});
            await token.transfer(crowdsale.address, tokensToSell, {from : owner});
        });
        it('rejects claiming tokens from a conntributor of the presale before april30', async function () {
            const paymentAmount = web3.toWei('12', 'ether');

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 2);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });

            // check DSLA balance
            let balance = new BigNumber(12 * 312500 * 0.5).mul(1e18);
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            await crowdsale.closeCrowdsale({from : owner});
            await assertRevert(crowdsale.claimTokens({from : owner}));
        });
        it('accepts claiming tokens from a conntributor of the privatesale between april30 and july31', async function () {
            const paymentAmount = web3.toWei('12', 'ether');

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 2);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });

            // check DSLA balance
            let balance = new BigNumber(12 * 312500 * 0.5).mul(1e18);
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            await crowdsale.closeCrowdsale({from : owner});
            await increaseTimeTo(april30 + duration.minutes(5));
            await crowdsale.claimTokens({from : user1});

            assert.equal(await token.balanceOf(user1), new BigNumber(12 * 312500 * 0.75).mul(1e18).valueOf());
        });
        it('accepts claiming tokens from a conntributor of the privatesale after july31', async function () {
            const paymentAmount = web3.toWei('12', 'ether');

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 2);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });

            // check DSLA balance
            let balance = new BigNumber(12 * 312500 * 0.5).mul(1e18);
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            await crowdsale.closeCrowdsale({from : owner});
            await increaseTimeTo(july31 + duration.minutes(5));
            await crowdsale.claimTokens({from : user1});

            assert.equal(await token.balanceOf(user1), balance.valueOf() * 2);
        });
    });
});
