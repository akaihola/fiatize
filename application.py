import os
from bottle import route, run, static_file, template
import requests
import sys


def get_best_coins(coins, target):
    costs = [0]
    coins_used = [None]
    for i in range(1, target + 1):
        best_cost = sys.maxsize
        best_coin = -1
        for coin in coins:
            if coin <= i:
                cost = 1 + costs[i - coin]
                if cost < best_cost:
                    best_cost = cost
                    best_coin = coin
        costs.append(best_cost)
        coins_used.append(best_coin)
    best_coins = []
    while target > 0:
        best_coins.append(coins_used[target])
        target -= coins_used[target]
    return reversed(best_coins)


DENOMINATIONS = [1, 2, 5, 10, 20, 50, 100, 200,
                 500, 1000, 2000, 5000, 10000, 20000, 50000]


@route('/static/<path:path>')
def callback(path):
    return static_file(path, os.path.join(os.path.dirname(__file__), 'static'))


@route('/<address>')
def index(address):
    balance_url = ('http://blockchain.info/q/addressbalance/{}?format=json'
                   .format(address))
    balance_response = requests.get(balance_url)
    balance_satoshis = int(balance_response.text)
    rate_url = 'https://api.bitcoinaverage.com/ticker/global/EUR/'
    rate_response = requests.get(rate_url)
    bid_rate = rate_response.json()['bid']
    eurocent_balance = int(bid_rate * balance_satoshis // 1000000)
    notes_and_coins = get_best_coins(DENOMINATIONS, eurocent_balance)
    return template('''<!doctype html>
        <html>
            <body>
                % for denomination in notes_and_coins:
                %     format = "gif" if denomination <= 200 else "jpg"
                      <img src="static/images/{{denomination}}.{{format}}">
                % end
            </body>
        </html>''', notes_and_coins=notes_and_coins)

run(host='localhost', port=8080)
