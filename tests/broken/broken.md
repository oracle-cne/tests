# Why is the test broken?  Why is it okay that it is?

console.bats is broken because `ocne cluster console -- <cmd>` hangs
indefinitely and only responds to SIGKILL.  This behavior is only
reproducible within this test suite.
