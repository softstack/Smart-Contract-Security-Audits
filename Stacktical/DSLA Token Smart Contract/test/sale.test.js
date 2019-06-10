import assertRevert from './helpers/assertRevert';
import latestTime from './helpers/latestTime';
import { increaseTimeTo, duration } from './helpers/increaseTime';

const Token = artifacts.require('./DSLA.sol');
const Crowdsale = artifacts.require('./DSLACrowdsale.sol');
const BigNumber = web3.BigNumber;

contract('ROUND 3', function ([owner, project, anotherAccount, user1, user2, wallet]) {
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

    describe('Sale period', function () {
        it('rejects a contribution made when sale not yet starting', async function () {
            const paymentAmount = web3.toWei('3', 'ether');
            await assertRevert(crowdsale.sendTransaction( { from: user1 , value: paymentAmount }));
        });
        it('rejects adding a contributor when sale not yet starting', async function () {
            const paymentAmount = web3.toWei('3', 'ether');
            await assertRevert(crowdsale.addPrivateSaleContributors(user1, paymentAmount, { from : owner }));
        });
        it('rejects adding a contribution from other currencies when sale not yet starting', async function () {
            const paymentAmount = web3.toWei('3', 'ether');
            await assertRevert(crowdsale.addOtherCurrencyContributors(user1, paymentAmount, 3, { from : owner }));
        });
        it('rejects a contribution made from a non whitlisted account when sale is started', async function () {
            const paymentAmount = web3.toWei('3', 'ether');
            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});

            assert.equal(await crowdsale.currentIcoRound.call(), 3);

            await assertRevert(crowdsale.sendTransaction( { from: user1 , value: paymentAmount }));
        });
        it('rejects a contribution made from a whitlisted account less than the individual floor == 3 ether', async function () {
            const paymentAmount = web3.toWei('2', 'ether');

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 3);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await assertRevert(crowdsale.sendTransaction( { from: user1 , value: paymentAmount }));
        });
        it('rejects a contribution made from a whitlisted account more than the individual cap == 30 ether', async function () {
            const paymentAmount = web3.toWei('31', 'ether');

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 3);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await assertRevert(crowdsale.sendTransaction( { from: user1 , value: paymentAmount }));
        });
        it('rejects a second contribution from a whitlisted account when sale is started', async function () {
            const paymentAmount = web3.toWei('3', 'ether');

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 3);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });
            await assertRevert(crowdsale.sendTransaction({ from: user1 , value: paymentAmount }));
        });
        it('accepts a contribution made from a whitlisted account when sale is started', async function () {
            const paymentAmount = web3.toWei('3', 'ether');
            let actualBalance = await web3.eth.getBalance(wallet);

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 3);

            await crowdsale.addToWhitelist(user1, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);

            await crowdsale.sendTransaction({ from: user1 , value: paymentAmount });

            // check DSLA balance
            let balance = new BigNumber(3 * rate * 0.75).mul(1e18);
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            // check distributed tokens value
            assert.equal(await crowdsale.distributedTokens.call().valueOf(), balance.valueOf());

            // check vested tokens value
            let vestedTokens = new BigNumber(3 * rate * 0.25).mul(1e18);
            assert.equal(await crowdsale.vestedTokens.call().valueOf(), vestedTokens.valueOf());
            // check raised funds value
            assert.equal(await crowdsale.raisedFunds.call().valueOf(), paymentAmount.valueOf());
        });
        it('accepts adding a contributor when sale is started', async function () {
            const paymentAmount = web3.toWei('3', 'ether');
            let rate_privatesale = 416700;
            let actualBalance = await web3.eth.getBalance(wallet);

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 2);

            await crowdsale.addPrivateSaleContributors(user1 , paymentAmount, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);
            // check DSLA balance
            let balance = paymentAmount * rate_privatesale * 0.25;
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            // check distributed tokens value
            assert.equal(await crowdsale.distributedTokens.call().valueOf(), balance.valueOf());

            // check vested tokens value
            let vestedTokens = new BigNumber(3 * rate_privatesale * 0.75).mul(1e18);
            assert.equal(await crowdsale.vestedTokens.call().valueOf(), vestedTokens.valueOf());
            // check raised funds value
            assert.equal(await crowdsale.raisedFunds.call().valueOf(), paymentAmount.valueOf());
        });
        it('accepts adding a contributor from other currencies when sale is started', async function () {
            const paymentAmount = web3.toWei('3', 'ether');
            let round = 3;
            let actualBalance = await web3.eth.getBalance(wallet);

            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            await crowdsale.goToNextRound({from : owner});
            assert.equal(await crowdsale.currentIcoRound.call(), 3);

            await crowdsale.addOtherCurrencyContributors(user1 , paymentAmount, round, {from : owner});
            assert.equal(await crowdsale.whitelist(user1), true);
            // check DSLA balance
            let balance = new BigNumber(3 * rate * 0.75).mul(1e18);
            assert.equal(await token.balanceOf(user1), balance.valueOf());

            // check distributed tokens value
            assert.equal(await crowdsale.distributedTokens.call().valueOf(), balance.valueOf());

            // check vested tokens value
            let vestedTokens = new BigNumber(3 * rate * 0.25).mul(1e18);
            assert.equal(await crowdsale.vestedTokens.call().valueOf(), vestedTokens.valueOf());
            // check raised funds value
            assert.equal(await crowdsale.raisedFunds.call().valueOf(), paymentAmount.valueOf());
            // check raised funds from other currencies
            assert.equal(await crowdsale.weiRaisedFromOtherCurrencies.call().valueOf(), paymentAmount.valueOf());
        });
    });
});
