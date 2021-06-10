import { BigNumber as BN, BigNumberish } from 'ethers';
import { assert, expect } from 'chai';
const PRECISION = BN.from(2).pow(40);

/**
 * convert an amount to Wei
 * @param inp if inp is number => inp is the number of decimal digits
 *            if inp is Token => the number of decimal digits will be extracted from Token
 */
export function amountToWei(amount: BN, decimal: number) {
  return BN.from(10).pow(decimal).mul(amount);
}

export function toFixedPoint(val: string | number): BN {
  if (typeof val === 'number') {
    return BN.from(val).mul(PRECISION);
  }
  var pos: number = val.indexOf('.');
  if (pos == -1) {
    return BN.from(val).mul(PRECISION);
  }
  var lenFrac = val.length - pos - 1;
  val = val.replace('.', '');
  return BN.from(val).mul(PRECISION).div(BN.from(10).pow(lenFrac));
}

export function randomBN(range?: number | BN): BN {
  let lim = 10 ** 15;
  return BN.from(Math.floor(Math.random() * lim))
    .mul(BN.from(range))
    .div(lim);
}

export function randomNumber(range?: number): number {
  return randomBN(range).toNumber();
}

export function approxBigNumber(
  _actual: BigNumberish,
  _expected: BigNumberish,
  _delta: BigNumberish,
  log: boolean = true
) {
  let actual: BN = BN.from(_actual);
  let expected: BN = BN.from(_expected);
  let delta: BN = BN.from(_delta);

  var diff = expected.sub(actual);
  if (diff.lt(0)) {
    diff = diff.mul(-1);
  }
  if (diff.lte(delta) == false) {
    expect(
      diff.lte(delta),
      `expecting: ${expected.toString()}, received: ${actual.toString()}, diff: ${diff.toString()}, allowedDelta: ${delta.toString()}`
    ).to.be.true;
  } else {
    if (log) {
      console.log(
        `expecting: ${expected.toString()}, received: ${actual.toString()}, diff: ${diff.toString()}, allowedDelta: ${delta.toString()}`
      );
    }
  }
}
