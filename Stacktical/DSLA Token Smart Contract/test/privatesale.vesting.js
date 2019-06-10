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
    const march31 = 1554019200;
    const june30 =  1561881600;
    const sept30 =  1569830400;


    describe('Vesting process for private sale period', function () {
        beforeEach('redeploy', async function () {
            var releaseDate = latestTime() + duration.days(30);
            token = await Token.new(releaseDate, {from : owner});
            crowdsale = await Crowdsale.new(wallet, token.address, {from : owner});

            await token.setCrowdsaleAddress(crowdsale.address, {from : owner});
            await token.transfer(crowdsale.address, tokensToSell, {from : owner});
        });
        it('rejects claiming tokens from a conntributor of the privatesale before march31', async function () {
            const paymentAmount = web3.toWei('3', 'ether');

            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 1);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });

            // check DSLA balance
            let balance = new BigNumber(3 * 416700 * 0.25).mul(1e18);
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            await crowdsale.closeCrowdsale({from : owner});
            await assertRevert(crowdsale.claimTokens({from : owner}));
        });
        it('accepts claiming tokens from a conntributor of the privatesale between march31 and june30', async function () {
            const paymentAmount = web3.toWei('4', 'ether');

            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 1);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });

            // check DSLA balance
            let balance = new BigNumber(4 * 416700 * 0.25).mul(1e18);
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            await crowdsale.closeCrowdsale({from : owner});
            await increaseTimeTo(march31 + duration.minutes(5));
            await crowdsale.claimTokens({from : user1});

            assert.equal(await token.balanceOf(user1), balance.valueOf() * 2);
        });
        it('accepts claiming tokens from a conntributor of the privatesale between june30 and sept30', async function () {
            const paymentAmount = web3.toWei('3', 'ether');

            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 1);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });

            // check DSLA balance
            let balance = paymentAmount * 416700 * 0.25;
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            await crowdsale.closeCrowdsale({from : owner});

            await increaseTimeTo(june30 + duration.minutes(5));
            await crowdsale.claimTokens({from : user1});

            assert.equal(await token.balanceOf(user1), balance.valueOf() * 3);
        });
        it('accepts claiming tokens from a conntributor of the privatesale after sept30', async function () {
            const paymentAmount = web3.toWei('3', 'ether');

            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 1);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });

            // check DSLA balance
            let balance = new BigNumber(3 * 416700 * 0.25).mul(1e18);
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            await crowdsale.closeCrowdsale({from : owner});
            await increaseTimeTo(sept30 + duration.minutes(5));
            await crowdsale.claimTokens({from : user1});

            assert.equal(await token.balanceOf(user1), balance.valueOf() * 4);
        });
    });
});
