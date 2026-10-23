// Optional integration-test driver. The application itself does not depend on Playwright.
let driver;
try { driver=require(process.env.EC_PLAYWRIGHT_MODULE||'playwright'); }
catch { throw new Error('Integration tests require an installed Playwright module. Set EC_PLAYWRIGHT_MODULE to its module path. No automatic install or TLS bypass is performed.'); }
module.exports=driver;
