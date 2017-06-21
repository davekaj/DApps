## MetaPay Checkout

This is just a little demo of how to use metamask in a checkout.

This is a react component that checks for web3 in the browser and renders a regular
checkout if web3 hasn't been injected (i.e. if the user isn't using metamask).
If the user *is* using metamask, a different checkout is rendered.

When the user clicks the payment button, a metamask window is triggered asking
the user to pay. You probably don't want to hit accept :P

### Installation

Just run an `npm install` in this directory as well as the `metamask-payment` directory.
Make sure you have webpack installed globally and run `npm run wds` from this directory.
