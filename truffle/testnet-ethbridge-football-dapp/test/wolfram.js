var WolframAlpha = artifacts.require("./WolframAlpha.sol");

contract('WolframAlpha', function(accounts) {
    //this.timeout(20000);
    var wolfram;
    var result;
    it("should call oraclize, wait with set timeout, and assert that 4 = 4", function(done){
       // setTimeout(()=>{}, 5000);
      // setTimeout(done, 20000);
        WolframAlpha.deployed().then(function(instance){
            wolfram = instance;
            return;
        }).then(function(){
            return new Promise(resolve => setTimeout(resolve, 20000));
        }).then(function(){
            return wolfram.getOraclizeAnswerJS.call();
        }).then(function(value){
            result = value;
            assert.equal(result, "4", "4 shall equal 4");
            done();
        });
    });

    it("should just assert that 4 = 4 to test it is working", function(){
        //setTimeout(()=>{}, 15000);
        return WolframAlpha.deployed().then(function(instance){
            return instance.getAnswer.call();
        }).then(function(theAnswer){
            assert.equal(theAnswer, 4, "two plus two hopefully equals 4");
        });
    });

})