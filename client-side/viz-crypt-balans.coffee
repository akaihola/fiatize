$addressInfo = $ '#address-info'
$form = $ 'form'
$video = $ 'video'
$canvas = $ '#qr-canvas'

cryptocurrencies =
  BTC:
    regex: /^[13]/
    getBalance: (address) ->
      $.get("http://btc.blockr.io/api/v1/address/balance/#{address}").then (resp) ->
        resp.data.balance
  LTC:
    regex: /^[L]/
    getBalance: (address) ->
      $.get("http://ltc.blockr.io/api/v1/address/balance/#{address}").then (resp) ->
        resp.data.balance

getBalance = (address) ->
  for currencyCode, currency of cryptocurrencies
    if currency.regex.test(address)
      return currency.getBalance address

ecbTokensUri = 'http://www.ecb.europa.eu/euro'
eurCoinsUri = "#{ecbTokensUri}/coins/common/shared/img"
eurNotesUri = "#{ecbTokensUri}/banknotes/shared/img"
usdCoinsUri = 'http://upload.wikimedia.org/wikipedia/commons/thumb'
usdTokensUri = 'http://www.newmoney.gov/newmoney/images/general'

fiatCurrencies =
  EUR:
    getRate: ->
      $.getJSON('https://api.bitcoinaverage.com/ticker/global/EUR/').then (resp) -> resp.bid
    tokenImages:
      1: "#{eurCoinsUri}/common_1cent.gif"
      2: "#{eurCoinsUri}/common_2cent.gif"
      5: "#{eurCoinsUri}/common_5cent.gif"
      10: "#{eurCoinsUri}/newcommon_10cent.gif"
      20: "#{eurCoinsUri}/newcommon_20cent.gif"
      50: "#{eurCoinsUri}/newcommon_50cent.gif"
      100: "#{eurCoinsUri}/newcommon_1euro.gif"
      200: "#{eurCoinsUri}/newcommon_2euro.gif"
      500: "#{eurNotesUri}/5euro_front_europa.jpg"
      1000: "#{eurNotesUri}/new10eurofr.jpg"
      2000: "#{eurNotesUri}/20eurofr.jpg"
      5000: "#{eurNotesUri}/50eurofr.jpg"
      10000: "#{eurNotesUri}/100eurofr.jpg"
      20000: "#{eurNotesUri}/200eurofr.jpg"
      50000: "#{eurNotesUri}/500eurofr.jpg"
  USD:
    getRate: ->
      $.getJSON('https://api.bitcoinaverage.com/ticker/global/USD/').then (resp) -> resp.bid
    tokenImages:
      1: "#{usdCoinsUri}/2/2e/US_One_Cent_Obv.png/48px-US_One_Cent_Obv.png"
      5: "#{usdCoinsUri}/6/62/US_Nickel_2013_Obv.png/53px-US_Nickel_2013_Obv.png"
      10: "#{usdCoinsUri}/a/a0/2006_Quarter_Proof.png/60px-2006_Quarter_Proof.png"
      20: "#{usdCoinsUri}/a/a0/2006_Quarter_Proof.png/60px-2006_Quarter_Proof.png"
      50: "#{usdCoinsUri}/e/e5/US_50_Cent_Obv.png/77px-US_50_Cent_Obv.png"
      100: "#{usdCoinsUri}/e/e1/Sacagawea_Obverse.png/69px-Sacagawea_Obverse.png"
      500: "#{usdTokensUri}/5/5_front_small.jpg"
      1000: "#{usdTokensUri}/10/GlossyFront_sm.jpg"
      2000: "#{usdTokensUri}/nbFront_small.gif"
      5000: "#{usdTokensUri}/Series2004NoteFront_50small.jpg"
      10000: "#{usdTokensUri}/100/100_front_75_174.jpg"

reverse = (a, b) -> b - a

getChange = (target, currency) ->
  total = 0
  result = {}
  tokens = fiatCurrencies[currency].tokenImages
  for denomination in (+d for d of tokens).sort(reverse)
    while total + denomination <= target
      result[denomination] ?=
        count: 0
        src: tokens[denomination]
      result[denomination].count += 1
      total += denomination
  return result

getParameterByName = (name) ->
  name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
  regex = new RegExp "[\\?&]" + name + "=([^&#]*)"
  results = regex.exec location.search
  if results is null then "" else decodeURIComponent(results[1].replace(/\+/g, " "))

display = (address, balance, currency, rate) ->
  eurocents = Math.floor(rate * balance * 100)
  notesAndCoins = getChange eurocents, currency
  $('#mBTC').html(1000 * balance)
  $('#EUR').html(eurocents / 100)
  $('#currency').html(currency)
  denominations = (denomination for denomination of notesAndCoins)
  for denomination in denominations.sort(reverse)
    for counter in [1..notesAndCoins[denomination].count]
      $('<img/>', {'src': notesAndCoins[denomination].src}).appendTo($addressInfo)

showBalance = (address) ->
  $('#card').attr('src', "../cards/#{address}.png")
  $('#address').html(address)
  $addressInfo.show()
  currency = getParameterByName('currency') || 'EUR'
  $.when(
    getBalance(address)
    fiatCurrencies[currency].getRate()
  ).done (balance, rate) ->
    display address, balance, currency, rate

showForm = ->
  $form.show()
  $('#scan').on 'click', -> initWebcam()

@initWebcam = ->
  gCtx = $canvas[0].getContext('2d')
  gCtx.scale(-1, 1)
  qrcode.callback = (a) ->
    $('#id_address').val a.replace(/^bitcoin:/, '')
    $form.submit()

  captureToCanvas = (stream) ->
    gCtx.drawImage $video[0], -800, 0
    try
      qrcode.decode()
      stream.stop()
      $canvas.hide()
    catch e
      console.log e
      setTimeout captureToCanvas, 100, stream

  navigator.getMedia = (navigator.getUserMedia ||
                        navigator.webkitGetUserMedia ||
                        navigator.mozGetUserMedia ||
                        navigator.msGetUserMedia)

  navigator.getMedia(
    # constraints
    {video: true, audio: false},
    # successCallback
    (localMediaStream) ->
      console.log 'getMedia success'
      $video.attr 'src', window.URL.createObjectURL localMediaStream
      $canvas.show()
      $video[0].onloadedmetadata = (e) ->
         setTimeout captureToCanvas, 500, localMediaStream
    # errorCallback
    (err) -> console.log "The following error occured: " + err
  )

$(document).ready ->
  address = getParameterByName 'address'
  if address
    showBalance address
  else
    showForm()
