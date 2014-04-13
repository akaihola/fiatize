['3LUSnUBVG3hKs8FYBmPFHvLCxBY8bgN9Lg',
 '32rUgPxDNvgTpLnJJcRoxJ2zzwbstEDPWZ',
 '3GP53yhnzPXPRSvoJtxxCaPo3o4dxg8nSB',
 '3J4veGPkNCaajm2DHHuAtPL15oUBGPRTr1'].forEach(function(address) {
    CoinWidgetCom.go({
    	wallet_address: address,
    	currency: 'bitcoin',
    	counter: 'amount',
    	lbl_button: 'Add to bounty',
    	lbl_count: 'donations',
    	lbl_amount: '฿',
    	lbl_address: 'Use address below to donate to the bounty.',
    	qrcode: true,
    	alignment: 'bl',
    	decimals: 8,
    	size: "small",
    	color: "light",
    	countdownFrom: "0",
    	element: "#coinwidget-bitcoin-" + address,
    	onShow: function(){},
    	onHide: function(){}
    });
});
