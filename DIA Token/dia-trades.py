#!/usr/bin/env python3

from decimal import *
import subprocess

# Bonding curve parameters
curve_a = Decimal(3.48)
curve_b = Decimal(10400000)
curve_c = Decimal(3.17639e12)

max_brackets = 20

# Parameters for calling the liquidity provider
DIA_TOKEN_ID = "21"
QUOTE_TOKEN_ID = "1"
MASTER_SAFE = "0x55AAfc3C4a7c87601bE10B713073EeF8e4F04753"
NETWORK_NAME = "rinkeby"
INFURA_KEY = ""
GAS_PRICE_GWEI = "1"
PK = ""

# Get the bonding curve value for a specified value x
def getCurvePrice(x):
    fraction = (x - curve_b)/((curve_c + (x - curve_b) * (x - curve_b)).sqrt())
    return curve_a * (fraction + Decimal(1))

# Class for handling the individual segments
class Segment:
    lower_price = Decimal(0)
    upper_price = Decimal(0)
    num_brackets = 0

    def __init__(self, lower_bound, upper_bound):
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound

    # Return the price gap in the segment
    def getDelta(self):
        return self.upper_price / self.lower_price

    # Get the number of brackets so that brackets are equally sized over all segments.
    # Steepest gradient with 15 brackets is 3.96
    def determineBracketNum(self):
        growth_factor = self.getDelta()
        bracket_factor = growth_factor / Decimal(3.96)
        self.num_brackets = int(Decimal(max_brackets) * bracket_factor)

    # Call the CMM script to deploy brackets
    def start_liquidity_provision(self):
        result = subprocess.run([
            "npx", "truffle", "exec", "scripts/complete_liquidity_provision.js",
            "--baseTokenId", DIA_TOKEN_ID,
            "--quoteTokenId", QUOTE_TOKEN_ID,
            "--lowestLimit", str(round(self.lower_price, 18)),
            "--highestLimit", str(round(self.upper_price, 18)),
            "--currentPrice", "0",
            "--masterSafe", MASTER_SAFE,
            "--depositBaseToken", str(round(self.upper_bound - self.lower_bound, 18)),
            "--depositQuoteToken", "0",
            "--numBrackets", str(self.num_brackets),
            "--network", NETWORK_NAME
            ],
            env={
                "INFURA_KEY": INFURA_KEY,
                "PK": PK,
                "GAS_PRICE_GWEI": GAS_PRICE_GWEI
                }
            )
        return result.stdout

def main():
    # Set precision for fix comma arithmetic in the Decimal library
    getcontext().prec = 36
    # Amount of sell tokens
    num_tokens = Decimal(30e6)
    # Number of segments along the bonding curve (each segment is split up into brackets)
    num_segments = Decimal(15)
    inum_segments = 15
    # Determine interval size on bonding curve x axis
    interval_size = num_tokens / num_segments
    segments = []


    # determine segment boundaries
    for i in range(inum_segments):
        lower_bound = interval_size * Decimal(i)
        upper_bound = (interval_size * (Decimal(i) + Decimal(1))) - Decimal(1e-18)
        segment = Segment(lower_bound, upper_bound)
        segments.append(segment)

    # Determine sell price ranges for each segment and execute deployment
    for s in segments:
        s.lower_price = getCurvePrice(s.lower_bound)
        s.upper_price = getCurvePrice(s.upper_bound)
        s.determineBracketNum()
        print(s.start_liquidity_provision())

if __name__ == "__main__":
    main()
