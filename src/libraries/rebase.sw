library rebase;

pub enum RebaseError {
    Overflow: (),
    DivisionByZero: (),
}

pub struct Rebase {
    elastic: u64, 
    base: u64,
}

impl Rebase {
    pub fn to_base(self, elastic: u64, round_up: bool) -> u64 {
        let mut base: u64 = 0;
        if self.elastic == 0 {
            base = elastic;
        } else {
            base = mul_div(elastic, self.base, self.elastic);
            if round_up && mul_div(base, self.elastic, self.base) < elastic {
                base += 1;
            }
        }

        base
    }

    pub fn to_elastic(self, base: u64, round_up: bool) -> u64 {
        let mut elastic: u64 = 0;
        if self.base == 0 {
            elastic = base;
        } else {
            elastic = mul_div(base, self.elastic, self.base);
            if round_up && mul_div(elastic, self.base, self.elastic) < base {
                elastic += 1;
            }
        }

        elastic
    }
}

impl Rebase {
    pub fn add(mut self, elastic: u64, round_up: bool) -> (Rebase, u64) {
        let base = self.to_base(elastic, round_up);
        let rebase = Rebase {
            elastic: self.elastic + elastic,
            base: self.base + base,
        };

        (rebase, base)
    }

    pub fn sub(mut self, base: u64, round_up: bool) -> (Rebase, u64) {
        let elastic = self.to_elastic(base, round_up);
        let rebase = Rebase {
            elastic: self.elastic - elastic,
            base: self.base - base,
        };

        (rebase, elastic)
    }

    pub fn add_full(self, elastic: u64, base: u64) -> Rebase {
        Rebase {
            elastic: self.elastic + elastic,
            base: self.base + base,
        }
    }

    pub fn sub_full(self, elastic: u64, base: u64) -> Rebase {
        Rebase {
            elastic: self.elastic - elastic,
            base: self.base - base,
        }
    }

    pub fn add_elastic(mut self, elastic: u64) -> u64 {
        self.elastic = self.elastic + elastic;
        self.elastic
    }

    pub fn sub_elastic(mut self, elastic: u64) -> u64 {
        self.elastic = self.elastic - elastic;
        self.elastic
    }
}

use std::u128::U128;

fn mul_div(a: u64, b: u64, c: u64) -> u64 {
    require(c != 0, RebaseError::DivisionByZero);
    let a = U128{upper: 0, lower: a};
    let b = U128{upper: 0, lower: b};
    let c = U128{upper: 0, lower: c};
    let result = (a * b) / c;
    require(result.upper == 0, RebaseError::Overflow);

    result.lower
} 

#[test]
fn test_first_to_share_correct() {
    let rebase = Rebase {
        elastic: 0,
        base: 0,
    };
    let result = rebase.to_base(100, false);
    assert(result == 100);
}

#[test]
fn test_first_to_elastic_correct() {
    let rebase = Rebase {
        elastic: 0,
        base: 0,
    };
    let result = rebase.to_elastic(100, false);
    assert(result == 100);
}

#[test]
fn test_calculates_to_share_correctly() {
    let rebase = Rebase {
        elastic: 1000,
        base: 500,
    };
    let result = rebase.to_base(100, false);
    assert(result == 50);

    let result = rebase.to_base(100, true);
    assert(result == 50);

    let result = rebase.to_base(1, false);
    assert(result == 0);

    let result = rebase.to_base(1, true);
    assert(result == 1);

    let result = rebase.to_base(0, false);
    assert(result == 0);

    let result = rebase.to_base(0, true);
    assert(result == 0); 
}

#[test]
fn calculates_to_elastic_properly() {
    let rebase = Rebase {
        elastic: 1000,
        base: 500,
    };
    let result = rebase.to_elastic(100, false);
    assert(result == 200);

    let result = rebase.to_elastic(100, true);
    assert(result == 200);

    let result = rebase.to_elastic(1, false);
    assert(result == 2);

    let result = rebase.to_elastic(1, true);
    assert(result == 2);

    let result = rebase.to_elastic(0, false);
    assert(result == 0);

    let result = rebase.to_elastic(0, true);
    assert(result == 0);
}

#[test]
fn test_adds_elastic_correctly() {
    let mut rebase = Rebase {
        elastic: 1000,
        base: 500,
    };
    let (result, base) = rebase.add(100, false);
    assert(result.elastic == 1100);
    assert(result.base == 550);
}

#[test]
fn removes_base_correctly() {
    let mut rebase = Rebase {
        elastic: 1100,
        base: 550,
    };
    let (result, elastic) = rebase.sub(50, false);
    assert(result.elastic == 1000);
    assert(result.base == 500);
}

#[test]
fn test_adds_both_correctly() {
    let rebase = Rebase {
        elastic: 1000,
        base: 500,
    };
    let result = rebase.add_full(189, 12);
    assert(result.elastic == 1189);
    assert(result.base == 512);
}

#[test]
fn calculates_to_share_correctly() {
    let rebase = Rebase {
        elastic: 1189,
        base: 512,
    };

    let result = rebase.to_base(100, false);
    assert(result == 43);

    let result = rebase.to_base(100, true);
    assert(result == 44);

    let result = rebase.to_base(1, false);
    assert(result == 0);

    let result = rebase.to_base(1, true);
    assert(result == 1);

    let result = rebase.to_base(0, false);
    assert(result == 0);

    let result = rebase.to_base(0, true);
    assert(result == 0);
}

#[test]
fn calculates_to_elastic_correctly() {
    let rebase = Rebase {
        elastic: 1189,
        base: 512,
    };

    let result = rebase.to_elastic(100, false);
    assert(result == 232);

    let result = rebase.to_elastic(100, true);
    assert(result == 233);

    let result = rebase.to_elastic(1, false);
    assert(result == 2);

    let result = rebase.to_elastic(1, true);
    assert(result == 3);

    let result = rebase.to_elastic(0, false);
    assert(result == 0);

    let result = rebase.to_elastic(0, true);
    assert(result == 0);
}

#[test]
fn remove_both_correctly() {
    let mut rebase = Rebase {
        elastic: 1189,
        base: 512,
    };
    let result = rebase.sub_full(1189, 512);
    assert(result.elastic == 0);
    assert(result.base == 0);
}

#[test]
fn removes_base_correctly_when_empty() {
    let mut rebase = Rebase {
        elastic: 0,
        base: 0,
    };
    let (result, elastic) = rebase.sub(0, false);
    assert(result.elastic == 0);
    assert(result.base == 0);
}

#[test]
fn test_adds_elastic_correctly_when_empty() {
    let mut rebase = Rebase {
        elastic: 0,
        base: 0,
    };
    let (result, base) = rebase.add(100, false);
    assert(result.elastic == 100);
    assert(result.base == 100);
}

#[test]
fn test_adds_just_elastic_correctly_when_empty() {
    let mut rebase = Rebase {
        elastic: 100,
        base: 100,
    };
    let result = rebase.add_elastic(50);
    assert(result == 150);
    assert(rebase.elastic == 150);
    assert(rebase.base == 100);
}

#[test]
fn remove_elastic_correctly_when_empty() {
    let mut rebase = Rebase {
        elastic: 150,
        base: 100,
    };
    let result = rebase.sub_elastic(40);
    assert(result == 110);
    assert(rebase.elastic == 110);
    assert(rebase.base == 100);
}