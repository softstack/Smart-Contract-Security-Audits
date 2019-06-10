const DSLA = artifacts.require('./DSLA.sol');
const DSLACrowdsale = artifacts.require('./DSLACrowdsale.sol');

module.exports =  function(deployer, network) {
    // Dec 31th 2018 8AM GMT
    const releaseDate = 1546243200;
    let wallet = "0xaf13f12ebe00cd02f486e000927408148e768802";
    let dsla;
    let crowdsale;

    return deployer.deploy(DSLA, releaseDate).then(function(instance){
        dsla = instance;
        return deployer.deploy(DSLACrowdsale, wallet, dsla.address).then(function(instance){
            crowdsale = instance;
            return dsla.setCrowdsaleAddress(crowdsale.address).then(async function(){
                const adr = await dsla.crowdsaleAddress.call();
                console.log("Crowdsale address set to " + adr);
            });
        });
    });
}
