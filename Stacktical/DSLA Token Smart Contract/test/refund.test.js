import assertRevert from './helpers/assertRevert';
import latestTime from './helpers/latestTime';
import { increaseTimeTo, duration } from './helpers/increaseTime';

const Token = artifacts.require('./DSLA.sol');
const Crowdsale = artifacts.require('./DSLACrowdsale.sol');
const BigNumber = web3.BigNumber;

contract('Refund', function ([owner, project, anotherAccount, user1, user2, wallet]) {
    let token;
    let crowdsale;
    const releaseDate = 1546243200;
    const tokensToSell = new BigNumber('5e27');
    const rate = 250000;
    const individualFloor = web3.toWei('3', 'ether');
    const individualCap = web3.toWei('30', 'ether');
    const softCap = web3.toWei('7200', 'ether');
    const hardCap = web3.toWei('17200', 'ether');

    beforeEach('redeploy', async function () {
        token = await Token.new(releaseDate, {from : owner});
        crowdsale = await Crowdsale.new(wallet, token.address, {from : owner});

        await token.setCrowdsaleAddress(crowdsale.address, {from : owner});
        await token.transfer(crowdsale.address, tokensToSell, {from : owner});
    });

    describe('Check if the crowdsale address is set', function () {
        it('return the same address', async function () {
            assert.equal(await token.crowdsaleAddress.call(), crowdsale.address);
        });
    });

    describe('Refund period', function () {
        it('rejects refunding a conntributor of the privatesale period', async function () {
            const paymentAmount = web3.toWei('3', 'ether');

            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 1);

            await crowdsale.addPrivateSaleContributors(user1 ,paymentAmount, {from : owner});

            await crowdsale.closeCrowdsale({from : owner});

            // claim a refund
            await assertRevert(crowdsale.claimRefund({from : user1}));
        });
        it('rejects refunding a conntributor of the privatesale period', async function () {
            const paymentAmount = web3.toWei('3', 'ether');

            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 1);

            await crowdsale.addOtherCurrencyContributors(user1 ,paymentAmount, 1, {from : owner});

            await crowdsale.closeCrowdsale({from : owner});

            await crowdsale.finalizeCrowdsale({from : owner});

            // claim a refund
            await assertRevert(crowdsale.claimRefund({from : user1}));
        });
        it('accepts refunding a contributor of the presale period', async function () {
            const paymentAmount = web3.toWei('12', 'ether');

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});

            assert.equal(await crowdsale.currentIcoRound.call(), 2);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });
            var balance = await web3.eth.getBalance(user1);

            // check raised funds value
            assert.equal(await crowdsale.raisedFunds.call().valueOf(), paymentAmount.valueOf());

            await crowdsale.closeCrowdsale({from : owner});

            await crowdsale.finalizeCrowdsale({from : owner});

            // claim a refund
            await crowdsale.claimRefund({from : user1, gasPrice : 0});

            var actualBalance = balance.add(paymentAmount);
            assert.equal(await web3.eth.getBalance(user1), actualBalance.valueOf());

            // check raised funds value
            assert.equal(await crowdsale.raisedFunds.call().valueOf(), 0);
        });
        it('accepts refunding a contributor of the sale period', async function () {
            const paymentAmount = web3.toWei('3', 'ether');

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});

            assert.equal(await crowdsale.currentIcoRound.call(), 3);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });
            var balance = await web3.eth.getBalance(user1);

            // check raised funds value
            assert.equal(await crowdsale.raisedFunds.call().valueOf(), paymentAmount.valueOf());

            await crowdsale.closeCrowdsale({from : owner});
            await crowdsale.finalizeCrowdsale({from : owner});

            // claim a refund
            await crowdsale.claimRefund({from : user1, gasPrice : 0});

            var actualBalance = balance.add(paymentAmount);
            assert.equal(await web3.eth.getBalance(user1), actualBalance.valueOf());

            // check raised funds value
            assert.equal(await crowdsale.raisedFunds.call().valueOf(), 0);
        });
        it('rejects refunding a conntributor after the refund deadline', async function () {
            const paymentAmount = web3.toWei('3', 'ether');

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 2);

            await crowdsale.addOtherCurrencyContributors(user1 ,paymentAmount, 1, {from : owner});

            await crowdsale.closeCrowdsale({from : owner});

            await crowdsale.finalizeCrowdsale({from : owner});

            // increase time to after refund period
            await increaseTimeTo(latestTime() + duration.weeks(4));

            // claim a refund
            await assertRevert(crowdsale.claimRefund({from : user1}));
        });
        it('accepts closing refund period', async function () {
            const paymentAmount = web3.toWei('12', 'ether');
            let actualBalance = await web3.eth.getBalance(wallet);

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 2);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });

            await crowdsale.closeCrowdsale({from : owner});
            await crowdsale.finalizeCrowdsale({from : owner});

            // increase time to after refund period
            await increaseTimeTo(latestTime() + duration.weeks(5));

            // close refund period
            await crowdsale.closeRefunding({from : user1});

            // check wallet withdrawable funds
            let newBalance = actualBalance.add(paymentAmount);
            assert.equal(await web3.eth.getBalance(wallet).valueOf(), newBalance.valueOf());

            // check raised funds value
            assert.equal(await crowdsale.raisedFunds.call().valueOf(), paymentAmount.valueOf());
        });
    });
});
